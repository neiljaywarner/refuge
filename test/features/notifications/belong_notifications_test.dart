import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/notifications/data/app_launcher_badge_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

class FakeLauncherBadgeService extends AppLauncherBadgeService {
  int recordedBadge = 0;

  @override
  Future<bool> setBadgeCount(int count) async {
    recordedBadge = count;
    return true;
  }
}

void main() {
  group('BelongNotification Domain Unit Tests', () {
    test('authorInitials extracts initials correctly', () {
      final n1 = BelongNotification(
        id: '1',
        authorName: 'John Doe',
        type: BelongNotificationType.mention,
        postTitle: 'Study',
        timestamp: DateTime.now(),
      );
      expect(n1.authorInitials, 'JD');

      final n2 = n1.copyWith(authorName: 'Elena R.');
      expect(n2.authorInitials, 'ER');

      final n3 = n1.copyWith(authorName: 'Pastor Thomas (Melbourne)');
      expect(n3.authorInitials, 'P(');

      final n4 = n1.copyWith(authorName: 'Solitary');
      expect(n4.authorInitials, 'S');
    });

    test('displayMessage formats interaction strings properly', () {
      final now = DateTime.now();
      final mention = BelongNotification(
        id: '1',
        authorName: 'John Doe',
        type: BelongNotificationType.mention,
        postTitle: 'Markan Chiasms',
        timestamp: now,
      );
      expect(
        mention.displayMessage,
        'John Doe mentioned you in a comment on "Markan Chiasms"',
      );

      final reply = mention.copyWith(
        type: BelongNotificationType.reply,
        postTitle: 'Prayer & Healing',
      );
      expect(
        reply.displayMessage,
        'John Doe replied to your comment on "Prayer & Healing"',
      );

      final like = mention.copyWith(
        type: BelongNotificationType.like,
        postTitle: 'Sensory Worship',
      );
      expect(
        like.displayMessage,
        'John Doe liked your reflection on "Sensory Worship"',
      );

      final following = mention.copyWith(
        type: BelongNotificationType.following,
        postTitle: 'Quiet Waters',
      );
      expect(
        following.displayMessage,
        'John Doe posted a new reflection in "Quiet Waters"',
      );
    });

    test('formattedTimeAgo produces friendly relative strings', () {
      final base = DateTime(2026, 10, 22, 12, 0);

      // Just now
      final nJustNow = BelongNotification(
        id: '1',
        authorName: 'Test',
        type: BelongNotificationType.like,
        postTitle: 'Test',
        timestamp: base.subtract(const Duration(seconds: 30)),
      );
      expect(nJustNow.formattedTimeAgo(base), 'Just now');

      // Minutes
      final nMin = nJustNow.copyWith(
        timestamp: base.subtract(const Duration(minutes: 15)),
      );
      expect(nMin.formattedTimeAgo(base), '15 mins ago');

      // Hours
      final nHour = nJustNow.copyWith(
        timestamp: base.subtract(const Duration(hours: 1)),
      );
      expect(nHour.formattedTimeAgo(base), '1 hr ago');

      final nHours = nJustNow.copyWith(
        timestamp: base.subtract(const Duration(hours: 4)),
      );
      expect(nHours.formattedTimeAgo(base), '4 hrs ago');

      // Days
      final nDays = nJustNow.copyWith(
        timestamp: base.subtract(const Duration(days: 2)),
      );
      expect(nDays.formattedTimeAgo(base), '2 days ago');

      // Older date
      final nDate = nJustNow.copyWith(
        timestamp: DateTime(2026, 9, 7, 10, 0),
      );
      expect(nDate.formattedTimeAgo(base), 'Sep 7th');
    });
  });

  group('BelongNotificationsNotifier Unit Tests', () {
    late FakeLauncherBadgeService badgeService;
    late BelongNotificationsNotifier notifier;

    setUp(() {
      badgeService = FakeLauncherBadgeService();
      notifier = BelongNotificationsNotifier(badgeService: badgeService);
    });

    test('Initial unread count is 3 and badge is synchronized', () {
      final unread = notifier.state.where((n) => !n.isRead).length;
      expect(unread, 3);
      expect(badgeService.recordedBadge, 3);
    });

    test('markAllAsRead clears unread items and sets launcher badge to 0', () {
      notifier.markAllAsRead();
      final unread = notifier.state.where((n) => !n.isRead).length;
      expect(unread, 0);
      expect(badgeService.recordedBadge, 0);
    });

    test('markAsRead marks individual item read', () {
      notifier.markAsRead('notif-mention-1');
      final notif = notifier.state.firstWhere((n) => n.id == 'notif-mention-1');
      expect(notif.isRead, isTrue);
      expect(badgeService.recordedBadge, 2);
    });
  });

  group('Calm Notifications BDD Widget Tests', () {
    Widget buildTestHarness({
      Widget? home,
      List<BelongNotification>? initialNotifications,
    }) {
      return ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            LocalPostRepository(isDevMode: true),
          ),
          appLauncherBadgeServiceProvider.overrideWithValue(
            FakeLauncherBadgeService(),
          ),
          if (initialNotifications != null)
            belongNotificationsProvider.overrideWith(
              (ref) => BelongNotificationsNotifier(
                badgeService: ref.read(appLauncherBadgeServiceProvider),
                initialList: initialNotifications,
              ),
            ),
        ],
        child: MaterialApp(
          home: home ?? const RefugeHomeScreen(),
        ),
      );
    }

    patrolWidgetTest(
      'Bottom nav bar shows bell with unread badge counter',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildTestHarness());
        await $.pumpAndSettle();

        // Check badge on Notifications tab
        expect($(const Key('bottom_nav_notifications_badge')), findsOneWidget);
        expect($('3'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Tapping notification bell navigates to Calm Notifications view with filter chips and avatar badges',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildTestHarness());
        await $.pumpAndSettle();

        // Tap notifications tab in bottom nav
        await $(const Key('bottom_nav_icon_notifications')).tap();
        await $.pumpAndSettle();

        // 1. Verify screen title and banner
        expect($('Notifications'), findsWidgets);
        expect(
          $('All notifications are delivered gently without intrusive sound alerts.'),
          findsOneWidget,
        );

        // 2. Verify filter chips are present
        expect($(const Key('filter_chip_inbox')), findsOneWidget);
        expect($(const Key('filter_chip_mentions')), findsOneWidget);
        expect($(const Key('filter_chip_threads')), findsOneWidget);
        expect($(const Key('filter_chip_following')), findsOneWidget);

        // 3. Verify notification item title and author initials
        expect(
          $('John Doe mentioned you in a comment on "Markan Chiasms"'),
          findsOneWidget,
        );
        expect(
          $('Elena R. replied to your comment on "Prayer & Healing"'),
          findsOneWidget,
        );
        expect(
          $('David M. liked your reflection on "Sensory Friendly Worship"'),
          findsOneWidget,
        );
        expect(
          $('Pastor Thomas posted a new reflection in "Psalm 23 Meditations"'),
          findsOneWidget,
        );

        // 4. Test filtering by Mentions
        await $(const Key('filter_chip_mentions')).tap();
        await $.pumpAndSettle();
        expect(
          $('John Doe mentioned you in a comment on "Markan Chiasms"'),
          findsOneWidget,
        );
        expect(
          $('Elena R. replied to your comment on "Prayer & Healing"'),
          findsNothing,
        );

        // 5. Test filtering by Threads
        await $(const Key('filter_chip_threads')).tap();
        await $.pumpAndSettle();
        expect(
          $('Elena R. replied to your comment on "Prayer & Healing"'),
          findsOneWidget,
        );
        expect(
          $('John Doe mentioned you in a comment on "Markan Chiasms"'),
          findsNothing,
        );

        // 6. Test filtering by Following
        await $(const Key('filter_chip_following')).tap();
        await $.pumpAndSettle();
        expect(
          $('Pastor Thomas posted a new reflection in "Psalm 23 Meditations"'),
          findsOneWidget,
        );
        expect(
          $('David M. liked your reflection on "Sensory Friendly Worship"'),
          findsOneWidget,
        );

        // 7. Return to Inbox
        await $(const Key('filter_chip_inbox')).tap();
        await $.pumpAndSettle();
        expect(
          $('John Doe mentioned you in a comment on "Markan Chiasms"'),
          findsOneWidget,
        );

        // 8. Test Mark All as Read button
        expect($(const Key('mark_all_read_checkbox')), findsOneWidget);
        await $(const Key('mark_all_notifications_as_read_button')).tap();
        await $.pumpAndSettle();

        // Unread dots are gone
        expect(
          $(const Key('notification_unread_dot_notif-mention-1')),
          findsNothing,
        );

        // Bottom nav badge counter is cleared
        expect($(const Key('bottom_nav_notifications_badge')), findsNothing);
      },
    );
  });
}
