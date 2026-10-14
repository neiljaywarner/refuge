import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Post Model & Repository Unit Tests', () {
    test('Post copyWith modifies fields immutably', () {
      final now = DateTime.now();
      final post = Post(
        id: '101',
        authorName: 'Grace K.',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Original prayer text',
        timestamp: now,
        reactions: {'pray': 2, 'peace': 1},
      );

      final updated = post.copyWith(content: 'Updated peaceful reflection');
      expect(updated.content, 'Updated peaceful reflection');
      expect(updated.id, '101');
      expect(updated.reactions['pray'], 2);
      expect(post.content, 'Original prayer text');
    });

    test('LocalPostRepository supports creating posts and streaming updates', () async {
      final repo = LocalPostRepository();
      final initial = await repo.getPosts(spaceKey: 'prayer');
      expect(initial.length, greaterThanOrEqualTo(2));

      final newPost = Post(
        id: '202',
        authorName: 'Hannah T.',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Finding quiet in the storm.',
        timestamp: DateTime.now(),
        reactions: {'peace': 3},
      );

      await repo.createPost(newPost);
      final afterCreate = await repo.getPosts(spaceKey: 'prayer');
      expect(afterCreate.first.id, '202');
      expect(afterCreate.first.content, 'Finding quiet in the storm.');
    });

    test('addReaction increments reaction count correctly', () async {
      final repo = LocalPostRepository();
      final posts = await repo.getPosts(spaceKey: 'prayer');
      final firstPostId = posts.first.id;
      final initialPrayCount = posts.first.reactions['pray'] ?? 0;

      await repo.addReaction(postId: firstPostId, reactionType: 'pray');
      final updatedPosts = await repo.getPosts(spaceKey: 'prayer');
      final updatedPrayCount = updatedPosts.first.reactions['pray'] ?? 0;

      expect(updatedPrayCount, equals(initialPrayCount + 1));
    });

    test('ServerpodPostRepository operates resiliently with fallback', () async {
      final repo = ServerpodPostRepository(serverUrl: 'http://localhost:9999/');
      final posts = await repo.getPosts(spaceKey: 'prayer');
      expect(posts, isNotEmpty);

      final newPost = Post(
        id: '303',
        authorName: 'Samuel L.',
        spaceKey: 'prayer',
        toneTag: '[Resource]',
        content: 'Sharing a soothing reflection on Psalm 46:10.',
        timestamp: DateTime.now(),
        reactions: {'pray': 1},
      );

      await repo.createPost(newPost);
      final refreshed = await repo.getPosts(spaceKey: 'prayer');
      expect(refreshed.first.id, '303');
    });

    test('PostRepositoryFactory creates configured repository mode', () {
      final repo = PostRepositoryFactory.create();
      expect(repo, isA<PostRepository>());
    });
  });
}
