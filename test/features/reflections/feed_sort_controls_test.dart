import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

void main() {
  group('Feed Multi-Criteria Sorting Controls & Reordering (#325, #671)', () {
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
      'Home screen positions Welcome banner at top and provides compact Filter & Sort popups (#671)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        // Welcome banner sits above the Feed/Spaces subheader and room header
        final bannerY = $.tester.getTopLeft(find.byKey(const Key('organizer_message_banner'))).dy;
        final feedTabY = $.tester.getTopLeft(find.byKey(const Key('subnav_feed_tab'))).dy;
        final roomHeaderY = $.tester.getTopLeft(find.byKey(const Key('space_room_header'))).dy;
        expect(bannerY, lessThan(feedTabY));
        expect(feedTabY, lessThan(roomHeaderY));

        // Verify compact popup buttons exist for space switcher, tone filter, and feed sort
        expect($(Key('space_switcher_popup_button')), findsOneWidget);
        expect($(Key('tone_filter_popup_button')), findsOneWidget);
        expect($(Key('feed_sort_popup_button')), findsOneWidget);

        // Open sort popup menu and verify all 7 sort options exist
        await $(Key('feed_sort_popup_button')).tap();
        await $.pumpAndSettle();
        for (final opt in FeedSortOption.values) {
          expect($(Key('feed_sort_menu_item_${opt.name}')), findsOneWidget);
        }
        await $(Key('feed_sort_menu_item_latest')).tap();
        await $.pumpAndSettle();

        // Default latest ordering: Sarah (newest) -> David -> Hannah (oldest)
        final sarahY = $.tester
            .getTopLeft(find.textContaining('Morning meditation on Psalm 139:14.'))
            .dy;
        final hannahY = $.tester.getTopLeft(find.text('Zebras and peaceful evening rest.')).dy;
        expect(sarahY, lessThan(hannahY));
      },
    );

    patrolWidgetTest('Selecting "Oldest" from sort popup reorders feed earliest first', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
      await $.pumpAndSettle();

      await $(Key('feed_sort_popup_button')).tap();
      await $.pumpAndSettle();
      await $(Key('feed_sort_menu_item_oldest')).tap();
      await $.pumpAndSettle();

      // Under Oldest, Hannah (earliest post) is first above Sarah
      final hannahY = $.tester.getTopLeft(find.text('Zebras and peaceful evening rest.')).dy;
      final sarahY = $.tester
          .getTopLeft(find.textContaining('Morning meditation on Psalm 139:14.'))
          .dy;
      expect(hannahY, lessThan(sarahY));
    });

    patrolWidgetTest(
      'Selecting "Likes" from sort popup reorders feed descending by care affirmations count',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        await $(Key('feed_sort_popup_button')).tap();
        await $.pumpAndSettle();
        await $(Key('feed_sort_menu_item_likes')).tap();
        await $.pumpAndSettle();

        // Under Likes, Hannah (30 likes) appears above David (5 likes)
        final hannahY = $.tester.getTopLeft(find.text('Zebras and peaceful evening rest.')).dy;
        final davidY = $.tester.getTopLeft(find.text('Apples of gold in settings of silver.')).dy;
        expect(hannahY, lessThan(davidY));
      },
    );

    patrolWidgetTest('Selecting "Alphabetical" orders reflections A to Z by content', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
      await $.pumpAndSettle();

      await $(Key('feed_sort_popup_button')).tap();
      await $.pumpAndSettle();
      await $(Key('feed_sort_menu_item_alphabetical')).tap();
      await $.pumpAndSettle();

      // Content starting with 'A' (David's Apples of gold) is top above Sarah ('Morning...')
      final davidY = $.tester.getTopLeft(find.text('Apples of gold in settings of silver.')).dy;
      final sarahY = $.tester
          .getTopLeft(find.textContaining('Morning meditation on Psalm 139:14.'))
          .dy;
      expect(davidY, lessThan(sarahY));
    });

    patrolWidgetTest('Selecting "Popular" from popup menu updates active sort and reorders', (
      $,
    ) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
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

      // Verify reordering under Popular (Hannah 30 likes is above David 5 likes)
      final hannahY = $.tester.getTopLeft(find.text('Zebras and peaceful evening rest.')).dy;
      final davidY = $.tester.getTopLeft(find.text('Apples of gold in settings of silver.')).dy;
      expect(hannahY, lessThan(davidY));
    });
  });
}
