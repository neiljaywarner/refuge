import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

void main() {
  group('Feed Stream Multi-Subscription & Replay Resilience (#458)', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository(isDevMode: true);
    });

    test('watchPosts delivers cached reflections immediately to the first listener', () async {
      final stream = repository.watchPosts(spaceKey: 'prayer');
      final firstEmission = await stream.first;

      expect(firstEmission, isNotEmpty);
      expect(firstEmission.every((p) => p.spaceKey == 'prayer'), isTrue);
    });

    test('watchPosts delivers cached reflections immediately to subsequent late listeners', () async {
      final stream = repository.watchPosts(spaceKey: 'prayer');

      // First listener subscribes and completes
      final list1 = await stream.first;
      expect(list1, isNotEmpty);

      // Second listener subscribes later: must receive reflections immediately without hanging
      final list2 = await stream.first.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => throw TimeoutException('Subsequent listener timed out waiting for initial yield'),
      );
      expect(list2, isNotEmpty);
      expect(list2.length, equals(list1.length));
    });

    test('watchSavedPosts delivers saved reflections to multiple late listeners', () async {
      // Toggle save on a post
      final posts = await repository.getPosts(spaceKey: 'prayer');
      final target = posts.first;
      await repository.toggleSavePost(postId: target.id);

      final stream = repository.watchSavedPosts();

      // First listener
      final saved1 = await stream.first;
      expect(saved1.any((p) => p.id == target.id), isTrue);

      // Second late listener
      final saved2 = await stream.first.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => throw TimeoutException('Second saved posts listener timed out'),
      );
      expect(saved2.any((p) => p.id == target.id), isTrue);
    });

    test('watchPosts emits updated list when a new post is added', () async {
      final stream = repository.watchPosts(spaceKey: 'prayer');

      final completer = Completer<List<Post>>();
      int emissionCount = 0;

      final sub = stream.listen((posts) {
        emissionCount++;
        if (emissionCount == 2) {
          completer.complete(posts);
        }
      });

      // Add a post
      await repository.createPost(
        Post(
          id: 'test-resilience-post',
          authorName: 'Resilience Test',
          spaceKey: 'prayer',
          toneTag: '[Encouragement]',
          content: 'Testing stream broadcast responsiveness',
          timestamp: DateTime.now(),
          reactions: {'pray': 1},
        ),
      );

      final updatedPosts = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(updatedPosts.any((p) => p.id == 'test-resilience-post'), isTrue);
      await sub.cancel();
    });
  });
}
