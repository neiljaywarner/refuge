import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_permissions_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/calm_notification_preferences_sheet.dart';

void main() {
  group('CalmNotificationPreferences Domain & Service Tests', () {
    test('default preferences are disabled with twiceDaily schedule', () {
      const prefs = CalmNotificationPreferences();
      expect(prefs.enabled, isFalse);
      expect(prefs.schedule, equals(CalmDigestSchedule.twiceDaily));
      expect(prefs.fcmToken, isNull);
      expect(prefs.isWebPwaInstalled, isFalse);
      expect(prefs.isIosWebWithoutPwa, isFalse);
    });

    test('service updates schedule and generates token on permission', () async {
      final service = NotificationPermissionsService();
      expect(service.state.schedule, equals(CalmDigestSchedule.twiceDaily));

      service.setSchedule(CalmDigestSchedule.morningOnly);
      expect(service.state.schedule, equals(CalmDigestSchedule.morningOnly));

      final granted = await service.setEnabled(true);
      expect(granted, isTrue);
      expect(service.state.enabled, isTrue);
      expect(service.state.fcmToken, isNotNull);

      // Muting disables enabled state
      service.setSchedule(CalmDigestSchedule.muted);
      expect(service.state.schedule, equals(CalmDigestSchedule.muted));
      expect(service.state.enabled, isFalse);
    });

    test('service blocks permission when iOS web is not installed as PWA', () async {
      final service = NotificationPermissionsService(
        overrideIsIosWebWithoutPwa: true,
      );
      expect(service.state.isIosWebWithoutPwa, isTrue);

      final granted = await service.setEnabled(true);
      expect(granted, isFalse);
      expect(service.state.enabled, isFalse);
    });
  });

  group('CalmNotificationPreferencesSheet Widget Tests', () {
    patrolWidgetTest('renders preferences sheet and updates schedule', ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: MaterialApp(
            home: CalmNotificationsView(),
          ),
        ),
      );

      expect($('Calm Notifications'), findsOneWidget);
      expect($(const Key('notification-preferences-button')), findsOneWidget);
      expect($(const Key('open-preferences-card')), findsOneWidget);

      // Open preferences via action button
      await $(const Key('notification-preferences-button')).tap();

      expect($('Calm Notification Ethics'), findsOneWidget);
      expect($(const ValueKey('toggle-notifications-switch')), findsOneWidget);

      // Toggle notifications
      await $(const ValueKey('toggle-notifications-switch')).tap();

      // Switch to Morning Only
      expect($(const ValueKey('schedule-radio-morningOnly')), findsOneWidget);
      await $(const ValueKey('schedule-radio-morningOnly')).tap();

      // Tap Save & Return
      expect($(const ValueKey('save-notification-preferences-button')), findsOneWidget);
      await $(const ValueKey('save-notification-preferences-button')).tap();

      expect($('Calm Notification Ethics'), findsNothing);
    });

    patrolWidgetTest('renders iOS web without PWA warning banner when applicable', ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            calmNotificationPreferencesProvider.overrideWith((ref) {
              return NotificationPermissionsService(
                overrideIsIosWebWithoutPwa: true,
              );
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalmNotificationPreferencesSheet(),
            ),
          ),
        ),
      );

      expect($('Calm Notification Ethics'), findsOneWidget);
      expect(
        $(RegExp('Apple iOS Requirement: Mobile Safari requires adding Belong to your Home Screen')),
        findsOneWidget,
      );
    });
  });
}
