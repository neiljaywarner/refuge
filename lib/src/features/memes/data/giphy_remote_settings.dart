import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remote Config parameter for the Giphy beta key.
///
/// Leave the published value blank to turn GIF search off. The same beta key
/// can be pasted here for other PG refuge apps while you are trying the
/// feature. The app downloads this value, so it is not hidden from a member
/// who inspects the app. A copied key can use up the free hourly limit.
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
