import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/presentation/belong_spaces_directory_view.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_permissions_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';

void main() {
  group('Spaces Directory - Muted Notifications Toggle (Issue #267)', () {
    patrolWidgetTest(
      'Hides muted notifications tile when system permission is not denied',
      ($) async {
        await $.pumpWidget(
          ProviderScope(
            overrides: [
              calmNotificationPreferencesProvider.overrideWith(
                (ref) => NotificationPermissionsService(
                  initialPreferences: const CalmNotificationPreferences(
                    isSystemPermissionDenied: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BelongSpacesDirectoryView(
                  selectedSpaceSlug: 'general_chat',
                  onSelectSpaceItem: (_) {},
                ),
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        expect($(const Key('notifications_muted_spaces_tile')), findsNothing);
        expect($('Notifications muted in system settings'), findsNothing);
      },
    );

    patrolWidgetTest(
      'Displays gentle toggle in Spaces directory when Android 13+ permission is denied ("Don\'t allow")',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          ProviderScope(
            overrides: [
              calmNotificationPreferencesProvider.overrideWith(
                (ref) => NotificationPermissionsService(
                  initialPreferences: const CalmNotificationPreferences(
                    isSystemPermissionDenied: true,
                    enabled: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BelongSpacesDirectoryView(
                  selectedSpaceSlug: 'general_chat',
                  onSelectSpaceItem: (_) {},
                ),
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        expect($(const Key('notifications_muted_spaces_tile')), findsOneWidget);
        expect($('Notifications muted in system settings'), findsOneWidget);
        expect(
          $('Tap to adjust calm digest schedules or re-enable later'),
          findsOneWidget,
        );
      },
    );
  });
}
