import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';

void main() {
  group('BelongBottomNavBar - Persistent Legible Labels (Issue #362)', () {
    patrolWidgetTest(
      'renders all 4 navigation labels simultaneously without collapsing',
      ($) async {
        BelongBottomTab selectedTab = BelongBottomTab.home;

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2E6B56),
                ),
              ),
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: selectedTab,
                  isContrast: false,
                  onSelectTab: (tab) => selectedTab = tab,
                ),
              ),
            ),
          ),
        );

        // Verify container
        expect($(const Key('belong_bottom_nav_bar')), findsOneWidget);

        // Verify all 4 text labels are visible at the same time
        expect($('Home'), findsOneWidget);
        expect($('Notifications'), findsOneWidget);
        expect($('Messages'), findsOneWidget);
        expect($('Search'), findsOneWidget);

        // Verify all 4 icons are present
        expect($(Icons.home_rounded), findsOneWidget);
        expect($(Icons.notifications_none_rounded), findsOneWidget);
        expect($(Icons.chat_bubble_outline_rounded), findsOneWidget);
        expect($(Icons.search_rounded), findsOneWidget);

        // Tap Messages tab
        await $('Messages').tap();
        expect(selectedTab, equals(BelongBottomTab.msgs));

        // Tap Search tab
        await $('Search').tap();
        expect(selectedTab, equals(BelongBottomTab.search));
      },
    );

    patrolWidgetTest(
      'renders high contrast mode with yellow highlights and bold labels',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: BelongBottomTab.notifications,
                  isContrast: true,
                  onSelectTab: (_) {},
                ),
              ),
            ),
          ),
        );

        // Verify all 4 labels are present in high-contrast mode
        expect($('Home'), findsOneWidget);
        expect($('Notifications'), findsOneWidget);
        expect($('Messages'), findsOneWidget);
        expect($('Search'), findsOneWidget);

        // Active tab is Notifications
        expect($(const Key('bottom_nav_label_notifications')), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'renders unread count badge on Notifications tab when count > 0',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              unreadNotificationsCountProvider.overrideWith((ref) => 5),
            ],
            child: MaterialApp(
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: BelongBottomTab.home,
                  isContrast: false,
                  onSelectTab: (_) {},
                ),
              ),
            ),
          ),
        );

        // Verify unread badge is rendered with count 5
        expect($(const Key('bottom_nav_notifications_badge')), findsOneWidget);
        expect($('5'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'does not overflow on narrow compact mobile screens (320px width)',
      ($) async {
        await $.tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => $.tester.binding.setSurfaceSize(null));

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              unreadNotificationsCountProvider.overrideWith((ref) => 12),
            ],
            child: MaterialApp(
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: BelongBottomTab.msgs,
                  isContrast: false,
                  onSelectTab: (_) {},
                ),
              ),
            ),
          ),
        );

        // Verify all 4 tab titles and badge remain visible without RenderFlex overflow
        expect($('Home'), findsOneWidget);
        expect($('Notifications'), findsOneWidget);
        expect($('Messages'), findsOneWidget);
        expect($('Search'), findsOneWidget);
        expect($(const Key('bottom_nav_notifications_badge')), findsOneWidget);
      },
    );
  });
}
