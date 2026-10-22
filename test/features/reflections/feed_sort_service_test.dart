import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_service.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

void main() {
  group('FeedSortService Pure Domain Sorting Matrix (#325)', () {
    late Post postEarly;
    late Post postMiddle;
    late Post postLate;
    late Post postSpecialInterest;

    setUp(() {
      final base = DateTime(2026, 10, 20, 10, 0);

      postEarly = Post(
        id: '1',
        authorName: 'Hannah',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Zebras and peaceful rest in God.',
        timestamp: base,
        reactions: {'pray': 5, 'peace': 10}, // 15 likes
      );

      postMiddle = Post(
        id: '2',
        authorName: 'David',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Apples of gold in settings of silver.',
        timestamp: base.add(const Duration(hours: 2)),
        reactions: {'pray': 20, 'peace': 5, 'encouraged': 5}, // 30 likes
      );

      postLate = Post(
        id: '3',
        authorName: 'Sarah',
        spaceKey: 'prayer',
        toneTag: '[Bible Deep-Dive]',
        content: 'Morning devotion on Psalm 139.',
        timestamp: base.add(const Duration(hours: 4)),
        reactions: {'pray': 2, 'peace': 1}, // 3 likes
      );

      postSpecialInterest = Post(
        id: '4',
        authorName: 'Alex',
        spaceKey: 'special_interests',
        toneTag: '[Special Interest]',
        specialInterestTag: 'Church Acoustics',
        content: 'Cathedral reverberation models in medieval architecture.',
        timestamp: base.add(const Duration(hours: 1)),
        reactions: {'relatable': 4}, // 4 likes
      );
    });

    test('Sorts by "Latest" chronologically descending (newest first)', () {
      final posts = [postEarly, postLate, postMiddle];
      final sorted = FeedSortService.sortPosts(posts, sortOption: FeedSortOption.latest);

      expect(sorted.map((p) => p.id).toList(), ['3', '2', '1']);
    });

    test('Sorts by "Oldest" chronologically ascending (earliest first)', () {
      final posts = [postLate, postEarly, postMiddle];
      final sorted = FeedSortService.sortPosts(posts, sortOption: FeedSortOption.oldest);

      expect(sorted.map((p) => p.id).toList(), ['1', '2', '3']);
    });

    test('Sorts by "Likes" descending by total qualitative care reaction affirmations', () {
      // postMiddle: 30 likes, postEarly: 15 likes, postLate: 3 likes
      final posts = [postLate, postEarly, postMiddle];
      final sorted = FeedSortService.sortPosts(posts, sortOption: FeedSortOption.likes);

      expect(sorted.map((p) => p.id).toList(), ['2', '1', '3']);
    });

    test('Sorts by "Popular" combining reactions and discussion replies count', () {
      // postEarly: 15 likes + (10 comments * 2) = 35 score
      // postMiddle: 30 likes + (1 comment * 2) = 32 score
      // postLate: 3 likes + (0 comments) = 3 score
      final posts = [postMiddle, postLate, postEarly];
      final commentCounts = {'1': 10, '2': 1, '3': 0};

      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.popular,
        commentCounts: commentCounts,
      );

      expect(sorted.map((p) => p.id).toList(), ['1', '2', '3']);
    });

    test('Sorts by "New Activity" based on latest discussion comment timestamp', () {
      final now = DateTime.now();
      // postEarly is oldest creation, but received a reply 5 minutes ago!
      final latestActivity = {
        '1': now.subtract(const Duration(minutes: 5)),
        '2': now.subtract(const Duration(hours: 1)),
        '3': now.subtract(const Duration(hours: 2)),
      };

      final posts = [postLate, postMiddle, postEarly];
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.newActivity,
        latestActivityByPost: latestActivity,
      );

      expect(sorted.map((p) => p.id).toList(), ['1', '2', '3']);
    });

    test('Sorts by "For you" prioritizing matching member special interests & bio affinities', () {
      final posts = [postEarly, postMiddle, postLate, postSpecialInterest];
      final userInterests = {'Acoustics', 'Audio'};

      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.forYou,
        userInterests: userInterests,
      );

      // postSpecialInterest matches 'Acoustics' so it must be first
      expect(sorted.first.id, '4');
    });

    test('Sorts by "Alphabetical" case-insensitively ascending (A to Z)', () {
      // 'Apples...' (post 2) -> 'Morning...' (post 3) -> 'Zebras...' (post 1)
      final posts = [postEarly, postLate, postMiddle];
      final sorted = FeedSortService.sortPosts(posts, sortOption: FeedSortOption.alphabetical);

      expect(sorted.map((p) => p.id).toList(), ['2', '3', '1']);
    });
  });
}
