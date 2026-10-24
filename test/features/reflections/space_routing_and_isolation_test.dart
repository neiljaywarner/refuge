import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/reflections/data/serverpod_post_repository.dart';

void main() {
  group('Space Routing and Post Isolation (#445, #446)', () {
    test('ServerpodPostRepository routes distinct spaces without collapsing to prayer', () async {
      final repo = ServerpodPostRepository(isDevMode: true);

      // Verify each space retains its distinct posts
      final prayerPosts = await repo.getPosts(spaceKey: 'prayer');
      final generalPosts = await repo.getPosts(spaceKey: 'general_chat');
      final welcomePosts = await repo.getPosts(spaceKey: 'start_here');
      final announcementPosts = await repo.getPosts(spaceKey: 'announcements');

      expect(prayerPosts.every((p) => p.spaceKey == 'prayer'), isTrue);
      expect(generalPosts.every((p) => p.spaceKey == 'general_chat'), isTrue);
      expect(welcomePosts.every((p) => p.spaceKey == 'start_here'), isTrue);
      expect(announcementPosts.every((p) => p.spaceKey == 'announcements'), isTrue);

      // Verify feeds are not duplicate across spaces
      expect(prayerPosts.first.id, isNot(equals(welcomePosts.first.id)));
      expect(prayerPosts.first.id, isNot(equals(generalPosts.first.id)));
    });

    test('kFellowshipSpaces contains all primary Belong spaces', () {
      expect(kFellowshipSpaces.containsKey('general_chat'), isTrue);
      expect(kFellowshipSpaces.containsKey('start_here'), isTrue);
      expect(kFellowshipSpaces.containsKey('announcements'), isTrue);
      expect(kFellowshipSpaces.containsKey('prayer'), isTrue);
      expect(kFellowshipSpaces.containsKey('saved_for_later'), isTrue);
    });

    test('Creating a post in a specific space is isolated to that space', () async {
      final repo = LocalPostRepository(isDevMode: true);
      final newPost = Post(
        id: 'new_unique_post',
        authorName: 'Test Member',
        spaceKey: 'start_here',
        toneTag: '[Welcome]',
        content: 'Hello everyone!',
        timestamp: DateTime.now(),
        reactions: const {},
      );

      await repo.createPost(newPost);

      final startHerePosts = await repo.getPosts(spaceKey: 'start_here');
      final prayerPosts = await repo.getPosts(spaceKey: 'prayer');

      expect(startHerePosts.any((p) => p.id == 'new_unique_post'), isTrue);
      expect(prayerPosts.any((p) => p.id == 'new_unique_post'), isFalse);
    });
  });
}
