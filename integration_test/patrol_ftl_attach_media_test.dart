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

    // Tap the result tile, not the title text. On a mis-sized surface the
    // title finder can resolve while the hit lands in the search field
    // (hint "quiet, bread, chapel"), which opens the keyboard and never
    // attaches.
    final result = $(const Key('giphy_result_patrol-chapel'));
    await result.waitUntilVisible();
    await result.tap();
    await $(const Key('attached_meme_banner'))
        .waitUntilVisible(timeout: const Duration(seconds: 20));
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
              imageUrl: _still,
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

    await $(const Key('giphy_open_sdk_button')).waitUntilVisible();
    await $(const Key('giphy_open_sdk_button')).tap();
    await $(const Key('attached_meme_banner'))
        .waitUntilVisible(timeout: const Duration(seconds: 20));
    expect(seenRating, 'pg');
    expect($('Attached: quiet clip'), findsOneWidget);
    expect($(const Key('publish_reflection_button')), findsOneWidget);
  });
}

const _still =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGNwa6qg'
    'CmIYNWjUoFGDRg0aNWjUoIE3CADmqdAf59hpwwAAAABJRU5ErkJggg==';

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
      // Solid still. A network preview on panther does not have to finish
      // before the tile can paint or receive a tap.
      stillUrl: _still,
      gifUrl: _still,
    ),
  ];
}
