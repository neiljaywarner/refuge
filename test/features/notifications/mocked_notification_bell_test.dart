import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';
import 'package:refuge4serverpod/src/features/notifications/data/app_launcher_badge_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

class _FakeBadge extends AppLauncherBadgeService {
  int recorded = 0;

  @override
  Future<bool> setBadgeCount(int count) async {
    recorded = count;
    return true;
  }
}

void main() {
  BelongNotification like() {
    return BelongNotification(
      id: 'notif-like-1',
      authorName: 'David M.',
      type: BelongNotificationType.like,
      postTitle: 'Sensory Friendly Worship',
      timestamp: DateTime.utc(2026, 10, 22, 15),
    );
  }

  BelongNotification mention() {
    return BelongNotification(
      id: 'notif-mention-1',
      authorName: 'Sarah K.',
      type: BelongNotificationType.mention,
      postTitle: 'Quiet Waters',
      timestamp: DateTime.utc(2026, 10, 22, 16),
    );
  }

  group('Notification bell with an in-memory feed', () {
    patrolWidgetTest(
      'Scenario: tapping the bell and one notification clears only that unread dot',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          ProviderScope(
            overrides: [
              postRepositoryProvider.overrideWithValue(
                LocalPostRepository(isDevMode: true),
              ),
              appLauncherBadgeServiceProvider.overrideWithValue(_FakeBadge()),
              belongNotificationsProvider.overrideWith(
                () => BelongNotificationsNotifier(
                  initialList: [mention(), like()],
                ),
              ),
            ],
            child: const MaterialApp(home: RefugeHomeScreen()),
          ),
        );
        await $.pumpAndSettle();

        expect($(const Key('bottom_nav_notifications_badge')), findsOneWidget);
        await $(const Key('bottom_nav_icon_notifications')).tap();
        await $.pumpAndSettle();

        expect(
          $('Sarah K. mentioned you in a comment on "Quiet Waters"'),
          findsOneWidget,
        );
        await $(const Key('notification_list_tile_notif-mention-1')).tap();
        await $.pumpAndSettle();

        expect(
          $(const Key('notification_unread_dot_notif-mention-1')),
          findsNothing,
        );
        expect(
          $(const Key('notification_unread_dot_notif-like-1')),
          findsOneWidget,
        );
        expect($(const Key('bottom_nav_notifications_badge')), findsOneWidget);
        expect($('1'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Scenario: a filter with no items shows the empty placeholder',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(800, 1400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              belongNotificationsProvider.overrideWith(
                () => BelongNotificationsNotifier(
                  initialList: [like()],
                  badgeService: _FakeBadge(),
                ),
              ),
            ],
            child: const MaterialApp(home: CalmNotificationsView()),
          ),
        );

        await $(const Key('filter_chip_mentions')).tap();
        await $.pumpAndSettle();
        expect($(const Key('empty_notifications_placeholder')), findsOneWidget);
        expect($('No notifications in mentions right now.'), findsOneWidget);
      },
    );
  });
}
