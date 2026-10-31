import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'giphy_surface.dart';

/// Legacy Remote Config parameter.
///
/// Older builds read this single key. New builds use it only as an Android
/// fallback when [kGiphyApiKeyAndroidParameter] is blank. Web and iOS never
/// read it, so an Android key cannot spend the web or iOS hourly pool.
const String kGiphyApiKeyParameter = 'giphy_api_key';

/// Android beta key. Official SDK, including Clips. About 100 requests/hour.
const String kGiphyApiKeyAndroidParameter = 'giphy_api_key_android';

/// iOS beta key. Official SDK, including Clips, once an iPhone build exists.
const String kGiphyApiKeyIosParameter = 'giphy_api_key_ios';

/// Web, PWA, and installed WebAPK beta key. HTTP GIF search only.
const String kGiphyApiKeyWebParameter = 'giphy_api_key_web';

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

/// Picks the beta key for [client].
///
/// Order: that platform's Remote Config parameter, then (Android only) the
/// legacy [kGiphyApiKeyParameter], then [dartDefineKey]. Web and iOS do not
/// use the Android or legacy key.
String resolveGiphyApiKey({
  required GiphyClient client,
  required String Function(String key) readString,
  String dartDefineKey = '',
}) {
  final specific = switch (client) {
    GiphyClient.android => readString(kGiphyApiKeyAndroidParameter),
    GiphyClient.ios => readString(kGiphyApiKeyIosParameter),
    GiphyClient.web => readString(kGiphyApiKeyWebParameter),
  }.trim();
  if (specific.isNotEmpty) return specific;
  if (client == GiphyClient.android) {
    final legacy = readString(kGiphyApiKeyParameter).trim();
    if (legacy.isNotEmpty) return legacy;
  }
  return dartDefineKey.trim();
}

/// Reads GIF search settings.
///
/// A published platform key wins over [dartDefineKey]. When Firebase is not
/// ready, the rating stays PG and only [dartDefineKey] can supply a key.
GiphyRemoteSettings readGiphyRemoteSettings({
  required bool firebaseReady,
  String Function(String key)? readString,
  String dartDefineKey = '',
  GiphyClient client = GiphyClient.web,
}) {
  final localKey = dartDefineKey.trim();
  if (!firebaseReady || readString == null) {
    return GiphyRemoteSettings(apiKey: localKey, rating: 'pg');
  }

  final remoteRating = readString(kGiphyContentRatingParameter);
  return GiphyRemoteSettings(
    apiKey: resolveGiphyApiKey(
      client: client,
      readString: readString,
      dartDefineKey: localKey,
    ),
    rating: normalizeGiphyRating(
      remoteRating.trim().isEmpty ? 'pg' : remoteRating,
    ),
  );
}

final giphyRemoteSettingsProvider = Provider<GiphyRemoteSettings>((ref) {
  const dartDefineKey = String.fromEnvironment('GIPHY_API_KEY');
  final client = giphyClientFor(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );
  if (Firebase.apps.isEmpty) {
    return readGiphyRemoteSettings(
      firebaseReady: false,
      dartDefineKey: dartDefineKey,
      client: client,
    );
  }
  try {
    final rc = FirebaseRemoteConfig.instance;
    return readGiphyRemoteSettings(
      firebaseReady: true,
      readString: rc.getString,
      dartDefineKey: dartDefineKey,
      client: client,
    );
  } catch (_) {
    return readGiphyRemoteSettings(
      firebaseReady: false,
      dartDefineKey: dartDefineKey,
      client: client,
    );
  }
});
