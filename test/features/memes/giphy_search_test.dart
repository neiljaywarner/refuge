import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:giphy_flutter_sdk/dto/giphy_content_type.dart';
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
              'fixed_height_still': {
                'url': 'https://media.giphy.com/still.gif',
              },
              'fixed_height': {'url': 'https://media.giphy.com/move.gif'},
            },
          },
          {
            'id': 'skip',
            'title': 'insecure still',
            'images': {
              'fixed_height_still': {
                'url': 'http://insecure.example/still.gif',
              },
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
              'fixed_height_still': {
                'url': 'https://media.giphy.com/still.gif',
              },
              'downsized': {'url': 'https://media.giphy.com/move.gif'},
            },
          },
        ],
      });

      expect(gifs.single.title.length, 80);
      expect(gifs.single.title, endsWith('...'));
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
      expect(
        giphySurfaceFor(isWeb: false, platform: TargetPlatform.iOS),
        GiphySurface.nativeSdk,
      );
      expect(
        giphySurfaceFor(isWeb: true, platform: TargetPlatform.android),
        GiphySurface.webApi,
      );
      expect(
        giphySurfaceFor(isWeb: false, platform: TargetPlatform.macOS),
        GiphySurface.webApi,
      );
      expect(kNativeGiphyFeatures, contains('clips'));
      expect(kWebApiGiphyFeatures, ['gif']);
    });

    test('the SDK dialog is locked to PG and includes clips', () {
      final settings = belongGiphySettings('pg');
      expect(settings.rating, GiphyRating.pg);
      expect(settings.mediaTypeConfig, contains(GiphyContentType.clips));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.sticker));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.emoji));
      expect(settings.mediaTypeConfig, contains(GiphyContentType.text));
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
          readString: (key) =>
              key == kGiphyApiKeyParameter ? 'legacy-android' : '',
          dartDefineKey: 'local-key',
        ).apiKey,
        'local-key',
      );
    });

    test('Android falls back to the legacy key only', () {
      final settings = readGiphyRemoteSettings(
        firebaseReady: true,
        client: GiphyClient.android,
        readString: (key) =>
            key == kGiphyApiKeyParameter ? 'legacy-android' : '',
        dartDefineKey: 'local-key',
      );

      expect(settings.apiKey, 'legacy-android');
    });

    test('installed web and desktop stay on the web key slot', () {
      expect(
        giphyClientFor(isWeb: true, platform: TargetPlatform.android),
        GiphyClient.web,
      );
      expect(
        giphyClientFor(isWeb: false, platform: TargetPlatform.iOS),
        GiphyClient.ios,
      );
      expect(
        giphyClientFor(isWeb: false, platform: TargetPlatform.android),
        GiphyClient.android,
      );
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
      final search = HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
      );

      await search.search('  ');
      await search.search('  chapel lights  ');

      expect(httpClient.uris, hasLength(2));
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

      expect(httpClient.uris.map((uri) => uri.queryParameters['rating']), [
        'g',
        'pg-13',
        'pg',
      ]);
    });

    test('caps the query at 50 characters', () async {
      final httpClient = _RecordingClient();
      final search = HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
      );

      await search.search('x' * 60);

      expect(httpClient.uris.single.queryParameters['q']!.length, 50);
    });

    test('errors stay calm and omit the api key', () async {
      const secret = 'beta-key-do-not-leak';
      final httpClient = _RecordingClient(
        statusCode: 403,
        body: '{"message":"bad $secret"}',
      );
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
                'fixed_height_still': {
                  'url': 'https://media.giphy.com/still.gif',
                },
                'fixed_height': {'url': 'https://media.giphy.com/move.gif'},
              },
            },
          ],
        }),
      );
      final search = HttpGiphySearch(
        httpClient: httpClient,
        apiKey: 'beta-key',
      );

      final gifs = await search.search('');

      expect(gifs.single.id, 'abc');
    });
  });

  group('Search GIFs tab', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.physicalSize = const Size(
        1080,
        2400,
      );
      binding.platformDispatcher.implicitView?.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.resetPhysicalSize();
      binding.platformDispatcher.implicitView?.resetDevicePixelRatio();
    });

    testWidgets('explains that search is off when no key is configured', (
      tester,
    ) async {
      await tester.pumpWidget(_galleryHarness());
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('tab_giphy_search')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('giphy_unconfigured')), findsOneWidget);
      expect(find.byKey(const Key('giphy_attribution')), findsNothing);
    });

    testWidgets('attaches the GIF when a still preview is tapped', (
      tester,
    ) async {
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

      await tester.pumpWidget(
        _galleryHarness(search: fake, onSelected: (meme) => selected = meme),
      );
      await tester.tap(find.byKey(const Key('open_gallery_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('tab_giphy_search')));
      await tester.pump();
      await tester.pump();

      expect(find.text('quiet chapel'), findsOneWidget);
      expect(find.byKey(const Key('giphy_attribution')), findsOneWidget);
      expect(fake.lastQuery, '');

      await tester.enterText(
        find.byKey(const Key('giphy_search_input')),
        'bread',
      );
      await tester.tap(find.byKey(const Key('giphy_search_button')));
      await tester.pump();

      expect(fake.lastQuery, 'bread');

      await tester.tap(find.byKey(const Key('giphy_result_abc')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(selected, isNotNull);
      expect(selected!.imageUrl, 'https://media.giphy.com/move.gif');
      expect(selected!.title, 'quiet chapel');
      expect(find.text('🖼️ Autism & Faith Meme Gallery'), findsNothing);
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
          sdkLauncher:
              ({required apiKey, required rating, required onSelected}) {
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
      await tester.tap(find.byKey(const Key('tab_giphy_search')));
      await tester.pump();

      expect(find.byKey(const Key('giphy_open_sdk_button')), findsOneWidget);
      expect(find.byKey(const Key('giphy_search_input')), findsNothing);
      expect(find.textContaining('clips'), findsWidgets);

      await tester.tap(find.byKey(const Key('giphy_open_sdk_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(seenRating, 'pg');
      expect(selected!.imageUrl, 'https://media.giphy.com/hero.gif');
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
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
    );
  }
}

class _FakeGiphySearch implements GiphySearch {
  _FakeGiphySearch({required this.results});

  final List<GiphyGif> results;
  String? lastQuery;

  @override
  bool get isConfigured => true;

  @override
  String get contentRating => 'pg';

  @override
  Future<List<GiphyGif>> search(String query) async {
    lastQuery = query;
    return results;
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
      if (settings != null)
        giphyRemoteSettingsProvider.overrideWithValue(settings),
      if (sdkLauncher != null)
        giphySdkLauncherProvider.overrideWithValue(sdkLauncher),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_gallery_button'),
            onPressed: () => showMemeGalleryModal(
              context,
              onSelectedMeme: onSelected ?? (_) {},
            ),
            child: const Text('Open Gallery'),
          ),
        ),
      ),
    ),
  );
}
