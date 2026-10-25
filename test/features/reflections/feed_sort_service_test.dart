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
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.latest,
      );

      expect(sorted.map((p) => p.id).toList(), ['3', '2', '1']);
    });

    test('Sorts by "Oldest" chronologically ascending (earliest first)', () {
      final posts = [postLate, postEarly, postMiddle];
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.oldest,
      );

      expect(sorted.map((p) => p.id).toList(), ['1', '2', '3']);
    });

    test('Sorts by "Likes" descending by total qualitative care reaction affirmations', () {
      // postMiddle: 30 likes, postEarly: 15 likes, postLate: 3 likes
      final posts = [postLate, postEarly, postMiddle];
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.likes,
      );

      expect(sorted.map((p) => p.id).toList(), ['2', '1', '3']);
    });

    test('Sorts by "Popular" combining reactions and comments weight', () {
      // postLate has 10 comments (score = 3 + 20 = 23)
      // postMiddle has 0 comments (score = 30 + 0 = 30)
      // postEarly has 2 comments (score = 15 + 4 = 19)
      final posts = [postEarly, postLate, postMiddle];
      final commentCounts = {
        '1': 2,
        '3': 10,
      };

      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.popular,
        commentCounts: commentCounts,
      );

      expect(sorted.map((p) => p.id).toList(), ['2', '3', '1']);
    });

    test('Sorts by "New Activity" based on latest thread reply timestamp', () {
      final base = DateTime(2026, 10, 20, 10, 0);
      final posts = [postLate, postMiddle, postEarly];

      // postEarly (oldest post) received a comment most recently!
      final latestActivity = {
        '1': base.add(const Duration(hours: 10)),
        '2': base.add(const Duration(hours: 3)),
        '3': base.add(const Duration(hours: 4)),
      };

      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.newActivity,
        latestActivityByPost: latestActivity,
      );

      expect(sorted.map((p) => p.id).toList(), ['1', '3', '2']);
    });

    test('Sorts by "Alphabetical" case-insensitively by reflection content', () {
      final posts = [postLate, postEarly, postMiddle];
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.alphabetical,
      );

      // 'Apples...' (2) -> 'Morning...' (3) -> 'Zebras...' (1)
      expect(sorted.map((p) => p.id).toList(), ['2', '3', '1']);
    });

    test('Sorts by "For You" matching member special interests and care score', () {
      final posts = [postEarly, postLate, postSpecialInterest];

      // User has special interest in acoustics
      final userInterests = {'Acoustics', 'Cathedral'};

      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.forYou,
        userInterests: userInterests,
      );

      // postSpecialInterest matches interest tag -> priority 1
      expect(sorted.first.id, '4');
    });

    test('Falls back gracefully without throwing when metadata maps are empty/null', () {
      final posts = [postLate, postEarly, postMiddle];

      expect(
        () => FeedSortService.sortPosts(
          posts,
          sortOption: FeedSortOption.newActivity,
          latestActivityByPost: null,
        ),
        returnsNormally,
      );

      expect(
        () => FeedSortService.sortPosts(
          posts,
          sortOption: FeedSortOption.popular,
          commentCounts: null,
        ),
        returnsNormally,
      );

      expect(
        () => FeedSortService.sortPosts(
          posts,
          sortOption: FeedSortOption.forYou,
          userInterests: null,
        ),
        returnsNormally,
      );
    });

    test('Deterministic tie-breaking preserves consistent ordering', () {
      final identical1 = Post(
        id: 'A',
        authorName: 'Alex',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Same content',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final identical2 = Post(
        id: 'B',
        authorName: 'Blake',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Same content',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final sorted = FeedSortService.sortPosts(
        [identical1, identical2],
        sortOption: FeedSortOption.latest,
      );

      expect(sorted.map((p) => p.id).toList(), ['B', 'A']);
    });
  });

  group('FeedSortService — Edge cases & comparator safety', () {
    test('Empty list returns empty without error', () {
      for (final option in FeedSortOption.values) {
        expect(FeedSortService.sortPosts([], sortOption: option), isEmpty);
      }
    });

    test('Single-item list returns identical element without error', () {
      final single = [
        Post(
          id: '1',
          authorName: 'Test',
          spaceKey: 'prayer',
          toneTag: '[Comfort Only]',
          content: 'Only post',
          timestamp: DateTime(2026, 10, 20),
          reactions: const {},
        ),
      ];

      for (final option in FeedSortOption.values) {
        final sorted = FeedSortService.sortPosts(single, sortOption: option);
        expect(sorted.length, 1);
        expect(sorted.first.id, '1');
      }
    });

    test('Sorts with zero reactions default cleanly', () {
      final postA = Post(
        id: 'A',
        authorName: 'A',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Post A',
        timestamp: DateTime(2026, 10, 20, 1),
        reactions: const {},
      );

      final postB = Post(
        id: 'B',
        authorName: 'B',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Post B',
        timestamp: DateTime(2026, 10, 20, 2),
        reactions: const {},
      );

      final sortedLikes = FeedSortService.sortPosts(
        [postA, postB],
        sortOption: FeedSortOption.likes,
      );
      expect(sortedLikes.map((p) => p.id).toList(), ['B', 'A']); // tiebreak by timestamp desc

      final sortedPopular = FeedSortService.sortPosts(
        [postA, postB],
        sortOption: FeedSortOption.popular,
      );
      expect(sortedPopular.map((p) => p.id).toList(), ['B', 'A']);
    });

    test('Sorts Alphabetical with special characters and leading whitespace', () {
      final postSpecial = Post(
        id: '1',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: '  #hashtag post',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final postNormal = Post(
        id: '2',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'A regular post',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final sorted = FeedSortService.sortPosts(
        [postNormal, postSpecial],
        sortOption: FeedSortOption.alphabetical,
      );
      expect(sorted.map((p) => p.id).toList(), ['1', '2']);
    });
  });

  group('FeedSortService — For You matching details', () {
    test('Short keywords (< 4 chars) are ignored to prevent noisy false positives', () {
      final post = Post(
        id: '1',
        authorName: 'User',
        spaceKey: 'study',
        toneTag: '[Bible Deep-Dive]',
        content: 'Reading the word of God',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final postOther = Post(
        id: '2',
        authorName: 'User',
        spaceKey: 'study',
        toneTag: '[Bible Deep-Dive]',
        content: 'Other content',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {'pray': 5},
      );

      final sorted = FeedSortService.sortPosts(
        [post, postOther],
        sortOption: FeedSortOption.forYou,
        userInterests: {'the', 'in', 'of'}, // all < 4 chars
      );

      // Should fall through to affinity score: postOther has 5 pray reactions -> ranked first
      expect(sorted.first.id, '2');
    });

    test('Matches toneTag when matching interest keyword', () {
      final post = Post(
        id: '1',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Looking for fellowship',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final postOther = Post(
        id: '2',
        authorName: 'User',
        spaceKey: 'general_chat',
        toneTag: '[General]',
        content: 'Looking for fellowship',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      final sorted = FeedSortService.sortPosts(
        [postOther, post],
        sortOption: FeedSortOption.forYou,
        userInterests: {'Prayer'}, // matches toneTag
      );

      expect(sorted.first.id, '1');
    });

    test('Handles malformed regex chars in interest keyword without crashing', () {
      final post = Post(
        id: '1',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Some content',
        timestamp: DateTime(2026, 10, 20),
        reactions: const {},
      );

      expect(
        () => FeedSortService.sortPosts(
          [post],
          sortOption: FeedSortOption.forYou,
          userInterests: {'[unclosed', '(parens*', 'C++'},
        ),
        returnsNormally,
      );
    });

    test('New Activity with partial map sorts unlisted posts by timestamp', () {
      final base = DateTime(2026, 10, 20, 10, 0);

      final postWithActivity = Post(
        id: '1',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Has activity',
        timestamp: base,
        reactions: const {},
      );

      final postNoActivity = Post(
        id: '2',
        authorName: 'User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'No activity map entry, but created later',
        timestamp: base.add(const Duration(hours: 5)),
        reactions: const {},
      );

      final sorted = FeedSortService.sortPosts(
        [postWithActivity, postNoActivity],
        sortOption: FeedSortOption.newActivity,
        latestActivityByPost: {'1': base.add(const Duration(hours: 1))},
      );

      // postNoActivity timestamp is +5h, postWithActivity is +1h -> postNoActivity first
      expect(sorted.first.id, '2');
    });
  });

  group('FeedQuery helper', () {
    final posts = [
      Post(
        id: 'demo-1',
        authorName: 'Demo User',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Demo reflection',
        timestamp: DateTime(2026, 10, 20, 10),
        reactions: const {},
        isDemo: true,
      ),
      Post(
        id: 'real-1',
        authorName: 'Real User',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Real prayer need',
        timestamp: DateTime(2026, 10, 20, 11),
        reactions: const {},
        isDemo: false,
      ),
      Post(
        id: 'real-2',
        authorName: 'Real User 2',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Another comfort note',
        timestamp: DateTime(2026, 10, 20, 12),
        reactions: const {},
        isDemo: false,
      ),
    ];

    test('guest (signedIn: false) sees demo and real reflections', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: 'All',
        sort: FeedSortOption.latest,
        signedIn: false,
      );
      expect(visible.map((p) => p.id).toSet(), {'demo-1', 'real-1', 'real-2'});
    });

    test('signed-in member sees only non-demo reflections', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: 'All',
        sort: FeedSortOption.latest,
        signedIn: true,
      );
      expect(visible.map((p) => p.id).toSet(), {'real-1', 'real-2'});
      expect(visible.any((p) => p.isDemo), isFalse);
    });

    test('applies tone filter correctly', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: '[Prayer Request]',
        sort: FeedSortOption.latest,
        signedIn: true,
      );
      expect(visible.map((p) => p.id).toList(), ['real-1']);
    });

    test('interestsFrom keeps badges and splits bio and tagline', () {
      final interests = FeedQuery.interestsFrom(
        comfortBadges: const ['Literal communication appreciated'],
        bio: 'Exploring Belong on the Spectrum',
        tagline: 'quiet, waters',
      );
      expect(interests, contains('Exploring'));
      expect(interests, contains('quiet'));
      expect(interests, contains('waters'));
      expect(interests, contains('Literal communication appreciated'));
    });

    test('filters out test junk posts like "blah your face", "test 1", and grokbot (#501, #611)', () {
      final postsWithJunk = [
        ...posts,
        Post(
          id: 'junk-1',
          authorName: 'Random Tester',
          spaceKey: 'prayer',
          toneTag: '[Comfort Only]',
          content: 'blah your face this is a test',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-2',
          authorName: 'grokbot1',
          spaceKey: 'prayer',
          toneTag: '[Comfort Only]',
          content: 'Quiet hello grokbot-mention-token @grokbot2',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-3',
          authorName: 'Tester',
          spaceKey: 'prayer',
          toneTag: '[Comfort Only]',
          content: 'test 1 check microphone',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-4',
          authorName: 'Developer',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: 'quick test for dev backend',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-5',
          authorName: 'Tester',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: 'test 2 check sound',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-6',
          authorName: 'Tester',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: 'asdf asdf asdf',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'junk-7',
          authorName: 'Tester',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: '   ',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
      ];

      final visible = FeedQuery.apply(
        posts: postsWithJunk,
        toneFilter: 'All',
        sort: FeedSortOption.latest,
        signedIn: false,
      );
      expect(visible.any((p) => p.id.startsWith('junk-')), isFalse);
      expect(visible.length, 3);
    });

    test('isTestJunk correctly identifies all developer clutter variants (#611)', () {
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: 'blah your face', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: 'test 345', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: 'quick test', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: 'lorem ipsum dolor sit amet', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: 'cursor test fixture', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'grokbot', spaceKey: 's', toneTag: 't', content: 'hello', timestamp: DateTime.now(), reactions: const {})), isTrue);
      expect(FeedQuery.isTestJunk(Post(id: 'j', authorName: 'A', spaceKey: 's', toneTag: 't', content: '  ', timestamp: DateTime.now(), reactions: const {})), isTrue);

      // Authentic posts are never flagged
      expect(FeedQuery.isTestJunk(Post(id: 'c', authorName: 'Hannah', spaceKey: 'general_chat', toneTag: '[Fellowship]', content: 'Praying for everyone to have a calm evening in God.', timestamp: DateTime.now(), reactions: const {})), isFalse);
    });
  });
}
