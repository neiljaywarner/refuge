import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where GIF search runs.
///
/// The official Giphy Flutter SDK is Android and iOS only. The PWA, and any
/// other target, uses the Giphy HTTP API. See `docs/wiki/Giphy-GIF-Search.md`.
enum GiphySurface { nativeSdk, webApi }

/// Which Giphy beta key Remote Config should supply.
///
/// Android, iOS, and web each have their own key and their own ~100
/// requests/hour pool. Web and iOS must not fall back to the Android key.
enum GiphyClient { android, ios, web }

/// Official SDK on Android and iOS. Web, PWA, WebAPK, and desktop stay on
/// the HTTP API even when the site is installed to a phone home screen.
GiphyClient giphyClientFor({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) return GiphyClient.web;
  return switch (platform) {
    TargetPlatform.iOS => GiphyClient.ios,
    TargetPlatform.android => GiphyClient.android,
    _ => GiphyClient.web,
  };
}

/// Official SDK tabs. The package default already includes these. Belong sets
/// them explicitly so the phone picker does not drift if the package default
/// changes.
const List<String> kNativeGiphyFeatures = [
  'recents',
  'gif',
  'sticker',
  'clips',
  'text',
  'emoji',
];

/// What the PWA search can attach. Clips, stickers, emoji, and animated text
/// stay on the native SDK.
const List<String> kWebApiGiphyFeatures = ['gif'];

GiphySurface giphySurfaceFor({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (!isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS)) {
    return GiphySurface.nativeSdk;
  }
  return GiphySurface.webApi;
}

final giphySurfaceProvider = Provider<GiphySurface>((ref) {
  return giphySurfaceFor(isWeb: kIsWeb, platform: defaultTargetPlatform);
});
