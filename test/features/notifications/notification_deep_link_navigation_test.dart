import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/notification_navigation_target.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

void main() {
  group('Notification Deep-Link Navigation Tests (#330)', () {
    testWidgets('CalmNotificationsView dispatches onNavigate on notification tap',
        (tester) async {
      NotificationNavigationTarget? receivedTarget;

      final testNotification = BelongNotification(
        id: 'notif-deep-1',
        type: BelongNotificationType.reply,
        authorName: 'Sarah K.',
        postTitle: 'Quiet Waters',
        timestamp: DateTime.now(),
        spaceKey: 'prayer',
        postId: 'post-prayer-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            belongNotificationsProvider.overrideWith(
              (ref) => BelongNotificationsNotifier([testNotification]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalmNotificationsView(
                onNavigate: (target) {
                  receivedTarget = target;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sarah K. replied to "Quiet Waters"'), findsOneWidget);

      await tester.tap(find.text('Sarah K. replied to "Quiet Waters"'));
      await tester.pumpAndSettle();

      expect(receivedTarget, isNotNull);
      expect(receivedTarget!.tab, equals(BelongBottomTab.home));
      expect(receivedTarget!.spaceKey, equals('prayer'));
      expect(receivedTarget!.postId, equals('post-prayer-1'));
      expect(receivedTarget!.openDiscussion, isTrue);
    });

    testWidgets('Direct message notification navigates to msgs tab',
        (tester) async {
      NotificationNavigationTarget? receivedTarget;

      final dmNotification = BelongNotification(
        id: 'notif-dm-1',
        type: BelongNotificationType.directMessage,
        authorName: 'David M.',
        postTitle: 'Hello friend',
        timestamp: DateTime.now(),
        conversationId: 'dm-david-1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            belongNotificationsProvider.overrideWith(
              (ref) => BelongNotificationsNotifier([dmNotification]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalmNotificationsView(
                onNavigate: (target) {
                  receivedTarget = target;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(receivedTarget, isNotNull);
      expect(receivedTarget!.tab, equals(BelongBottomTab.msgs));
      expect(receivedTarget!.conversationId, equals('dm-david-1'));
    });

    testWidgets('Notification without target shows polite archived snackbar',
        (tester) async {
      final archivedNotification = BelongNotification(
        id: 'notif-archived-1',
        type: BelongNotificationType.following,
        authorName: 'Grace H.',
        postTitle: 'Follow notice',
        timestamp: DateTime.now(),
        // No spaceKey and no postId
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            belongNotificationsProvider.overrideWith(
              (ref) => BelongNotificationsNotifier([archivedNotification]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalmNotificationsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(
        find.text('This reflection was unhurriedly archived or moved'),
        findsOneWidget,
      );
    });
  });
}
