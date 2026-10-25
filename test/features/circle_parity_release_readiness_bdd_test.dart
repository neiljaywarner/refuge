import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

void main() {
  group('Circle.so Parity & Release Readiness BDD Scenarios (Issue #371)', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository(isDevMode: true);
      ProfileStorageService.instance.clear();
    });

    Widget buildHarness() {
      return RefugeApp(repository: repository);
    }

    patrolWidgetTest(
      'Scenario: Exploring Circle spaces, sections, and member directory',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildHarness());
        await $.pumpAndSettle();

        // 1. Given the app is running on the Home screen
        expect($('Belong'), findsWidgets);

        // 2. When I tap the Spaces tab
        await $(const Key('subnav_spaces_tab')).tap();
        await $.pumpAndSettle();

        // 3. Then I see Circle community sections
        expect($('PINNED'), findsOneWidget);
        expect($('General Chat'), findsWidgets);
        expect($('COMMUNITY'), findsOneWidget);
        expect($('Members Section & Directory'), findsOneWidget);

        // 4. When I tap Members Section & Directory
        await $('Members Section & Directory').tap();
        await $.pumpAndSettle();

        // 5. Then I see Member Directory
        expect($('Member Directory'), findsOneWidget);
        expect($('Fellowship disciples & leaders'), findsOneWidget);
        expect($('Marty (Organizer)'), findsOneWidget);

        // 6. Return back to spaces
        await $(const Key('members_directory_back_button')).tap();
        await $.pumpAndSettle();
        expect($('General Chat'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Scenario: Switching between Direct Messages, Notifications, and Search',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildHarness());
        await $.pumpAndSettle();

        // 1. Tap Notifications bottom tab
        await $(const Key('bottom_nav_icon_notifications')).tap();
        await $.pumpAndSettle();
        expect($('Notifications'), findsWidgets);
        expect(
          $(
            'Demo Mode · Showing sample interactions. Sign in to receive personal notifications.',
          ),
          findsOneWidget,
        );

        // 2. Tap Msgs bottom tab
        await $(const Key('bottom_nav_icon_msgs')).tap();
        await $.pumpAndSettle();
        expect($('Direct Messages'), findsOneWidget);

        // 3. Tap Search bottom tab
        await $(const Key('bottom_nav_icon_search')).tap();
        await $.pumpAndSettle();
        expect($('Search'), findsWidgets);

        // 4. Return to Home feed
        await $(const Key('bottom_nav_icon_home')).tap();
        await $.pump(const Duration(milliseconds: 300));
        expect($('Feed'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Scenario: FCM Push Notifications opt-in primer ensures zero startup prompts',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildHarness());
        await $.pumpAndSettle();

        // 1. Verify app launches with zero unexpected dialogs
        expect($('Calm Notification Ethics'), findsNothing);

        // 2. Navigate to Notifications -> Preferences
        await $(const Key('bottom_nav_icon_notifications')).tap();
        await $.pumpAndSettle();
        await $(const Key('notification-preferences-button')).tap();
        await $.pumpAndSettle();

        // 3. User is informed why push notifications exist before granting permission
        expect($('Calm Notification Ethics'), findsOneWidget);
        expect(
          $(
            'Belong respects your attention and sensory peace. We never send loud chimes, urgency countdowns, or anxiety-inducing red dots.',
          ),
          findsOneWidget,
        );

        // 4. Toggle notifications
        await $(const ValueKey('toggle-notifications-switch')).tap();
        await $.pumpAndSettle();

        // 5. Dismiss sheet
        await $(const ValueKey('save-notification-preferences-button')).tap();
        await $.pumpAndSettle();
        expect($('Calm Notification Ethics'), findsNothing);
      },
    );
  });
}
