import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:sanctuary_server_client/sanctuary_server_client.dart' as sp;

class MockPostRepository extends Mock implements PostRepository {}

class MockServerpodClient extends Mock implements sp.Client {}

class MockReflectionEndpoint extends Mock implements sp.EndpointReflection {}

class _ImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageHttpClient();
}

class _ImageHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ImageRequest();
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
  }) {
    return Stream<List<int>>.value(bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
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
    registerFallbackValue(
      sp.ReflectionPost(
        authorName: 'Fellow Member',
        spaceKey: 'prayer',
        intentTag: '[Prayer Request]',
        content: 'placeholder',
        createdAt: DateTime.utc(2026, 1, 1),
        prayingCount: 0,
        standingWithCount: 0,
        peaceCount: 0,
        encouragedCount: 0,
      ),
    );
    registerFallbackValue(
      sp.QuietDigest(
        spaceKey: 'prayer',
        totalReflections: 0,
        totalCareAffirmations: 0,
        predominantIntent: '[Prayer Request]',
        summaryMessage: 'placeholder',
        generatedAt: DateTime.utc(2026, 1, 1),
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
      when(() => repo.watchPosts(spaceKey: any(named: 'spaceKey')))
          .thenAnswer((invocation) {
            final spaceKey = invocation.namedArguments[#spaceKey] as String;
            return local.watchPosts(spaceKey: spaceKey);
          });
      when(() => repo.watchSavedPosts())
          .thenAnswer((_) => local.watchSavedPosts());
      when(() => repo.getQuietDigest(spaceKey: any(named: 'spaceKey')))
          .thenAnswer((invocation) {
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
      ).thenAnswer((invocation) {
        return local.addReaction(
          postId: invocation.namedArguments[#postId] as String,
          reactionType: invocation.namedArguments[#reactionType] as String,
        );
      });
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
      return $.pumpWidget(
        RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
      );
    }

    patrolWidgetTest(
      'Scenario: publishing a text reflection calls the mocked repository',
      ($) async {
        await pumpHome($);
        await $.pumpAndSettle();

        await $(const Key('home_top_bar_create_post_button')).tap();
        await $(const Key('menu_item_create_post')).tap();
        await $(const Key('reflection_composer_input')).last
            .enterText('Grateful for a quiet afternoon.');
        await $(const Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        expect($('Grateful for a quiet afternoon.'), findsOneWidget);
        final published =
            verify(() => repo.createPost(captureAny())).captured.single as Post;
        expect(published.content, 'Grateful for a quiet afternoon.');
        expect(published.toneTag, '[Prayer Request]');
        expect(published.imageUrl, isNull);
        expect(published.spaceKey, 'prayer');
      },
    );

    patrolWidgetTest(
      'Scenario: an image post stores the URL, alt text, and topic without the network',
      ($) async {
        await pumpHome($);
        await $.pumpAndSettle();

        await $(const Key('home_top_bar_create_post_button')).tap();
        await $(const Key('menu_item_create_image_post')).tap();
        await $(const Key('image_post_url_input'))
            .enterText('https://example.com/calm.png');
        await $(const Key('image_post_alt_text_input'))
            .enterText('A still lake at dawn');
        await $(const Key('special_interest_tag_input'))
            .enterText('Scripture Art');
        await $(const Key('reflection_composer_input')).last
            .enterText('He leads me beside quiet waters.');
        await $.pumpAndSettle();
        expect($(const Key('image_post_preview_container')), findsOneWidget);

        await $(const Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        final published =
            verify(() => repo.createPost(captureAny())).captured.single as Post;
        expect(published.imageUrl, 'https://example.com/calm.png');
        expect(published.content, contains('He leads me beside quiet waters.'));
        expect(
          published.content,
          contains('[Image Description: A still lake at dawn]'),
        );
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
        await $(const Key('image_post_url_input'))
            .enterText('https://example.com/calm.png');
        await $.pumpAndSettle();
        await $(const Key('remove_image_button')).tap();
        await $.pumpAndSettle();
        expect($(const Key('image_post_preview_container')), findsNothing);

        await $(const Key('image_post_url_input'))
            .enterText('https://example.com/calm.png');
        await $(const Key('publish_reflection_button')).last.tap();
        await $.pumpAndSettle();

        final published =
            verify(() => repo.createPost(captureAny())).captured.single as Post;
        expect(published.content, contains('Shared an image reflection'));
        expect(published.imageUrl, 'https://example.com/calm.png');
      },
    );
  });

  group('ServerpodPostRepository with a mocked client', () {
    late MockServerpodClient client;
    late MockReflectionEndpoint endpoint;

    setUp(() {
      client = MockServerpodClient();
      endpoint = MockReflectionEndpoint();
      when(() => client.reflection).thenReturn(endpoint);
    });

    sp.ReflectionPost samplePost({
      int? id,
      String content = 'A quiet word.',
      DateTime? createdAt,
    }) {
      return sp.ReflectionPost(
        id: id,
        authorName: 'Fellow Member',
        spaceKey: 'study',
        intentTag: '[Bible Deep Dive]',
        specialInterestTag: 'Mark',
        content: content,
        createdAt: createdAt ?? DateTime.utc(2026, 10, 1),
        prayingCount: 1,
        standingWithCount: 0,
        peaceCount: 2,
        encouragedCount: 3,
      );
    }

    ServerpodPostRepository buildRepo() {
      return ServerpodPostRepository(
        client: client,
        fallback: LocalPostRepository(isDevMode: false),
        isDevMode: false,
      );
    }

    test('publishReflection success stores the server id and marks the client live', () async {
      when(() => endpoint.publishReflection(any())).thenAnswer((
        invocation,
      ) async {
        final sent = invocation.positionalArguments.single as sp.ReflectionPost;
        return samplePost(id: 42, content: sent.content);
      });

      final repo = buildRepo();
      final created = await repo.createPost(
        Post(
          id: 'local-1',
          authorName: 'Fellow Member',
          spaceKey: 'study',
          toneTag: '[Bible Deep Dive]',
          specialInterestTag: 'Mark',
          content: 'A quiet word.',
          timestamp: DateTime.utc(2026, 10, 1),
          reactions: const {
            'pray': 1,
            'peace': 2,
            'encouraged': 3,
            'standing': 0,
          },
        ),
      );

      expect(created.id, '42');
      expect(repo.isLiveConnected, isTrue);
      verify(() => endpoint.publishReflection(any())).called(1);
    });

    test('publishReflection failure falls back to the local store', () async {
      when(() => endpoint.publishReflection(any()))
          .thenThrow(Exception('serverpod down'));
      final repo = buildRepo();
      final created = await repo.createPost(
        Post(
          id: 'local-2',
          authorName: 'Fellow Member',
          spaceKey: 'prayer',
          toneTag: '[Prayer Request]',
          content: 'Praying for a calm week.',
          timestamp: DateTime.utc(2026, 10, 2),
          reactions: const {},
        ),
      );

      expect(created.id, 'local-2');
      expect(repo.isLiveConnected, isFalse);
      final stored = await repo.getPosts(spaceKey: 'prayer');
      expect(stored.single.content, 'Praying for a calm week.');
    });

    test(
      'watchSpace maps live rows and quiet digest uses the mocked summary',
      () async {
        final updates = StreamController<sp.ReflectionPost>(sync: true);
        when(() => endpoint.watchSpace('study'))
            .thenAnswer((_) => updates.stream);
        when(() => endpoint.getQuietDigest('memes')).thenAnswer(
          (_) async => sp.QuietDigest(
            spaceKey: 'prayer',
            totalReflections: 3,
            totalCareAffirmations: 8,
            predominantIntent: '[Prayer Request]',
            summaryMessage: 'Three reflections gathered in peace.',
            generatedAt: DateTime.utc(2026, 10, 3),
          ),
        );

        final repo = buildRepo();
        final seen = <List<Post>>[];
        final subscription = repo
            .watchPosts(spaceKey: 'study')
            .listen(seen.add);
        await Future<void>.value();

        updates.add(
          samplePost(
            id: 7,
            content: 'First reading.',
            createdAt: DateTime.utc(2026, 10, 1, 9),
          ),
        );
        updates.add(
          samplePost(
            id: 7,
            content: 'Revised reading.',
            createdAt: DateTime.utc(2026, 10, 1, 10),
          ),
        );
        updates.add(
          samplePost(
            id: 8,
            content: 'A second note.',
            createdAt: DateTime.utc(2026, 10, 1, 11),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await Future<void>.value();
        }

        expect(seen.last.map((post) => post.content).toList(), [
          'A second note.',
          'Revised reading.',
        ]);
        expect(seen.last.first.id, '8');
        expect(repo.isLiveConnected, isTrue);

        final digest = await repo.getQuietDigest(spaceKey: 'memes');
        expect(digest, 'Three reflections gathered in peace.');
        verify(() => endpoint.getQuietDigest('memes')).called(1);
        subscription.cancel();
      },
    );

    test(
      'affirmCare is sent for numeric ids and skipped for local ids',
      () async {
        when(() => endpoint.affirmCare(any(), any()))
            .thenAnswer((_) async => samplePost(id: 15));
        when(() => endpoint.getQuietDigest(any()))
            .thenThrow(Exception('timeout'));

        final repo = buildRepo();
        await repo.addReaction(postId: '15', reactionType: 'pray');
        verify(() => endpoint.affirmCare(15, 'praying')).called(1);
        expect(repo.isLiveConnected, isTrue);

        await repo.addReaction(postId: 'local-9', reactionType: 'peace');
        verifyNever(() => endpoint.affirmCare(any(), 'peace'));

        final digest = await repo.getQuietDigest(spaceKey: 'special_interests');
        expect(
          digest,
          'A quiet, unhurried space awaiting the first community reflection.',
        );
        expect(repo.isLiveConnected, isFalse);
      },
    );
  });
}
