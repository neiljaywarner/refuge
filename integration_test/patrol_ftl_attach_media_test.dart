import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_remote_settings.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_sdk_picker.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_search.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_surface.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';

import 'patrol_app_harness.dart';

/// Dev-only Firebase Test Lab target.
///
/// Uses the read-only home harness plus an in-memory Giphy double. It never
/// publishes a reflection, never calls the Giphy network, and never logs a key.
///
/// ```bash
/// dart run tool/run_firebase_test_lab.dart \
///   --target integration_test/patrol_ftl_attach_media_test.dart
/// ```
void main() {
  patrolTest('FTL: dev attach sheet searches GIFs and does not publish', ($) async {
    await pumpDevReadOnlyHome(
      $,
      extraOverrides: [
        giphySurfaceProvider.overrideWithValue(GiphySurface.webApi),
        giphyRemoteSettingsProvider.overrideWithValue(
          const GiphyRemoteSettings(apiKey: 'patrol-fixture-not-a-giphy-key', rating: 'pg'),
        ),
        giphySearchProvider.overrideWithValue(_PatrolGiphySearch()),
      ],
    );

    final add = $(const Key('composer_add_meme_compact_button'));
    await add.scrollTo();
    await add.tap();
    expect($('Attach media'), findsOneWidget);
    expect($('Powered by GIPHY'), findsOneWidget);
    expect($('quiet chapel'), findsOneWidget);
    expect($(const Key('tab_giphy_search')), findsNothing);

    await $('quiet chapel').tap();
    expect($('Attached: quiet chapel'), findsOneWidget);
    expect($(const Key('publish_reflection_button')), findsOneWidget);
    expect($('Attach media'), findsNothing);
  });

  patrolTest('FTL: dev native Open Giphy attaches without the HTTP footer', ($) async {
    String? seenRating;
    await pumpDevReadOnlyHome(
      $,
      extraOverrides: [
        giphySurfaceProvider.overrideWithValue(GiphySurface.nativeSdk),
        giphyRemoteSettingsProvider.overrideWithValue(
          const GiphyRemoteSettings(apiKey: 'patrol-fixture-not-a-giphy-key', rating: 'pg'),
        ),
        giphySearchProvider.overrideWithValue(_PatrolGiphySearch()),
        giphySdkLauncherProvider.overrideWithValue(({
          required apiKey,
          required rating,
          required onSelected,
        }) {
          seenRating = rating;
          expect(apiKey, isNotEmpty);
          onSelected(
            const CalmMeme(
              title: 'quiet clip',
              icon: '🎬',
              subtitle: 'GIPHY clip · rated PG',
              tag: 'Memes',
              body: 'quiet clip',
              imageUrl: 'https://media.giphy.com/media/patrol-clip/200.gif',
            ),
          );
        }),
      ],
    );

    final add = $(const Key('composer_add_meme_compact_button'));
    await add.scrollTo();
    await add.tap();
    expect($(find.textContaining('Open Giphy')), findsOneWidget);
    expect($('Powered by GIPHY'), findsNothing);
    expect($(find.textContaining('The feed attaches a silent GIF.')), findsOneWidget);

    await $(const Key('giphy_open_sdk_button')).tap();
    expect(seenRating, 'pg');
    expect($('Attached: quiet clip'), findsOneWidget);
    expect($(const Key('publish_reflection_button')), findsOneWidget);
  });
}

class _PatrolGiphySearch implements GiphySearch {
  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) async => const [
    GiphyGif(
      id: 'patrol-chapel',
      title: 'quiet chapel',
      stillUrl: 'https://media.giphy.com/media/patrol-still/200_s.gif',
      gifUrl: 'https://media.giphy.com/media/patrol-move/200.gif',
    ),
  ];
}
