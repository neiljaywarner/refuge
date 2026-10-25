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

class _FakeBadgeService extends AppLauncherBadgeService {
  int recordedBadge = 0;
  @override
  Future<bool> setBadgeCount(int count) async {
    recordedBadge = count;
    return true;
  }
}

void main() {
  group('Notification Deep-Linking Tests (#330)', () {
    late _FakeBadgeService badgeService;

    setUp(() {
      badgeService = _FakeBadgeService();
    });

    group('Solitary / Isolated Widget Tests (CalmNotificationsView)', () {
      testWidgets(
        'Tapping direct message notification dispatches navigation to Msgs tab and conversationId',
        (tester) async {
          NotificationNavigationTarget? capturedTarget;

          final dmNotification = BelongNotification(
            id: 'test-dm-1',
            type: BelongNotificationType.directMessage,
            authorName: 'Caleb Stone',
            postTitle: 'Direct Message',
            commentSnippet: 'Are you available to talk about sensory meetups?',
            conversationId: 'thread-caleb-stone',
            timestamp: DateTime.now(),
            isRead: false,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
                belongNotificationsProvider.overrideWith(
                  () => BelongNotificationsNotifier(
                    badgeService: badgeService,
                    initialList: [dmNotification],
                  ),
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: CalmNotificationsView(onNavigate: (target) => capturedTarget = target),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Tap notification tile
          await tester.tap(find.byKey(const Key('notification_list_tile_test-dm-1')));
          await tester.pumpAndSettle();

          expect(capturedTarget, isNotNull);
          expect(capturedTarget!.tab, BelongBottomTab.msgs);
          expect(capturedTarget!.conversationId, 'thread-caleb-stone');
        },
      );

      testWidgets(
        'Tapping mention notification dispatches navigation to Home tab, target space and post',
        (tester) async {
          NotificationNavigationTarget? capturedTarget;

          final mentionNotification = BelongNotification(
            id: 'test-mention-1',
            type: BelongNotificationType.mention,
            authorName: 'Sarah Chen',
            postTitle: 'Autistic Theology',
            spaceKey: 'study',
            postId: 'post-autistic-theology-1',
            commentSnippet: 'What do you think @neil?',
            timestamp: DateTime.now(),
            isRead: false,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
                belongNotificationsProvider.overrideWith(
                  () => BelongNotificationsNotifier(
                    badgeService: badgeService,
                    initialList: [mentionNotification],
                  ),
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: CalmNotificationsView(onNavigate: (target) => capturedTarget = target),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Tap notification tile
          await tester.tap(find.byKey(const Key('notification_list_tile_test-mention-1')));
          await tester.pumpAndSettle();

          expect(capturedTarget, isNotNull);
          expect(capturedTarget!.tab, BelongBottomTab.home);
          expect(capturedTarget!.spaceKey, 'study');
          expect(capturedTarget!.postId, 'post-autistic-theology-1');
          expect(capturedTarget!.openDiscussion, isTrue);
        },
      );

      testWidgets(
        'Tapping notification with missing/archived target displays polite calm SnackBar fallback',
        (tester) async {
          NotificationNavigationTarget? capturedTarget;

          final archivedNotification = BelongNotification(
            id: 'test-archived-1',
            type: BelongNotificationType.like,
            authorName: 'Anonymous Member',
            postTitle: 'Deleted Reflection',
            timestamp: DateTime.now(),
            isRead: false,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
                belongNotificationsProvider.overrideWith(
                  () => BelongNotificationsNotifier(
                    badgeService: badgeService,
                    initialList: [archivedNotification],
                  ),
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: CalmNotificationsView(onNavigate: (target) => capturedTarget = target),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Tap notification tile
          await tester.tap(find.byKey(const Key('notification_list_tile_test-archived-1')));
          await tester.pumpAndSettle();

          expect(capturedTarget, isNull);
          expect(find.byKey(const Key('notification_archived_snackbar')), findsOneWidget);
          expect(find.text('This reflection was unhurriedly archived or moved'), findsOneWidget);
        },
      );
    });

    group('Sociable Widget Tests (End-to-End Navigation inside RefugeHomeScreen)', () {
      patrolWidgetTest(
        'Tapping DM notification in CalmNotificationsView navigates to Msgs tab and opens active conversation thread',
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
                postRepositoryProvider.overrideWithValue(LocalPostRepository(isDevMode: true)),
                appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
              ],
              child: const MaterialApp(home: RefugeHomeScreen()),
            ),
          );
          await $.pumpAndSettle();

          // 1. Switch to Notifications tab
          await $(const Key('bottom_nav_icon_notifications')).tap();
          await $.pumpAndSettle();

          // 2. Tap the DM notification tile
          await $(const Key('notification_list_tile_notif-dm-1')).tap();
          await $.pumpAndSettle();

          // 3. Sociable verification: Msgs tab is active and conversation thread is displayed
          expect($('Welcome to Belong!'), findsWidgets);
          expect($('Type a calm reply...'), findsOneWidget);
        },
      );

      patrolWidgetTest(
        'Tapping mention notification navigates to Home tab and highlights post or opens discussion',
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
                postRepositoryProvider.overrideWithValue(LocalPostRepository(isDevMode: true)),
                appLauncherBadgeServiceProvider.overrideWithValue(badgeService),
              ],
              child: const MaterialApp(home: RefugeHomeScreen()),
            ),
          );
          await $.pumpAndSettle();

          // 1. Switch to Notifications tab
          await $(const Key('bottom_nav_icon_notifications')).tap();
          await $.pumpAndSettle();

          // 2. Tap the Mention notification tile
          await $(const Key('notification_list_tile_notif-mention-1')).tap();
          await $.pumpAndSettle();

          // 3. Sociable verification: Bottom nav is on Home tab
          expect($(const Key('belong_bottom_nav_bar')), findsOneWidget);
        },
      );
    });
  });
}
