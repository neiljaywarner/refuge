import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/calm_meme.dart';
import 'giphy_remote_settings.dart';

/// A GIF from Giphy. [stillUrl] is the motionless preview.
/// [gifUrl] is what a member attaches to a reflection.
class GiphyGif {
  const GiphyGif({
    required this.id,
    required this.title,
    required this.stillUrl,
    required this.gifUrl,
    this.rating = 'pg',
  });

  final String id;
  final String title;
  final String stillUrl;
  final String gifUrl;
  final String rating;
}

/// Calm failure for GIF search. The message never includes the API key or
/// the raw HTTP body, which can echo the key.
class GiphySearchException implements Exception {
  const GiphySearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Looks up GIFs at the configured rating ceiling. An empty [search] query
/// means trending.
abstract class GiphySearch {
  bool get isConfigured;

  String get contentRating;

  Future<List<GiphyGif>> search(String query);
}

/// Giphy public API client.
///
/// The key comes from the platform Remote Config parameter
/// (`giphy_api_key_web` on the PWA), with `--dart-define=GIPHY_API_KEY` as a
/// fallback. A missing key is not an
/// error: [search] returns an empty list and never calls the network.
/// The rating comes from Remote Config `giphy_content_rating` and defaults
/// to PG.
class HttpGiphySearch implements GiphySearch {
  HttpGiphySearch({http.Client? httpClient, String? apiKey, String? rating})
    : _httpClient = httpClient ?? http.Client(),
      _apiKey = (apiKey ?? const String.fromEnvironment('GIPHY_API_KEY'))
          .trim(),
      _rating = normalizeGiphyRating(rating),
      _ownsClient = httpClient == null;

  static const _unavailable = GiphySearchException(
    'GIF search is unavailable right now.',
  );

  final http.Client _httpClient;
  final String _apiKey;
  final String _rating;
  final bool _ownsClient;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  String get contentRating => _rating;

  void close() {
    if (_ownsClient) _httpClient.close();
  }

  @override
  Future<List<GiphyGif>> search(String query) async {
    if (!isConfigured) return const [];

    final trimmed = query.trim();
    final bounded = trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
    final endpoint = bounded.isEmpty ? 'trending' : 'search';
    final uri = Uri.https('api.giphy.com', '/v1/gifs/$endpoint', {
      'api_key': _apiKey,
      'limit': '12',
      'rating': _rating,
      if (bounded.isNotEmpty) 'q': bounded,
    });

    final http.Response response;
    try {
      response = await _httpClient.get(uri);
    } catch (_) {
      throw _unavailable;
    }

    if (response.statusCode != 200) throw _unavailable;

    try {
      return parseGiphyGifPayload(jsonDecode(response.body));
    } on FormatException {
      throw _unavailable;
    }
  }
}

/// Turns a Giphy JSON payload into still-preview GIFs.
/// Drops items that lack an https still and an https GIF.
List<GiphyGif> parseGiphyGifPayload(Object? payload) {
  if (payload is! Map) return const [];
  final data = payload['data'];
  if (data is! List) return const [];

  final gifs = <GiphyGif>[];
  for (final item in data) {
    if (item is! Map) continue;
    final images = item['images'];
    if (images is! Map) continue;
    final still =
        _httpsUrl(images['fixed_height_still']) ??
        _httpsUrl(images['fixed_width_still']);
    final gif =
        _httpsUrl(images['fixed_height']) ?? _httpsUrl(images['downsized']);
    final id = item['id']?.toString().trim() ?? '';
    if (still == null || gif == null || id.isEmpty) continue;
    gifs.add(
      GiphyGif(
        id: id,
        title: _displayTitle(item['title']?.toString() ?? ''),
        stillUrl: still,
        gifUrl: gif,
        rating: normalizeGiphyRating(item['rating']?.toString()),
      ),
    );
  }
  return gifs;
}

/// Reflection attachment for a chosen GIF. The feed receives the GIF URL.
CalmMeme calmMemeFromGiphy(GiphyGif gif) => CalmMeme(
  title: gif.title,
  icon: '🎞️',
  subtitle: 'GIPHY · rated ${giphyRatingLabel(gif.rating)}',
  tag: 'Memes',
  body: gif.title,
  imageUrl: gif.gifUrl,
);

String _displayTitle(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'GIF';
  if (trimmed.length <= 80) return trimmed;
  return '${trimmed.substring(0, 77)}...';
}

String? _httpsUrl(Object? image) {
  if (image is! Map) return null;
  final url = image['url'];
  if (url is! String) return null;
  final trimmed = url.trim();
  if (!trimmed.startsWith('https://')) return null;
  return trimmed;
}

final giphySearchProvider = Provider<GiphySearch>((ref) {
  final settings = ref.watch(giphyRemoteSettingsProvider);
  final search = HttpGiphySearch(
    apiKey: settings.apiKey,
    rating: settings.rating,
  );
  ref.onDispose(search.close);
  return search;
});
