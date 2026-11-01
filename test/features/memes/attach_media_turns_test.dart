import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/build/build_identity.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_build_stamp.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_refuge_dialog.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_remote_settings.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_sdk_picker.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_search.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_surface.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

const _tealStill =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGNwa6qgCmIYNWjUoFGDRg0aNWjUoIE3CADmqdAf59hpwwAAAABJRU5ErkJggg==';
const _amberStill =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAIAAABvFaqvAAAAH0lEQVR4nGM4MsWLKohh1KBRg0YNGjVo1KBRgwbeIAAcBKyubmnaIwAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('web attach turns keep Powered by GIPHY on the sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final search = _GateGiphySearch();
    await tester.pumpWidget(_shotApp(search: search, surface: GiphySurface.webApi));
    await tester.pump();

    expect(find.text('Add Meme / GIF'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_meme_gif_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Attach media'), findsOneWidget);
    expect(find.byKey(const Key('giphy_search_input')), findsOneWidget);
    expect(find.byKey(const Key('giphy_attribution')), findsOneWidget);
    expect(find.text('Powered by GIPHY'), findsOneWidget);
    expect(find.byKey(const Key('tab_giphy_search')), findsNothing);

    search.release();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('giphy_results_grid')), findsOneWidget);
    expect(find.text('quiet chapel'), findsOneWidget);
    expect(find.text('Powered by GIPHY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('giphy_result_chapel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('attached_meme_banner')), findsOneWidget);
    expect(find.text('Attached: quiet chapel'), findsOneWidget);
    expect(find.text('Attach media'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native sheet opens Giphy and leaves attribution to the SDK dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? seenRating;
    await tester.pumpWidget(
      _shotApp(
        search: _GateGiphySearch()..release(),
        surface: GiphySurface.nativeSdk,
        sdkLauncher: ({required apiKey, required rating, required onSelected}) {
          seenRating = rating;
          expect(apiKey, 'widget-fixture-not-a-giphy-key');
          onSelected(
            const CalmMeme(
              title: 'quiet clip',
              icon: '🎬',
              subtitle: 'GIPHY clip · rated PG',
              tag: 'Memes',
              body: 'quiet clip',
              imageUrl: 'https://media.giphy.com/media/widget-clip/200.gif',
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('add_meme_gif_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('giphy_open_sdk_button')), findsOneWidget);
    expect(find.textContaining('The feed attaches a silent GIF.'), findsOneWidget);
    expect(find.byKey(const Key('giphy_attribution')), findsNothing);
    expect(find.text('Powered by GIPHY'), findsNothing);

    await tester.tap(find.byKey(const Key('giphy_open_sdk_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(seenRating, 'pg');
    expect(find.text('Attached: quiet clip'), findsOneWidget);
  });

  testWidgets('About keeps the GIPHY gratitude line beside Vote & Feedback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('attach_media_shot_boundary'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAboutRefugeDialog(
                  context,
                  primaryColor: Colors.teal,
                  isContrast: false,
                  buildIdentity: const BuildIdentity(),
                  loadVersion: () async => AppVersionLabel.unknown,
                  onOpenFeedback: () {},
                ),
                child: const Text('About'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    final line = find.byKey(const Key('about_giphy_line'));
    await tester.ensureVisible(line);
    await tester.pumpAndSettle();
    expect(find.textContaining('gratefully powered by GIPHY'), findsOneWidget);
    expect(find.textContaining('does not endorse Belong'), findsOneWidget);
    expect(find.text('Vote & Feedback'), findsOneWidget);
    expect(find.byKey(const Key('about_support_copy')), findsOneWidget);
  });
}

Widget _shotApp({
  required GiphySearch search,
  required GiphySurface surface,
  GiphySdkLauncher? sdkLauncher,
}) {
  return RepaintBoundary(
    key: const Key('attach_media_shot_boundary'),
    child: ProviderScope(
      overrides: [
        giphySurfaceProvider.overrideWithValue(surface),
        giphySearchProvider.overrideWithValue(search),
        giphyRemoteSettingsProvider.overrideWithValue(
          const GiphyRemoteSettings(apiKey: 'widget-fixture-not-a-giphy-key', rating: 'pg'),
        ),
        if (sdkLauncher != null) giphySdkLauncherProvider.overrideWithValue(sdkLauncher),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: ReflectionComposer(
            selectedSpace: 'memes',
            primaryColor: Colors.teal,
            isContrast: false,
            isModal: true,
            onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async {},
          ),
        ),
      ),
    ),
  );
}

class _GateGiphySearch implements GiphySearch {
  final _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) async {
    await _gate.future;
    return const [
      GiphyGif(
        id: 'chapel',
        title: 'quiet chapel',
        stillUrl: _tealStill,
        gifUrl: 'https://media.giphy.com/media/widget-chapel/200.gif',
      ),
      GiphyGif(
        id: 'bread',
        title: 'warm bread',
        stillUrl: _amberStill,
        gifUrl: 'https://media.giphy.com/media/widget-bread/200.gif',
      ),
    ];
  }
}
