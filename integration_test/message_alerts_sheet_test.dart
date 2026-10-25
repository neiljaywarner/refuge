import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';

/// Sheet integration: the in-app switch and the platform settings hint.
///
/// Run with `flutter test integration_test/message_alerts_sheet_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('message alerts sheet names the Android notification settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CalmNotificationsView())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-preferences-button')));
    await tester.pumpAndSettle();

    expect(find.text('Calm Notification Ethics'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('toggle-notifications-switch')),
      findsOneWidget,
    );
    final help = tester.widget<Text>(
      find.byKey(const ValueKey('notification-settings-help')),
    );
    final helpText = help.data ?? '';
    expect(
      helpText.contains('Apps, then Belong, then Notifications') ||
          helpText.contains('Settings, then Notifications, then Belong') ||
          helpText.contains('System Settings, then Notifications, then Belong') ||
          helpText.contains('address bar'),
      isTrue,
    );
    expect(
      find.textContaining('On. A new direct message shows as a notification'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-notifications-switch')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('On. A new direct message shows as a notification'),
      findsOneWidget,
    );
  });
}
