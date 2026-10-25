import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/notifications/data/app_launcher_badge_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_stub.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_sync_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

class _FakeBadgeService extends AppLauncherBadgeService {
  int recordedBadge = -1;

  @override
  int get currentBadgeCount => recordedBadge;

  @override
  Future<bool> setBadgeCount(int count) async {
    recordedBadge = count;
    return true;
  }

  @override
  Future<bool> clearBadge() => setBadgeCount(0);
}

void main() {
  group('Notification Phase 2 Sociable Integration Tests (#530)', () {
    late _FakeBadgeService badgeService;
    late CalmLocalNotificationStub localNotificationService;

    setUp(() {
      badgeService = _FakeBadgeService();
      localNotificationService = CalmLocalNotificationStub();
    });

    patrolWidgetTest(
      'Sociable: Incoming cloud notification updates bottom bell badge and tapping mark all read clears state',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        late WidgetRef capturedRef;

        await $.pumpWidget(
          ProviderScope(
            overrides: [
              postRepositoryProvider.overrideWithValue(
                LocalPostRepository(isDevMode: true),
              ),
              appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
              calmLocalNotificationServiceProvider.overrideWithValue(
                localNotificationService,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const MaterialApp(home: RefugeHomeScreen());
              },
            ),
          ),
        );
        await $.pumpAndSettle();

        // 1. Home screen is loaded
        expect($(const Key('belong_bottom_nav_bar')), findsOneWidget);

        // 2. Dispatch a simulated real-time cloud webhook notification
        final syncService = capturedRef.read(notificationSyncServiceProvider);
        await syncService.handleIncomingNotification(
          BelongNotification(
            id: 'realtime-mention-999',
            type: BelongNotificationType.mention,
            authorName: 'Dr. Temple',
            postTitle: 'Sensory Architecture',
            timestamp: DateTime.now(),
            isRead: false,
            spaceKey: 'study',
          ),
        );
        await $.pumpAndSettle();

        // 3. Switch to notifications tab via bottom navigation bell
        await $(const Key('bottom_nav_icon_notifications')).tap();
        await $.pumpAndSettle();

        // 4. Assert incoming cloud notification is visible in CalmNotificationsView
        expect(
          $('Dr. Temple mentioned you in a comment on "Sensory Architecture"'),
          findsOneWidget,
        );

        // 5. Tap "Mark all read" button
        await $(const Key('mark_all_notifications_as_read_button')).tap();
        await $.pumpAndSettle();

        // 6. Assert unread count is cleared to 0 and launcher badge service synchronized to 0
        expect(capturedRef.read(unreadNotificationCountProvider), equals(0));
        expect(badgeService.recordedBadge, equals(0));
      },
    );
  });
}
