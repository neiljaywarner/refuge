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

    test(
      'Sorts by "Popular" combining reactions and discussion replies count',
      () {
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
      },
    );

    test(
      'Sorts by "New Activity" based on latest discussion comment timestamp',
      () {
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
      },
    );

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
      final sorted = FeedSortService.sortPosts(
        posts,
        sortOption: FeedSortOption.alphabetical,
      );

      expect(sorted.map((p) => p.id).toList(), ['2', '3', '1']);
    });

    test('Empty feed, a single post, and empty reactions never throw', () {
      for (final option in FeedSortOption.values) {
        expect(
          FeedSortService.sortPosts(const [], sortOption: option),
          isEmpty,
        );
        expect(
          FeedSortService.sortPosts([postEarly], sortOption: option).single.id,
          '1',
        );
      }

      final blank = Post(
        id: 'blank',
        authorName: 'Fellow Member',
        spaceKey: 'prayer',
        toneTag: '[Question]',
        content: '',
        timestamp: DateTime(2026, 1, 1),
        reactions: const {},
      );
      final sorted = FeedSortService.sortPosts(
        [blank, postLate],
        sortOption: FeedSortOption.likes,
        latestActivityByPost: null,
        commentCounts: null,
      );
      expect(sorted.map((p) => p.id), ['3', 'blank']);
    });

    test('Does not mutate the caller list', () {
      final posts = [postLate, postEarly];
      FeedSortService.sortPosts(posts, sortOption: FeedSortOption.oldest);
      expect(posts.map((p) => p.id), ['3', '1']);
    });

    test('New Activity and Popular tolerate null metadata maps', () {
      final posts = [postEarly, postLate];
      expect(
        FeedSortService.sortPosts(
          posts,
          sortOption: FeedSortOption.newActivity,
        ).map((p) => p.id),
        ['3', '1'],
      );
      expect(
        FeedSortService.sortPosts(
          posts,
          sortOption: FeedSortOption.popular,
        ).first.id,
        '1',
      );
    });

    test('For you survives regex metacharacters in interests', () {
      final sorted = FeedSortService.sortPosts(
        [postEarly, postSpecialInterest],
        sortOption: FeedSortOption.forYou,
        userInterests: const {'c++', '(psalm)', 'Acoustics'},
      );
      expect(sorted.first.id, '4');
    });

    test('Timestamp ties break by id', () {
      final tied = Post(
        id: '1b',
        authorName: 'Fellow Member',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Same moment.',
        timestamp: postEarly.timestamp,
        reactions: const {'pray': 1},
      );
      final latest = FeedSortService.sortPosts([
        postEarly,
        tied,
      ], sortOption: FeedSortOption.latest);
      expect(latest.map((p) => p.id), ['1b', '1']);
    });
  });

  group('FeedQuery filter x sort x sign-in (#485)', () {
    late List<Post> posts;

    setUp(() {
      final base = DateTime(2026, 10, 20, 10, 0);
      posts = [
        Post(
          id: 'demo-prayer',
          authorName: 'David M.',
          spaceKey: 'prayer',
          toneTag: '[Prayer Request]',
          content: 'Please pray for peace of mind.',
          timestamp: base,
          reactions: const {'pray': 2},
          isDemo: true,
        ),
        Post(
          id: 'live-comfort',
          authorName: 'Elena R.',
          spaceKey: 'prayer',
          toneTag: '[Comfort Only]',
          content: 'Heavy sensory fatigue after errands.',
          timestamp: base.add(const Duration(hours: 1)),
          reactions: const {'peace': 4},
          isDemo: false,
        ),
        Post(
          id: 'live-question',
          authorName: 'Pastor Thomas',
          spaceKey: 'prayer',
          toneTag: '[Question]',
          content: 'Quiet waters in Psalm 23.',
          timestamp: base.add(const Duration(hours: 2)),
          reactions: const {'pray': 1},
          isDemo: false,
        ),
      ];
    });

    test('Signed-out demo mode keeps sample reflections', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: 'All',
        sort: FeedSortOption.latest,
        signedIn: false,
      );
      expect(visible.map((p) => p.id), [
        'live-question',
        'live-comfort',
        'demo-prayer',
      ]);
    });

    test('Signed-in feed drops demo reflections', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: 'All',
        sort: FeedSortOption.oldest,
        signedIn: true,
      );
      expect(visible.map((p) => p.id), ['live-comfort', 'live-question']);
    });

    test('Every filter and sort combination stays inside the filter', () {
      const filters = [
        'All',
        '[Prayer Request]',
        '[Comfort Only]',
        '[Bible Deep-Dive]',
        '[Question]',
      ];
      for (final signedIn in [false, true]) {
        for (final filter in filters) {
          for (final sort in FeedSortOption.values) {
            final visible = FeedQuery.apply(
              posts: posts,
              toneFilter: filter,
              sort: sort,
              signedIn: signedIn,
              latestActivityByPost: null,
              commentCounts: null,
              userInterests: const {'peace', 'Psalm'},
            );
            expect(visible, isA<List<Post>>());
            if (filter != 'All') {
              expect(visible.every((p) => p.toneTag == filter), isTrue);
            }
            if (signedIn) {
              expect(visible.every((p) => !p.isDemo), isTrue);
            }
          }
        }
      }
    });

    test('Comfort Only keeps Elena and hides the prayer request', () {
      final visible = FeedQuery.apply(
        posts: posts,
        toneFilter: '[Comfort Only]',
        sort: FeedSortOption.alphabetical,
        signedIn: false,
      );
      expect(visible.map((p) => p.id), ['live-comfort']);
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

    test('filters out test junk posts like "blah your face", "test 1", and grokbot (#501)', () {
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
      ];

      final visible = FeedQuery.apply(
        posts: postsWithJunk,
        toneFilter: 'All',
        sort: FeedSortOption.latest,
        signedIn: false,
      );
      expect(visible.any((p) => p.id == 'junk-1'), isFalse);
      expect(visible.any((p) => p.id == 'junk-2'), isFalse);
      expect(visible.any((p) => p.id == 'junk-3'), isFalse);
      expect(visible.length, 3);
    });
  });
}
