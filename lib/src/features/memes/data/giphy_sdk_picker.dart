import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giphy_flutter_sdk/dto/giphy_content_type.dart';
import 'package:giphy_flutter_sdk/dto/giphy_media.dart';
import 'package:giphy_flutter_sdk/dto/giphy_rating.dart';
import 'package:giphy_flutter_sdk/dto/giphy_settings.dart';
import 'package:giphy_flutter_sdk/giphy_dialog.dart';
import 'package:giphy_flutter_sdk/giphy_flutter_sdk.dart';

import '../domain/calm_meme.dart';
import 'giphy_remote_settings.dart';

/// Opens the official Giphy dialog. Tests replace this so they never touch
/// the native plugin.
typedef GiphySdkLauncher = void Function({
  required String apiKey,
  required String rating,
  required void Function(CalmMeme meme) onSelected,
});

final giphySdkLauncherProvider = Provider<GiphySdkLauncher>(
  (ref) => launchBelongGiphyDialog,
);

/// Phone picker settings. Rating defaults to PG. The SDK's own default is
/// PG-13, so this function always sets the rating explicitly.
GiphySettings belongGiphySettings(String rating) => GiphySettings(
  rating: giphySdkRating(rating),
  mediaTypeConfig: const [
    GiphyContentType.recents,
    GiphyContentType.gif,
    GiphyContentType.sticker,
    GiphyContentType.clips,
    GiphyContentType.text,
    GiphyContentType.emoji,
  ],
  selectedContentType: GiphyContentType.gif,
  enableDynamicText: true,
  showConfirmationScreen: true,
);

GiphyRating giphySdkRating(String rating) =>
    switch (normalizeGiphyRating(rating)) {
      'g' => GiphyRating.g,
      'pg-13' => GiphyRating.pg13,
      _ => GiphyRating.pg,
    };

/// Turns a dialog selection into a reflection attachment.
///
/// The feed receives an https GIF or image URL, including for clips, so the
/// sanctuary does not autoplay sound. Explicit ratings are dropped.
CalmMeme? calmMemeFromGiphyMedia(GiphyMedia media) {
  if (media.rating == GiphyRating.r ||
      media.rating == GiphyRating.nsfw ||
      media.rating == GiphyRating.unrated) {
    return null;
  }
  final url = _https(media.images.original?.gifUrl) ?? _https(media.url);
  if (url == null) return null;
  final title = (media.title ?? media.altText ?? '').trim();
  final display = title.isEmpty
      ? 'GIF'
      : (title.length <= 80 ? title : '${title.substring(0, 77)}...');
  final ratingToken = switch (media.rating) {
    GiphyRating.g => 'g',
    GiphyRating.pg13 => 'pg-13',
    _ => 'pg',
  };
  final kind = media.isVideo
      ? 'clip'
      : media.isSticker
      ? 'sticker'
      : media.isDynamic
      ? 'animated text'
      : 'GIF';
  return CalmMeme(
    title: display,
    icon: media.isVideo ? '🎬' : '🎞️',
    subtitle: 'GIPHY $kind · rated ${giphyRatingLabel(ratingToken)}',
    tag: 'Memes',
    body: display,
    imageUrl: url,
  );
}

void launchBelongGiphyDialog({
  required String apiKey,
  required String rating,
  required void Function(CalmMeme meme) onSelected,
}) {
  GiphyFlutterSDK.configure(apiKey: apiKey);
  final listener = _BelongGiphyListener(onSelected);
  GiphyDialog.instance.addListener(listener);
  GiphyDialog.instance.configure(settings: belongGiphySettings(rating));
  GiphyDialog.instance.show();
}

class _BelongGiphyListener implements GiphyMediaSelectionListener {
  _BelongGiphyListener(this._onSelected);

  final void Function(CalmMeme meme) _onSelected;

  @override
  void onMediaSelect(GiphyMedia media) {
    GiphyDialog.instance.removeListener(this);
    final meme = calmMemeFromGiphyMedia(media);
    if (meme != null) _onSelected(meme);
  }

  @override
  void onDismiss() {
    GiphyDialog.instance.removeListener(this);
  }
}

String? _https(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (!trimmed.startsWith('https://')) return null;
  return trimmed;
}
