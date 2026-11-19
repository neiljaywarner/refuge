import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

class MockPostRepository extends Mock implements PostRepository {}

class _ImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageHttpClient();
}

class _ImageHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _ImageRequest();

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}
}

class _ImageHeaders extends Fake implements HttpHeaders {
  @override
  ContentType? get contentType => ContentType('image', 'png');
}

class _ImageRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _ImageHeaders();

  @override
  Future<HttpClientResponse> close() async => _ImageResponse(_pngBytes);
}

class _ImageResponse extends Fake implements HttpClientResponse {
  _ImageResponse(this.bytes);

  final List<int> bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _ImageHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(bytes)
          .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

/// 1x1 transparent PNG so image posts never dial the network.
final List<int> _pngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  setUpAll(() {
    registerFallbackValue(
      Post(
        id: 'fallback',
        authorName: 'Fellow Member',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'placeholder',
        timestamp: DateTime.utc(2026, 1, 1),
        reactions: const {},
      ),
    );
  });

  group('Text and image posts through a mocked repository', () {
    late LocalPostRepository local;
    late MockPostRepository repo;

    setUp(() {
      HttpOverrides.global = _ImageHttpOverrides();
      local = LocalPostRepository(isDevMode: true);
      repo = MockPostRepository();
      when(() => repo.watchPosts(spaceKey: any(named: 'spaceKey'))).thenAnswer((invocation) {
        final spaceKey = invocation.namedArguments[#spaceKey] as String;
        return local.watchPosts(spaceKey: spaceKey);
      });
      when(() => repo.watchSavedPosts()).thenAnswer((_) => local.watchSavedPosts());
      when(() => repo.getQuietDigest(spaceKey: any(named: 'spaceKey'))).thenAnswer((invocation) {
        final spaceKey = invocation.namedArguments[#spaceKey] as String;
        return local.getQuietDigest(spaceKey: spaceKey);
      });
      when(() => repo.createPost(any())).thenAnswer((invocation) async {
        final post = invocation.positionalArguments.single as Post;
        return local.createPost(post);
      });
      when(
        () => repo.addReaction(
          postId: any(named: 'postId'),
          reactionType: any(named: 'reactionType'),
        ),
      ).thenAnswer(
        (invocation) => local.addReaction(
          postId: invocation.namedArguments[#postId] as String,
          reactionType: invocation.namedArguments[#reactionType] as String,
        ),
      );
      when(
        () => repo.toggleReaction(
          postId: any(named: 'postId'),
          reactionType: any(named: 'reactionType'),
          userId: any(named: 'userId'),
          displayName: any(named: 'displayName'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer(
        (invocation) => local.toggleReaction(
          postId: invocation.namedArguments[#postId] as String,
          reactionType: invocation.namedArguments[#reactionType] as String,
          userId: invocation.namedArguments[#userId] as String,
          displayName: invocation.namedArguments[#displayName] as String,
          avatarUrl: invocation.namedArguments[#avatarUrl] as String?,
        ),
      );
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    Future<void> pumpHome(PatrolTester $) {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      return $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
    }

    patrolWidgetTest('Scenario: publishing a text reflection calls the mocked repository', (
      $,
    ) async {
      await pumpHome($);
      await $.pumpAndSettle();

      await $(const Key('home_top_bar_create_post_button')).tap();
      await $(const Key('menu_item_create_post')).tap();
      await $(const Key('reflection_composer_input')).last
          .enterText('Grateful for a quiet afternoon.');
      await $(const Key('publish_reflection_button')).last.tap();
      await $.pumpAndSettle();

      expect($('Grateful for a quiet afternoon.'), findsOneWidget);
      final published = verify(() => repo.createPost(captureAny())).captured.single as Post;
      expect(published.content, 'Grateful for a quiet afternoon.');
      expect(published.toneTag, '[Prayer Request]');
      expect(published.imageUrl, isNull);
      expect(published.spaceKey, 'prayer');
    });

    patrolWidgetTest(
      'Scenario: an image post stores the URL, alt text, and topic without the network',
      ($) async {
        await pumpHome($);
        await $.pumpAndSettle();

        await $(const Key('home_top_bar_create_post_button')).tap();
        await $(const Key('menu_item_create_image_post')).tap();
        await $(const Key('image_post_url_input')).enterText('https://example.com/calm.png');
        await $(const Key('image_post_alt_text_input')).enterText('A still lake at dawn');
        await $(const Key('special_interest_tag_input')).enterText('Scripture Art');
        await $(const Key('reflection_composer_input')).last
            .enterText('He leads me beside quiet waters.');
        await $.pumpAndSettle();
        expect($(const Key('image_post_preview_container')), findsOneWidget);

        await $(const Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        final published = verify(() => repo.createPost(captureAny())).captured.single as Post;
        expect(published.imageUrl, 'https://example.com/calm.png');
        expect(published.content, contains('He leads me beside quiet waters.'));
        expect(published.content, contains('[Image Description: A still lake at dawn]'));
        expect(published.specialInterestTag, 'Scripture Art');
        expect(published.toneTag, '[Special Interest]');
      },
    );

    patrolWidgetTest(
      'Scenario: removing an image and publishing a caption-only image uses the fallback line',
      ($) async {
        await pumpHome($);
        await $.pumpAndSettle();

        await $(const Key('home_top_bar_create_post_button')).tap();
        await $(const Key('menu_item_create_image_post')).tap();
        await $(const Key('image_post_url_input')).enterText('https://example.com/calm.png');
        await $.pumpAndSettle();
        await $(const Key('remove_image_button')).tap();
        await $.pumpAndSettle();
        expect($(const Key('image_post_preview_container')), findsNothing);

        await $(const Key('image_post_url_input')).enterText('https://example.com/calm.png');
        await $(const Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        final published = verify(() => repo.createPost(captureAny())).captured.single as Post;
        expect(published.content, contains('Shared an image reflection'));
        expect(published.imageUrl, 'https://example.com/calm.png');
      },
    );
  });
}
