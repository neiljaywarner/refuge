import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:giphy_flutter_sdk/dto/giphy_content_type.dart';
import 'package:giphy_flutter_sdk/dto/giphy_image.dart';
import 'package:giphy_flutter_sdk/dto/giphy_images.dart';
import 'package:giphy_flutter_sdk/dto/giphy_media.dart';
import 'package:giphy_flutter_sdk/dto/giphy_rating.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_remote_settings.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_sdk_picker.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_search.dart';
import 'package:refuge4serverpod/src/features/memes/data/giphy_surface.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/memes/presentation/meme_gallery_modal.dart';

void main() {
  group('parseGiphyGifPayload', () {
    test('keeps https Giphy images and drops insecure or incomplete items', () {
      final gifs = parseGiphyGifPayload({
        'data': [
          {
            'id': 'abc',
            'title': 'quiet chapel',
            'images': {
              'fixed_height_still': {'url': 'https://media.giphy.com/still.gif'},
              'fixed_height': {'url': 'https://media.giphy.com/move.gif'},
            },
          },
          {
            'id': 'skip',
            'title': 'insecure still',
            'images': {
              'fixed_height_still': {'url': 'http://insecure.example/still.gif'},
              'fixed_height': {'url': 'https://media.giphy.com/move.gif'},
            },
          },
          {'id': '', 'title': 'missing id', 'images': {}},
        ],
      });

      expect(gifs, hasLength(1));
      expect(gifs.single.id, 'abc');
      expect(gifs.single.title, 'quiet chapel');
      expect(gifs.single.stillUrl, 'https://media.giphy.com/still.gif');
      expect(gifs.single.gifUrl, 'https://media.giphy.com/move.gif');
    });

    test('shortens a very long title', () {
      final gifs = parseGiphyGifPayload({
        'data': [
          {
            'id': 'long',
            'title': 'a' * 90,
            'images': {
              'fixed_height_still': {'url': 'https://media.giphy.com/still.gif'},
              'downsized': {'url': 'https://media.giphy.com/move.gif'},
            },
          },
        ],
      });

      expect(gifs.single.title.length, 80);
      expect(gifs.single.title, endsWith('...'));
    });
  });

  group('calmMemeFromGiphyMedia', () {
    test('uses an image rendition and ignores the Giphy page url', () {
      final pageOnly = calmMemeFromGiphyMedia(
        GiphyMedia(
          id: 'page',
          url: 'https://giphy.com/gifs/page',
          rating: GiphyRating.pg,
          images: const GiphyImages(),
        ),
      );
      expect(pageOnly, isNull);

      final downsized = calmMemeFromGiphyMedia(
        GiphyMedia(
          id: 'down',
          url: 'https://giphy.com/gifs/down',
          title: 'quiet room',
          rating: GiphyRating.pg,
          images: const GiphyImages(
            downsized: GiphyImage(gifUrl: 'https://media.giphy.com/down.gif'),
          ),
        ),
      );
      expect(downsized?.imageUrl, 'https://media.giphy.com/down.gif');

      final original = calmMemeFromGiphyMedia(
        GiphyMedia(
          id: 'orig',
          rating: GiphyRating.g,
          images: const GiphyImages(
            original: GiphyImage(gifUrl: 'https://media.giphy.com/orig.gif'),
            downsized: GiphyImage(gifUrl: 'https://media.giphy.com/down.gif'),
          ),
        ),
      );
      expect(original?.imageUrl, 'https://media.giphy.com/orig.gif');
    });
  });

  group('calmMemeFromGiphy', () {
    test('attaches the GIF url and labels the source', () {
      const gif = GiphyGif(
        id: 'abc',
        title: 'quiet chapel',
        stillUrl: 'https://media.giphy.com/still.gif',
        gifUrl: 'https://media.giphy.com/move.gif',
      );

      final meme = calmMemeFromGiphy(gif);

      expect(meme.imageUrl, gif.gifUrl);
      expect(meme.subtitle, 'GIPHY · rated PG');
      expect(meme.tag, 'Memes');
    });
  });

  group('giphySurfaceFor', () {
    test('phones use the official SDK and the web uses the API', () {
      expect(
        giphySurfaceFor(isWeb: false, platform: TargetPlatform.android),
        GiphySurface.nativeSdk,
      );
      expect(giphySurfaceFor(isWeb: false, platform: TargetPlatform.iOS), GiphySurface.nativeSdk);
      expect(giphySurfaceFor(isWeb: true, platform: TargetPlatform.android), GiphySurface.webApi);
      expect(giphySurfaceFor(isWeb: false, platform: TargetPlatform.macOS), GiphySurface.webApi);
    });

    test('iOS PWA and Mobile Safari standalone mode uses webApi and web key', () {
      expect(giphySurfaceFor(isWeb: true, platform: TargetPlatform.iOS), GiphySurface.webApi);
      expect(giphyClientFor(isWeb: true, platform: TargetPlatform.iOS), GiphyClient.web);
    });

    test('the SDK dialog is locked to PG and uses the native feature list', () {
      final settings = belongGiphySettings('pg');
      expect(settings.rating, GiphyRating.pg);
      expect(
        settings.mediaTypeConfig.map(GiphyContentTypeExtension.toStringValue).toList(),
        kNativeGiphyFeatures,
      );
      expect(settings.mediaTypeConfig, contains(GiphyContentType.clips));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.sticker));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.emoji));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.text));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.gif));
      expect(settings.enableDynamicText, isTrue);
      expect(belongGiphySettings('r').rating, GiphyRating.pg);
      expect(belongGiphySettings('pg-13').rating, GiphyRating.pg13);
    });
  });

  group('readGiphyRemoteSettings', () {
    test('a published Android key wins and a blank rating stays PG', () {
      final settings = readGiphyRemoteSettings(
        firebaseReady: true,
        client: GiphyClient.android,
        readString: (key) => switch (key) {
          kGiphyApiKeyAndroidParameter => 'android-key',
          kGiphyContentRatingParameter => '  ',
          _ => '',
        },
        dartDefineKey: 'local-key',
      );

      expect(settings.apiKey, 'android-key');
      expect(settings.rating, 'pg');
    });

    test('web and iOS never use the Android or legacy key', () {
      String read(String key) => switch (key) {
        kGiphyApiKeyParameter => 'legacy-android',
        kGiphyApiKeyAndroidParameter => 'android-key',
        kGiphyApiKeyIosParameter => 'ios-key',
        kGiphyApiKeyWebParameter => 'web-key',
        _ => '',
      };

      expect(
        readGiphyRemoteSettings(
          firebaseReady: true,
          client: GiphyClient.web,
          readString: read,
        ).apiKey,
        'web-key',
      );
      expect(
        readGiphyRemoteSettings(
          firebaseReady: true,
          client: GiphyClient.ios,
          readString: read,
        ).apiKey,
        'ios-key',
      );
      expect(
        readGiphyRemoteSettings(
          firebaseReady: true,
          client: GiphyClient.web,
          readString: (key) => key == kGiphyApiKeyParameter ? 'legacy-android' : '',
          dartDefineKey: 'local-key',
        ).apiKey,
        'local-key',
      );
    });

    test('Android falls back to the legacy key only', () {
      final settings = readGiphyRemoteSettings(
        firebaseReady: true,
        client: GiphyClient.android,
        readString: (key) => key == kGiphyApiKeyParameter ? 'legacy-android' : '',
        dartDefineKey: 'local-key',
      );

      expect(settings.apiKey, 'legacy-android');
    });

    test('installed web and desktop stay on the web key slot', () {
      expect(giphyClientFor(isWeb: true, platform: TargetPlatform.android), GiphyClient.web);
      expect(giphyClientFor(isWeb: false, platform: TargetPlatform.iOS), GiphyClient.ios);
      expect(giphyClientFor(isWeb: false, platform: TargetPlatform.android), GiphyClient.android);
    });

    test('keeps the dart-define key when Remote Config is blank', () {
      final settings = readGiphyRemoteSettings(
        firebaseReady: true,
        readString: (_) => '',
        dartDefineKey: 'local-key',
      );

      expect(settings.apiKey, 'local-key');
      expect(settings.rating, 'pg');
    });

    test('accepts g and pg-13 and treats r as pg', () {
      expect(normalizeGiphyRating('g'), 'g');
      expect(normalizeGiphyRating('PG-13'), 'pg-13');
      expect(normalizeGiphyRating('pg13'), 'pg-13');
      expect(normalizeGiphyRating('r'), 'pg');
      expect(normalizeGiphyRating(null), 'pg');
    });
  });

  group('HttpGiphySearch', () {
    test('missing key never calls the network', () async {
      final httpClient = _RecordingClient();
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: '   ');

      expect(search.isConfigured, isFalse);
      expect(await search.search('chapel'), isEmpty);
      expect(httpClient.uris, isEmpty);
    });

    test('trending and search stay on the PG ceiling', () async {
      final httpClient = _RecordingClient();
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: 'beta-key');

      await search.search('  ');
      await search.search('  chapel lights  ');

      expect(httpClient.uris, hasLength(2));
      expect(kWebApiGiphyFeatures, ['gif', 'text']);
      expect(httpClient.uris[0].path, '/v1/gifs/trending');
      expect(httpClient.uris[0].queryParameters['rating'], 'pg');
      expect(httpClient.uris[0].queryParameters['limit'], '12');
      expect(httpClient.uris[0].queryParameters.containsKey('q'), isFalse);
      expect(httpClient.uris[1].path, '/v1/gifs/search');
      expect(httpClient.uris[1].queryParameters['q'], 'chapel lights');
      expect(httpClient.uris[1].queryParameters['rating'], 'pg');
    });

    test('sends g or pg-13 when asked and refuses r', () async {
      final httpClient = _RecordingClient();
      await HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
        rating: 'g',
      ).search('heroes');
      await HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
        rating: 'pg-13',
      ).search('heroes');
      await HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
        rating: 'r',
      ).search('heroes');

      expect(httpClient.uris.map((uri) => uri.queryParameters['rating']), ['g', 'pg-13', 'pg']);
    });

    test('caps the query at 50 characters', () async {
      final httpClient = _RecordingClient();
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: 'beta-key');

      await search.search('x' * 60);

      expect(httpClient.uris.single.queryParameters['q']!.length, 50);
    });

    test('errors stay calm and omit the api key', () async {
      const secret = 'beta-key-do-not-leak';
      final httpClient = _RecordingClient(statusCode: 403, body: '{"message":"bad $secret"}');
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: secret);

      await expectLater(
        search.search('chapel'),
        throwsA(
          isA<GiphySearchException>().having(
            (error) => error.toString(),
            'message',
            isNot(contains(secret)),
          ),
        ),
      );
    });

    test('parses a 200 payload', () async {
      final httpClient = _RecordingClient(
        body: jsonEncode({
          'data': [
            {
              'id': 'abc',
              'title': 'quiet chapel',
              'images': {
                'fixed_height_still': {'url': 'https://media.giphy.com/still.gif'},
                'fixed_height': {'url': 'https://media.giphy.com/move.gif'},
              },
            },
          ],
        }),
      );
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: 'beta-key');

      final gifs = await search.search('');

      expect(gifs.single.id, 'abc');
    });

    test('animateText requests /v1/text/animate at PG ceiling and maps animated text items', () async {
      final httpClient = _RecordingClient(
        body: jsonEncode({
          'data': [
            {
              'id': 'anim_1',
              'title': 'calm words',
              'rating': 'pg',
              'images': {
                'fixed_height_still': {'url': 'https://media.giphy.com/text_still.gif'},
                'fixed_height': {'url': 'https://media.giphy.com/text_move.gif'},
              },
            },
          ],
        }),
      );
      // Even if initialized with pg-13, animateText enforces the PG ceiling.
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: 'beta-key', rating: 'pg-13');

      final results = await search.animateText('  calm words  ');

      expect(httpClient.uris.single.path, '/v1/text/animate');
      expect(httpClient.uris.single.queryParameters['m'], 'calm words');
      expect(httpClient.uris.single.queryParameters['s'], 'calm words');
      expect(httpClient.uris.single.queryParameters['rating'], 'pg');
      expect(httpClient.uris.single.queryParameters['limit'], '12');

      expect(results, hasLength(1));
      expect(results.single.id, 'anim_1');
      expect(results.single.title, 'calm words');
      expect(results.single.isAnimatedText, isTrue);

      final meme = calmMemeFromGiphy(results.single);
      expect(meme.subtitle, 'GIPHY animated text · rated PG');
      expect(meme.imageUrl, 'https://media.giphy.com/text_move.gif');
    });

    test('animateText caps input at 50 chars and ignores empty strings without network call', () async {
      final httpClient = _RecordingClient();
      final search = HttpGiphySearch(httpClient: httpClient, apiKey: 'beta-key');

      final empty = await search.animateText('   ');
      expect(empty, isEmpty);
      expect(httpClient.uris, isEmpty);

      await search.animateText('y' * 65);
      expect(httpClient.uris.single.queryParameters['m']!.length, 50);
    });
  });

  group('Attach media GIF search', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.implicitView?.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.resetPhysicalSize();
      binding.platformDispatcher.implicitView?.resetDevicePixelRatio();
    });

    testWidgets('explains that search is off when no key is configured', (tester) async {
      await tester.pumpWidget(_galleryHarness());
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Attach media'), findsOneWidget);
      expect(find.byKey(const Key('tab_giphy_search')), findsNothing);
      expect(find.byKey(const Key('giphy_unconfigured')), findsOneWidget);
      expect(find.byKey(const Key('giphy_attribution')), findsNothing);
    });

    testWidgets('attaches the GIF when a still preview is tapped', (tester) async {
      CalmMeme? selected;
      final fake = _FakeGiphySearch(
        results: const [
          GiphyGif(
            id: 'abc',
            title: 'quiet chapel',
            stillUrl: 'https://media.giphy.com/still.gif',
            gifUrl: 'https://media.giphy.com/move.gif',
          ),
        ],
      );

      await tester.pumpWidget(_galleryHarness(search: fake, onSelected: (meme) => selected = meme));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Attach media'), findsOneWidget);
      expect(find.byKey(const Key('tab_giphy_search')), findsNothing);
      expect(find.text('quiet chapel'), findsOneWidget);
      expect(find.byKey(const Key('giphy_attribution')), findsOneWidget);
      expect(find.text('Powered by GIPHY'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('giphy_attribution')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('giphy_still_motion_note')), findsOneWidget);
      expect(fake.lastQuery, '');

      await tester.enterText(find.byKey(const Key('giphy_search_input')), 'bread');
      await tester.tap(find.byKey(const Key('giphy_search_button')));
      await tester.pump();

      expect(fake.lastQuery, 'bread');

      await tester.tap(find.byKey(const Key('giphy_result_abc')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(selected, isNotNull);
      expect(selected!.imageUrl, 'https://media.giphy.com/move.gif');
      expect(selected!.title, 'quiet chapel');
      expect(find.text('Attach media'), findsNothing);
      expect(find.byKey(const Key('giphy_platform_note')), findsNothing);
    });

    testWidgets('Android opens the official SDK picker at PG', (tester) async {
      String? seenRating;
      CalmMeme? selected;

      await tester.pumpWidget(
        _galleryHarness(
          surface: GiphySurface.nativeSdk,
          settings: const GiphyRemoteSettings(apiKey: 'beta-key', rating: 'pg'),
          onSelected: (meme) => selected = meme,
          sdkLauncher: ({required apiKey, required rating, required onSelected}) {
            seenRating = rating;
            expect(apiKey, 'beta-key');
            onSelected(
              const CalmMeme(
                title: 'hero',
                icon: '🎬',
                subtitle: 'GIPHY clip · rated PG',
                tag: 'Memes',
                body: 'hero',
                imageUrl: 'https://media.giphy.com/hero.gif',
              ),
            );
          },
        ),
      );
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('giphy_open_sdk_button')), findsOneWidget);
      expect(find.byKey(const Key('giphy_search_input')), findsNothing);
      expect(find.byKey(const Key('giphy_attribution')), findsNothing);
      expect(find.textContaining('clips'), findsWidgets);

      await tester.tap(find.byKey(const Key('giphy_open_sdk_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(seenRating, 'pg');
      expect(selected!.imageUrl, 'https://media.giphy.com/hero.gif');
    });

    testWidgets(
      'iOS PWA (Mobile Safari standalone mode) renders web search and still previews without native SDK MethodChannel',
      (tester) async {
        CalmMeme? selected;
        final fake = _FakeGiphySearch(
          results: const [
            GiphyGif(
              id: 'pwa-gif',
              title: 'serene sanctuary',
              stillUrl: 'https://media.giphy.com/still_pwa.gif',
              gifUrl: 'https://media.giphy.com/move_pwa.gif',
            ),
          ],
        );

        final surface = giphySurfaceFor(isWeb: true, platform: TargetPlatform.iOS);
        expect(surface, GiphySurface.webApi);

        await tester.pumpWidget(
          _galleryHarness(
            surface: surface,
            search: fake,
            onSelected: (meme) => selected = meme,
          ),
        );
        await tester.tap(find.byKey(const Key('open_gallery_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('giphy_search_input')), findsOneWidget);
        expect(find.byKey(const Key('giphy_attribution')), findsOneWidget);
        expect(find.text('Powered by GIPHY'), findsOneWidget);
        expect(find.text('serene sanctuary'), findsOneWidget);

        await tester.tap(find.byKey(const Key('giphy_result_pwa-gif')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(selected, isNotNull);
        expect(selected!.imageUrl, 'https://media.giphy.com/move_pwa.gif');
        expect(selected!.title, 'serene sanctuary');
      },
    );

    testWidgets('keeps search, attribution, and the grid above the keyboard', (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final fake = _FakeGiphySearch(
        results: const [
          GiphyGif(
            id: 'abc',
            title: 'quiet chapel',
            stillUrl: 'https://media.giphy.com/still.gif',
            gifUrl: 'https://media.giphy.com/move.gif',
          ),
        ],
      );

      await tester.pumpWidget(_galleryHarness(search: fake));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('giphy_search_input')), findsOneWidget);
      expect(find.byKey(const Key('giphy_attribution')), findsOneWidget);
      expect(find.byKey(const Key('giphy_results_grid')), findsOneWidget);

      const keyboardTop = 640.0 - 280.0;
      final searchBox = tester.getRect(find.byKey(const Key('giphy_search_input')));
      final gridBox = tester.getRect(find.byKey(const Key('giphy_results_grid')));
      final creditBox = tester.getRect(find.byKey(const Key('giphy_attribution')));

      expect(searchBox.bottom, lessThan(keyboardTop));
      expect(creditBox.bottom, lessThanOrEqualTo(keyboardTop + 1));
      expect(gridBox.height, greaterThan(24));
      expect(gridBox.bottom, lessThanOrEqualTo(keyboardTop + 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a slower trending response cannot replace a newer search', (tester) async {
      final search = _QueuedGiphySearch();
      await tester.pumpWidget(_galleryHarness(search: search));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byKey(const Key('giphy_search_input')), 'bread');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(search.pendingCount(''), 1);
      expect(search.pendingCount('bread'), 1);

      search.complete('bread', const [
        GiphyGif(
          id: 'bread',
          title: 'quiet bread',
          stillUrl: 'https://media.giphy.com/bread-still.gif',
          gifUrl: 'https://media.giphy.com/bread.gif',
        ),
      ]);
      await tester.pump();
      search.complete('', const [
        GiphyGif(
          id: 'trend',
          title: 'trending chapel',
          stillUrl: 'https://media.giphy.com/trend-still.gif',
          gifUrl: 'https://media.giphy.com/trend.gif',
        ),
      ]);
      await tester.pump();

      expect(find.text('quiet bread'), findsOneWidget);
      expect(find.text('trending chapel'), findsNothing);
    });

    testWidgets('reopening the sheet reuses trending and skips a second request', (tester) async {
      final search = _CountingGiphySearch(
        results: const [
          GiphyGif(
            id: 'abc',
            title: 'quiet chapel',
            stillUrl: 'https://media.giphy.com/still.gif',
            gifUrl: 'https://media.giphy.com/move.gif',
          ),
        ],
      );
      await tester.pumpWidget(_galleryHarness(search: search));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(search.calls, 1);

      Navigator.of(tester.element(find.text('Attach media'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Attach media'), findsNothing);

      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump();

      expect(search.calls, 1);
      expect(find.text('quiet chapel'), findsOneWidget);
    });

    testWidgets('More hides the GIF field from semantics and drops the keyboard', (tester) async {
      final search = _FakeGiphySearch(
        results: const [
          GiphyGif(
            id: 'abc',
            title: 'quiet chapel',
            stillUrl: 'https://media.giphy.com/still.gif',
            gifUrl: 'https://media.giphy.com/move.gif',
          ),
        ],
      );
      await tester.pumpWidget(_galleryHarness(search: search));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump();

      tester.state<EditableTextState>(find.byType(EditableText)).requestKeyboard();
      await tester.pump();
      tester.widget<TextButton>(find.byKey(const Key('attach_media_more'))).onPressed!();
      await tester.pump();

      expect(find.byKey(const Key('attach_media_photo')), findsOneWidget);
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
      final excluded = tester.widget<ExcludeSemantics>(
        find
            .ancestor(
              of: find.byKey(const Key('giphy_search_input')),
              matching: find.byType(ExcludeSemantics),
            )
            .first,
      );
      expect(excluded.excluding, isTrue);
      final inert = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byKey(const Key('giphy_search_input')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(inert.ignoring, isTrue);
    });

    testWidgets('close control is named Close and at least 48 dp', (tester) async {
      await tester.pumpWidget(_galleryHarness(search: _FakeGiphySearch(results: const [])));
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump();

      expect(find.byTooltip('Close'), findsOneWidget);
      final size = tester.getSize(find.byKey(const Key('meme_gallery_close_button')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('web picker switches to Animate Text, types "calm words", and attaches animated text', (tester) async {
      CalmMeme? picked;
      final fakeSearch = _FakeGiphySearch(
        results: const [
          GiphyGif(
            id: 'gif_1',
            title: 'quiet river',
            stillUrl: 'https://media.giphy.com/river_s.gif',
            gifUrl: 'https://media.giphy.com/river.gif',
            rating: 'pg',
          ),
        ],
        animatedTextResults: const [
          GiphyGif(
            id: 'anim_calm',
            title: 'calm words',
            stillUrl: 'https://media.giphy.com/calm_s.gif',
            gifUrl: 'https://media.giphy.com/calm.gif',
            rating: 'pg',
            isAnimatedText: true,
          ),
        ],
      );

      await tester.pumpWidget(
        _galleryHarness(
          search: fakeSearch,
          onSelected: (meme) => picked = meme,
        ),
      );

      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initial state is standard GIF search
      expect(find.byKey(const Key('giphy_mode_gifs')), findsOneWidget);
      expect(find.byKey(const Key('giphy_mode_text')), findsOneWidget);
      expect(find.text('quiet river'), findsOneWidget);

      // Tap "Animate Text" mode chip
      await tester.tap(find.byKey(const Key('giphy_mode_text')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In empty text mode, prompts user
      expect(find.text('Type a phrase to see animated text styles.'), findsOneWidget);

      // Enter "calm words" and tap Animate
      await tester.enterText(find.byKey(const Key('giphy_search_input')), 'calm words');
      await tester.tap(find.byKey(const Key('giphy_search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeSearch.lastAnimatedText, 'calm words');
      expect(find.byKey(const Key('giphy_result_anim_calm')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('giphy_result_anim_calm')),
          matching: find.text('calm words'),
        ),
        findsOneWidget,
      );

      // Tap the animated text result to attach
      await tester.tap(find.byKey(const Key('giphy_result_anim_calm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(picked, isNotNull);
      expect(picked!.imageUrl, 'https://media.giphy.com/calm.gif');
      expect(picked!.subtitle, 'GIPHY animated text · rated PG');
    });
  });
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient({this.statusCode = 200, this.body = '{"data":[]}'});

  final int statusCode;
  final String body;
  final uris = <Uri>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uris.add(request.url);
    return http.StreamedResponse(Stream<List<int>>.value(utf8.encode(body)), statusCode);
  }
}

class _CountingGiphySearch extends _FakeGiphySearch {
  _CountingGiphySearch({required super.results, super.animatedTextResults});

  int calls = 0;

  @override
  Future<List<GiphyGif>> search(String query) {
    calls++;
    return super.search(query);
  }

  @override
  Future<List<GiphyGif>> animateText(String text) {
    calls++;
    return super.animateText(text);
  }
}

class _QueuedGiphySearch implements GiphySearch {
  final pending = <String, List<Completer<List<GiphyGif>>>>{};

  int pendingCount(String query) => pending[query]?.length ?? 0;

  void complete(String query, List<GiphyGif> results) {
    final next = pending[query]?.removeAt(0);
    if (next == null) {
      throw StateError('no pending search for "$query"');
    }
    next.complete(results);
  }

  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) {
    final completer = Completer<List<GiphyGif>>();
    pending.putIfAbsent(query, () => []).add(completer);
    return completer.future;
  }

  @override
  Future<List<GiphyGif>> animateText(String text) {
    final completer = Completer<List<GiphyGif>>();
    pending.putIfAbsent(text, () => []).add(completer);
    return completer.future;
  }
}

class _FakeGiphySearch implements GiphySearch {
  _FakeGiphySearch({required this.results, this.animatedTextResults});

  final List<GiphyGif> results;
  final List<GiphyGif>? animatedTextResults;
  String? lastQuery;
  String? lastAnimatedText;

  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) async {
    lastQuery = query;
    return results;
  }

  @override
  Future<List<GiphyGif>> animateText(String text) async {
    lastAnimatedText = text;
    return animatedTextResults ?? results;
  }
}

Widget _galleryHarness({
  GiphySearch? search,
  ValueChanged<CalmMeme>? onSelected,
  GiphySurface surface = GiphySurface.webApi,
  GiphyRemoteSettings? settings,
  GiphySdkLauncher? sdkLauncher,
}) {
  return ProviderScope(
    overrides: [
      giphySurfaceProvider.overrideWithValue(surface),
      if (search != null) giphySearchProvider.overrideWithValue(search),
      if (settings != null) giphyRemoteSettingsProvider.overrideWithValue(settings),
      if (sdkLauncher != null) giphySdkLauncherProvider.overrideWithValue(sdkLauncher),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_gallery_button'),
            onPressed: () => showMemeGalleryModal(context, onSelectedMeme: onSelected ?? (_) {}),
            child: const Text('Open Gallery'),
          ),
        ),
      ),
    ),
  );
}
