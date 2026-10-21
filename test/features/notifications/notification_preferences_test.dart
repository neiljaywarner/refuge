import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    testWidgets('renders preferences sheet and updates schedule', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalmNotificationsView(),
          ),
        ),
      );

      expect(find.text('Calm Notifications'), findsOneWidget);
      expect(find.byKey(const Key('notification-preferences-button')), findsOneWidget);
      expect(find.byKey(const Key('open-preferences-card')), findsOneWidget);

      // Open preferences via action button
      await tester.tap(find.byKey(const Key('notification-preferences-button')));
      await tester.pumpAndSettle();

      expect(find.text('Calm Notification Ethics'), findsOneWidget);
      expect(find.byKey(const ValueKey('toggle-notifications-switch')), findsOneWidget);

      // Toggle notifications
      await tester.tap(find.byKey(const ValueKey('toggle-notifications-switch')));
      await tester.pumpAndSettle();

      // Switch to Morning Only
      final morningRadio = find.byKey(const ValueKey('schedule-radio-morningOnly'));
      expect(morningRadio, findsOneWidget);
      await tester.tap(morningRadio);
      await tester.pumpAndSettle();

      // Tap Save & Return
      final saveBtn = find.byKey(const ValueKey('save-notification-preferences-button'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Calm Notification Ethics'), findsNothing);
    });

    testWidgets('renders iOS web without PWA warning banner when applicable', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
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

      expect(find.text('Calm Notification Ethics'), findsOneWidget);
      expect(
        find.textContaining('Apple iOS Requirement: Mobile Safari requires adding Belong to your Home Screen'),
        findsOneWidget,
      );
    });
  });
}
