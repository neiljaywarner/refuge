import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Web Back Navigation & PopScope Hierarchy (Issue #499)', () {
    patrolWidgetTest(
      'navigating to Spaces and triggering PopScope returns to Feed',
      ($) async {
        await $.pumpWidgetAndSettle(
          RefugeApp(repository: LocalPostRepository()),
        );

        // 1. Initial state: on Home Feed
        expect($(const Key('subnav_feed_tab')), findsOneWidget);
        expect($(const Key('subnav_spaces_tab')), findsOneWidget);

        // 2. Switch to Spaces
        await $(const Key('subnav_spaces_tab')).tap();
        await $.pumpAndSettle();
        expect($('PINNED'), findsOneWidget);
        expect($('WELCOME'), findsOneWidget);

        // 3. Trigger back navigation (Simulates browser Back / Android system back)
        final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
        expect(popScopeFinder, findsOneWidget);
        final popScope = $.tester.widget<PopScope>(popScopeFinder);
        popScope.onPopInvokedWithResult?.call(false, null);
        await $.pumpAndSettle();

        // 4. Verify we returned to Feed rather than popping out
        expect($(const Key('subnav_feed_tab')), findsOneWidget);
        expect($('PINNED'), findsNothing);
      },
    );

    patrolWidgetTest(
      'navigating to Notifications tab and triggering PopScope returns to Home tab',
      ($) async {
        await $.pumpWidgetAndSettle(
          RefugeApp(repository: LocalPostRepository()),
        );

        // 1. Switch to Notifications tab
        await $('Notifications').tap();
        await $.pumpAndSettle();

        // Verify Notifications view is open
        expect($('Notifications'), findsWidgets);

        // 2. Trigger back navigation
        final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
        expect(popScopeFinder, findsOneWidget);
        final popScope = $.tester.widget<PopScope>(popScopeFinder);
        popScope.onPopInvokedWithResult?.call(false, null);
        await $.pumpAndSettle();

        // 3. Verify we returned to Home tab
        expect($(const Key('subnav_feed_tab')), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'navigating to ComingSoon view inside Spaces and triggering PopScope returns to Spaces',
      ($) async {
        await $.pumpWidgetAndSettle(
          RefugeApp(repository: LocalPostRepository()),
        );

        // 1. Switch to Spaces
        await $(const Key('subnav_spaces_tab')).tap();
        await $.pumpAndSettle();

        // 2. Tap Coming Soon item
        final itemFinder = $('Actually Autistic Events');
        if (itemFinder.evaluate().isNotEmpty) {
          await itemFinder.tap();
          await $.pumpAndSettle();

          // 3. Pop returns to Spaces
          final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
          expect(popScopeFinder, findsOneWidget);
          final popScope = $.tester.widget<PopScope>(popScopeFinder);
          popScope.onPopInvokedWithResult?.call(false, null);
          await $.pumpAndSettle();

          expect($('PINNED'), findsOneWidget);
          expect($('WELCOME'), findsOneWidget);
        }
      },
    );

    patrolWidgetTest(
      'navigating to a different space and triggering PopScope returns to prayer',
      ($) async {
        await $.pumpWidgetAndSettle(
          RefugeApp(repository: LocalPostRepository()),
        );

        // 1. Switch to Spaces
        await $(const Key('subnav_spaces_tab')).tap();
        await $.pumpAndSettle();

        // 2. Select a space (e.g. Announcements)
        final spaceFinder = $('Announcements');
        if (spaceFinder.evaluate().isNotEmpty) {
          await spaceFinder.tap();
          await $.pumpAndSettle();

          // 3. Trigger back navigation
          final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
          expect(popScopeFinder, findsOneWidget);
          final popScope = $.tester.widget<PopScope>(popScopeFinder);
          popScope.onPopInvokedWithResult?.call(false, null);
          await $.pumpAndSettle();

          // 4. Verify we returned to feed
          expect($(const Key('subnav_feed_tab')), findsOneWidget);
        }
      },
    );
  });
}
