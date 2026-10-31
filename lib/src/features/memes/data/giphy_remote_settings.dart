import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote Config parameter for the Giphy beta key.
///
/// Published only in Firebase Remote Config — never in git. Free tier: about
/// 100 API requests/hour for that key across PWA HTTP calls and native SDK
/// configure. See `docs/wiki/Giphy-GIF-Search.md` and GitHub #741 if quota
/// gets tight.
const String kGiphyApiKeyParameter = 'giphy_api_key';

/// Remote Config parameter for the highest GIF rating to request.
///
/// Accepted values are `g`, `pg`, and `pg-13`. `pg` includes G and mild
/// clips such as superheroes. Anything else, including `r`, is treated as `pg`.
const String kGiphyContentRatingParameter = 'giphy_content_rating';

/// Ratings Search GIFs will send. Giphy treats the value as a ceiling.
const Set<String> kGiphyContentRatings = {'g', 'pg', 'pg-13'};

/// Maps a Remote Config value to `g`, `pg`, or `pg-13`. Anything else is PG.
String normalizeGiphyRating(String? raw) {
  final value = (raw ?? '').trim().toLowerCase().replaceAll(' ', '');
  if (value == 'pg13') return 'pg-13';
  if (kGiphyContentRatings.contains(value)) return value;
  return 'pg';
}

/// Short label for the picker and the attached reflection.
String giphyRatingLabel(String rating) =>
    switch (normalizeGiphyRating(rating)) {
      'g' => 'G',
      'pg-13' => 'PG-13',
      _ => 'PG',
    };

/// Key and rating ceiling used by GIF search.
class GiphyRemoteSettings {
  const GiphyRemoteSettings({required this.apiKey, required this.rating});

  final String apiKey;
  final String rating;

  static const fallback = GiphyRemoteSettings(apiKey: '', rating: 'pg');
}

/// Reads GIF search settings.
///
/// A published Remote Config key wins over [dartDefineKey]. A blank remote
/// key keeps the dart-define fallback. When Firebase is not ready, the rating
/// stays PG and only [dartDefineKey] can supply a key.
GiphyRemoteSettings readGiphyRemoteSettings({
  required bool firebaseReady,
  String Function(String key)? readString,
  String dartDefineKey = '',
}) {
  final localKey = dartDefineKey.trim();
  if (!firebaseReady || readString == null) {
    return GiphyRemoteSettings(apiKey: localKey, rating: 'pg');
  }

  final remoteKey = readString(kGiphyApiKeyParameter).trim();
  final remoteRating = readString(kGiphyContentRatingParameter);
  return GiphyRemoteSettings(
    apiKey: remoteKey.isNotEmpty ? remoteKey : localKey,
    rating: normalizeGiphyRating(
      remoteRating.trim().isEmpty ? 'pg' : remoteRating,
    ),
  );
}

final giphyRemoteSettingsProvider = Provider<GiphyRemoteSettings>((ref) {
  const dartDefineKey = String.fromEnvironment('GIPHY_API_KEY');
  if (Firebase.apps.isEmpty) {
    return readGiphyRemoteSettings(
      firebaseReady: false,
      dartDefineKey: dartDefineKey,
    );
  }
  try {
    final rc = FirebaseRemoteConfig.instance;
    return readGiphyRemoteSettings(
      firebaseReady: true,
      readString: rc.getString,
      dartDefineKey: dartDefineKey,
    );
  } catch (_) {
    return readGiphyRemoteSettings(
      firebaseReady: false,
      dartDefineKey: dartDefineKey,
    );
  }
});
