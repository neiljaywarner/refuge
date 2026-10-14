import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/about/presentation/about_refuge_dialog.dart';
import 'features/reflections/data/post_repository.dart';
import 'features/reflections/data/serverpod_post_repository.dart';
import 'features/reflections/domain/post.dart';
import 'features/reflections/presentation/community_anchor_banner.dart';
import 'features/reflections/presentation/quiet_digest_banner.dart';
import 'features/reflections/presentation/reflection_card.dart';
import 'features/reflections/presentation/reflection_composer.dart';
import 'features/reflections/presentation/space_navigation_bar.dart';
import 'features/reflections/presentation/tone_filter_row.dart';
import 'features/sensory_themes/domain/sensory_mode.dart';
import 'features/sensory_themes/presentation/sensory_theme_controller.dart';

/// Main screen of the Refuge (Sanctuary) calm-tech fellowship clubhouse.
/// Implemented as a ConsumerStatefulWidget following CodeWithAndrea's architecture.
class SanctuaryHomeScreen extends ConsumerStatefulWidget {
  final PostRepository? repository;
  final ThemeNotifier? themeNotifier;

  const SanctuaryHomeScreen({
    super.key,
    this.repository,
    this.themeNotifier,
  });

  @override
  ConsumerState<SanctuaryHomeScreen> createState() =>
      _SanctuaryHomeScreenState();
}

/// Alias for SanctuaryHomeScreen to support Refuge branding.
typedef RefugeHomeScreen = SanctuaryHomeScreen;

class _SanctuaryHomeScreenState extends ConsumerState<SanctuaryHomeScreen> {
  String _selectedSpace = 'prayer';
  String _activeFilter = 'All';
  String? _legacyQuietDigestMessage;
  Stream<List<Post>>? _legacyPostStream;

  PostRepository get _activeRepository {
    if (widget.repository != null) return widget.repository!;
    return ref.read(postRepositoryProvider);
  }

  @override
  void initState() {
    super.initState();
    _refreshStream();
  }

  void _refreshStream() {
    final repo = _activeRepository;
    setState(() {
      _legacyPostStream = repo.watchPosts(spaceKey: _selectedSpace);
    });
    repo.getQuietDigest(spaceKey: _selectedSpace).then((digest) {
      if (mounted && digest != null) {
        setState(() {
          _legacyQuietDigestMessage = digest;
        });
      }
    });
  }

  void _onSelectSpace(String spaceKey) {
    if (_selectedSpace != spaceKey) {
      setState(() {
        _selectedSpace = spaceKey;
      });
      _refreshStream();
    }
  }

  Future<void> _submitPost({
    required String content,
    required String toneTag,
    String? specialInterestTag,
  }) async {
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Fellowship Member',
      spaceKey: _selectedSpace,
      toneTag: toneTag,
      specialInterestTag: specialInterestTag,
      content: content,
      timestamp: DateTime.now(),
      reactions: {'pray': 1, 'peace': 1, 'encouraged': 1, 'relatable': 1},
    );

    await _activeRepository.createPost(newPost);
  }

  void _setSensoryMode(SensoryMode mode) {
    if (widget.themeNotifier != null) {
      widget.themeNotifier!.setMode(mode);
    } else {
      ref.read(sensoryThemeModeProvider.notifier).setMode(mode);
    }
  }

  SensoryMode get _currentMode {
    if (widget.themeNotifier != null) {
      return widget.themeNotifier!.mode;
    }
    return ref.watch(sensoryThemeModeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = _currentMode == SensoryMode.contrast;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final repo = _activeRepository;
    final isLiveServerpod =
        repo is ServerpodPostRepository && repo.isLiveConnected;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sanctuary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLiveServerpod
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF68A67D),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Calm Tech • ${isLiveServerpod ? "Live" : "Resilient"}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<SensoryMode>(
            tooltip: 'Sensory Themes',
            icon: const Icon(Icons.brightness_6_rounded, size: 20),
            onSelected: (mode) => _setSensoryMode(mode),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: SensoryMode.clean,
                child: Row(
                  children: [
                    Text('☀️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Clean'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.sage,
                child: Row(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Sage'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.charcoal,
                child: Row(
                  children: [
                    Text('🌙', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Dark'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SensoryMode.contrast,
                child: Row(
                  children: [
                    Text('👁️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('Contrast'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'About Sanctuary & Hackathon Credits',
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () => showAboutSanctuaryDialog(
              context,
              primaryColor: primaryColor,
              isContrast: isContrast,
              currentMode: _currentMode,
              onSelectMode: _setSensoryMode,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              CommunityAnchorBanner(
                primaryColor: primaryColor,
                isContrast: isContrast,
              ),
              SpaceNavigationBar(
                selectedSpace: _selectedSpace,
                onSelectSpace: _onSelectSpace,
              ),
              QuietDigestBanner(
                primaryColor: primaryColor,
                isContrast: isContrast,
                legacyMessage: _legacyQuietDigestMessage,
              ),
              ReflectionComposer(
                selectedSpace: _selectedSpace,
                primaryColor: primaryColor,
                isContrast: isContrast,
                onSubmit: _submitPost,
              ),
              ToneFilterRow(
                activeFilter: _activeFilter,
                onSelectFilter: (f) => setState(() => _activeFilter = f),
              ),
              Expanded(
                child: StreamBuilder<List<Post>>(
                  stream: _legacyPostStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    var posts = snapshot.data!;
                    if (_activeFilter != 'All') {
                      posts = posts
                          .where((p) => p.toneTag == _activeFilter)
                          .toList();
                    }

                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          'Space is quiet right now.\nBe the first to share an unhurried thought.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      itemBuilder: (context, index) {
                        final p = posts[index];
                        return ReflectionCard(
                          post: p,
                          isContrast: isContrast,
                          onAddReaction: (reactionType) =>
                              _activeRepository.addReaction(
                            postId: p.id,
                            reactionType: reactionType,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
