import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/widgets/calm_media_image.dart';
import '../data/giphy_remote_settings.dart';
import '../data/giphy_sdk_picker.dart';
import '../data/giphy_search.dart';
import '../data/giphy_surface.dart';
import '../domain/calm_meme.dart';

/// GIF search at the Remote Config rating ceiling.
///
/// Android and iOS open the official Giphy SDK, which carries Giphy's own
/// marks. The PWA searches the Giphy API, shows still previews, and keeps a
/// visible "Powered by GIPHY" line on this surface.
class GiphySearchPanel extends ConsumerStatefulWidget {
  const GiphySearchPanel({super.key, required this.onSelected});

  final ValueChanged<CalmMeme> onSelected;

  @override
  ConsumerState<GiphySearchPanel> createState() => _GiphySearchPanelState();
}

class _GiphySearchPanelState extends ConsumerState<GiphySearchPanel> {
  final TextEditingController _queryController = TextEditingController();

  var _loading = false;
  String? _error;
  List<GiphyGif> _results = const [];
  var _showingTrending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(giphySurfaceProvider) == GiphySurface.webApi) {
        _search('');
      }
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final client = ref.read(giphySearchProvider);
    if (!client.isConfigured) {
      setState(() {
        _loading = false;
        _error = null;
        _results = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _showingTrending = query.trim().isEmpty;
    });

    try {
      final results = await client.search(query);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = results;
      });
    } on GiphySearchException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(giphySearchProvider);
    final surface = ref.watch(giphySurfaceProvider);
    final configured = search.isConfigured;
    final ratingLabel = giphyRatingLabel(search.contentRating);
    if (!configured) {
      return const Text(
        key: Key('giphy_unconfigured'),
        'GIF search is not turned on for this build. Paste a link under More.',
        style: TextStyle(fontSize: 12, height: 1.35),
      );
    }

    if (surface == GiphySurface.nativeSdk) {
      return _buildNativeSdk(ratingLabel);
    }

    return _buildWebApi(ratingLabel);
  }

  Widget _buildWebApi(String ratingLabel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchRow = Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('giphy_search_input'),
                controller: _queryController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'quiet, bread, chapel',
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(borderRadius: .circular(10)),
                ),
                onSubmitted: _search,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              key: const Key('giphy_search_button'),
              onPressed: _loading ? null : () => _search(_queryController.text),
              child: const Text('Search', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
        const attribution = Text(
          key: Key('giphy_attribution'),
          'Powered by GIPHY',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        );
        final results = _buildResults(ratingLabel);

        // A short viewport (keyboard open) cannot pin a footer under an
        // Expanded grid. Keep the attribution with the search field so it
        // stays on screen, and let the grid fill whatever height remains.
        if (!constraints.maxHeight.isFinite || constraints.maxHeight < 150) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                searchRow,
                const SizedBox(height: 6),
                attribution,
                const SizedBox(height: 8),
                SizedBox(height: 160, child: results),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: .start,
          children: [
            searchRow,
            const SizedBox(height: 8),
            Expanded(child: results),
            const SizedBox(height: 6),
            attribution,
          ],
        );
      },
    );
  }

  Widget _buildNativeSdk(String ratingLabel) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('giphy_open_sdk_button'),
            onPressed: () {
              final settings = ref.read(giphyRemoteSettingsProvider);
              ref.read(giphySdkLauncherProvider)(
                apiKey: settings.apiKey,
                rating: settings.rating,
                onSelected: widget.onSelected,
              );
            },
            icon: const Icon(Icons.gif_box_outlined, size: 18),
            label: Text('Open Giphy ($ratingLabel)'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'GIFs, stickers, emoji, and clips. The feed attaches a silent GIF.',
          style: TextStyle(
            fontSize: 11,
            height: 1.35,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(String ratingLabel) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          key: Key('giphy_search_loading'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Text(
        _error!,
        key: const Key('giphy_search_error'),
        style: const TextStyle(fontSize: 12),
      );
    }

    if (_results.isEmpty) {
      return Text(
        _showingTrending
            ? 'No quiet GIF suggestions right now.'
            : 'No $ratingLabel GIFs for that search. Try a quieter word.',
        key: const Key('giphy_empty_results'),
        style: const TextStyle(fontSize: 12),
      );
    }

    return GridView.builder(
      key: const Key('giphy_results_grid'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final gif = _results[index];
        return Semantics(
          button: true,
          label: gif.title,
          child: InkWell(
            key: Key('giphy_result_${gif.id}'),
            onTap: () => widget.onSelected(calmMemeFromGiphy(gif)),
            borderRadius: .circular(8),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: .circular(8),
                    child: CalmMediaImage(imageUrl: gif.stillUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gif.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
