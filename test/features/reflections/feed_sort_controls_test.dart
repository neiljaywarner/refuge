import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

void main() {
  group('Feed Multi-Criteria Sorting Controls & Reordering (#325)', () {
    late LocalPostRepository repo;

    setUp(() {
      final now = DateTime.now();
      repo = LocalPostRepository(
        isDevMode: false,
        initialPosts: [
          Post(
            id: 'post_early_hannah',
            authorName: 'Hannah',
            spaceKey: 'prayer',
            toneTag: '[Comfort Only]',
            content: 'Zebras and peaceful evening rest.',
            timestamp: now.subtract(const Duration(hours: 5)),
            reactions: {'peace': 20, 'pray': 10}, // 30 likes
          ),
          Post(
            id: 'post_mid_david',
            authorName: 'David',
            spaceKey: 'prayer',
            toneTag: '[Prayer Request]',
            content: 'Apples of gold in settings of silver.',
            timestamp: now.subtract(const Duration(hours: 2)),
            reactions: {'pray': 5}, // 5 likes
          ),
          Post(
            id: 'post_late_sarah',
            authorName: 'Sarah',
            spaceKey: 'prayer',
            toneTag: '[Bible Deep-Dive]',
            content: 'Morning meditation on Psalm 139:14.',
            timestamp: now.subtract(const Duration(minutes: 10)),
            reactions: {'pray': 1}, // 1 like
          ),
        ],
      );
    });

    patrolWidgetTest(
      'FeedSortRow renders all 7 sort options and popup menu button',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
        );
        await $.pumpAndSettle();

        // Verify popup button exists
        expect($(Key('feed_sort_popup_button')), findsOneWidget);

        // Verify all 7 chips exist
        for (final opt in FeedSortOption.values) {
          expect($(Key('feed_sort_chip_${opt.name}')), findsOneWidget);
        }

        // Default active sort is "Latest"
        final latestChip = $.tester.widget<ChoiceChip>(
          find.byKey(const Key('feed_sort_chip_latest')),
        );
        expect(latestChip.selected, isTrue);

        // Default latest ordering: Sarah (newest) -> David -> Hannah (oldest)
        final sarahY = $.tester
            .getTopLeft(
              find.textContaining('Morning meditation on Psalm 139:14.'),
            )
            .dy;
        final hannahY = $.tester
            .getTopLeft(find.text('Zebras and peaceful evening rest.'))
            .dy;
        expect(sarahY, lessThan(hannahY));
      },
    );

    patrolWidgetTest(
      'Tapping "Oldest" chip reorders feed with earliest reflection first',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
        );
        await $.pumpAndSettle();

        // Tap Oldest chip
        await $(Key('feed_sort_chip_oldest')).tap();
        await $.pumpAndSettle();

        // Verify Oldest chip is selected
        final oldestChip = $.tester.widget<ChoiceChip>(
          find.byKey(const Key('feed_sort_chip_oldest')),
        );
        expect(oldestChip.selected, isTrue);

        // Under Oldest, Hannah (earliest post) is first above Sarah
        final hannahY = $.tester
            .getTopLeft(find.text('Zebras and peaceful evening rest.'))
            .dy;
        final sarahY = $.tester
            .getTopLeft(
              find.textContaining('Morning meditation on Psalm 139:14.'),
            )
            .dy;
        expect(hannahY, lessThan(sarahY));
      },
    );

    patrolWidgetTest(
      'Tapping "Likes" chip reorders feed descending by care affirmations count',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
        );
        await $.pumpAndSettle();

        // Scroll chip into view before tapping
        await $.tester.ensureVisible(
          find.byKey(const Key('feed_sort_chip_likes')),
        );
        await $.pumpAndSettle();

        // Tap Likes chip
        await $(Key('feed_sort_chip_likes')).tap();
        await $.pumpAndSettle();

        // Verify Likes chip is selected
        final likesChip = $.tester.widget<ChoiceChip>(
          find.byKey(const Key('feed_sort_chip_likes')),
        );
        expect(likesChip.selected, isTrue);

        // Under Likes, Hannah (30 likes) appears above David (5 likes)
        final hannahY = $.tester
            .getTopLeft(find.text('Zebras and peaceful evening rest.'))
            .dy;
        final davidY = $.tester
            .getTopLeft(find.text('Apples of gold in settings of silver.'))
            .dy;
        expect(hannahY, lessThan(davidY));
      },
    );

    patrolWidgetTest(
      'Tapping "Alphabetical" chip orders reflections A to Z by content',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
        );
        await $.pumpAndSettle();

        // Scroll chip into view before tapping
        await $.tester.ensureVisible(
          find.byKey(const Key('feed_sort_chip_alphabetical')),
        );
        await $.pumpAndSettle();

        // Tap Alphabetical chip
        await $(Key('feed_sort_chip_alphabetical')).tap();
        await $.pumpAndSettle();

        // Verify Alphabetical chip is selected
        final alphaChip = $.tester.widget<ChoiceChip>(
          find.byKey(const Key('feed_sort_chip_alphabetical')),
        );
        expect(alphaChip.selected, isTrue);

        // Content starting with 'A' (David's Apples of gold) is top above Sarah ('Morning...')
        final davidY = $.tester
            .getTopLeft(find.text('Apples of gold in settings of silver.'))
            .dy;
        final sarahY = $.tester
            .getTopLeft(
              find.textContaining('Morning meditation on Psalm 139:14.'),
            )
            .dy;
        expect(davidY, lessThan(sarahY));
      },
    );

    patrolWidgetTest(
      'Selecting sort option from popup menu updates active sort and reorders',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()),
        );
        await $.pumpAndSettle();

        // Open popup menu
        await $(Key('feed_sort_popup_button')).tap();
        await $.pumpAndSettle();

        // Verify popup items exist
        expect($(Key('feed_sort_menu_item_popular')), findsOneWidget);
        expect($(Key('feed_sort_menu_item_newActivity')), findsOneWidget);

        // Select Popular
        await $(Key('feed_sort_menu_item_popular')).tap();
        await $.pumpAndSettle();

        // Popular chip is now selected
        final popChip = $.tester.widget<ChoiceChip>(
          find.byKey(const Key('feed_sort_chip_popular')),
        );
        expect(popChip.selected, isTrue);

        // Verify reordering under Popular (Hannah 30 likes is above David 5 likes)
        final hannahY = $.tester
            .getTopLeft(find.text('Zebras and peaceful evening rest.'))
            .dy;
        final davidY = $.tester
            .getTopLeft(find.text('Apples of gold in settings of silver.'))
            .dy;
        expect(hannahY, lessThan(davidY));
      },
    );
  });
}
