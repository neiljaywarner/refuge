import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/notifications/data/app_launcher_badge_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_stub.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_permissions_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/notification_sync_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';

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
  group('NotificationSyncService Solitary Tests (#530)', () {
    late _FakeBadgeService fakeBadgeService;
    late CalmLocalNotificationStub fakeLocalNotificationService;
    late ProviderContainer container;

    setUp(() {
      fakeBadgeService = _FakeBadgeService();
      fakeLocalNotificationService = CalmLocalNotificationStub();

      container = ProviderContainer(
        overrides: [
          appLauncherBadgeServiceProvider.overrideWithValue(fakeBadgeService),
          calmLocalNotificationServiceProvider.overrideWithValue(fakeLocalNotificationService),
          belongNotificationsProvider.overrideWith(
            () => BelongNotificationsNotifier(
              badgeService: fakeBadgeService,
              initialList: [
                BelongNotification(
                  id: 'initial-1',
                  type: BelongNotificationType.mention,
                  authorName: 'Initial Author',
                  postTitle: 'Initial Reflection',
                  timestamp: DateTime.now(),
                  isRead: false,
                ),
              ],
            ),
          ),
          calmNotificationPreferencesProvider.overrideWith(
            (ref) => NotificationPermissionsService(
              initialPreferences: const CalmNotificationPreferences(enabled: false),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('BelongNotification toJson and fromJson round-trip perfectly', () {
      final original = BelongNotification(
        id: 'roundtrip-1',
        type: BelongNotificationType.directMessage,
        authorName: 'Marty C.',
        postTitle: 'Direct Message',
        commentSnippet: 'Hello from sync test',
        conversationId: 'dm-marty-1',
        timestamp: DateTime(2026, 10, 24, 18, 0),
        isRead: false,
        spaceKey: 'theology',
        postId: 'post-123',
      );

      final json = original.toJson();
      final restored = BelongNotification.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.authorName, original.authorName);
      expect(restored.postTitle, original.postTitle);
      expect(restored.commentSnippet, original.commentSnippet);
      expect(restored.conversationId, original.conversationId);
      expect(restored.spaceKey, original.spaceKey);
      expect(restored.postId, original.postId);
      expect(restored.isRead, original.isRead);
    });

    test('handleIncomingNotification adds to collection and updates launcher badge', () async {
      final syncService = container.read(notificationSyncServiceProvider);

      final newNotification = BelongNotification(
        id: 'incoming-cloud-1',
        type: BelongNotificationType.reply,
        authorName: 'Pastor Thomas',
        postTitle: 'Psalm 23',
        timestamp: DateTime.now(),
        isRead: false,
      );

      await syncService.handleIncomingNotification(newNotification);

      final list = container.read(belongNotificationsProvider);
      expect(list.any((n) => n.id == 'incoming-cloud-1'), isTrue);
      // Initial list had 1 unread + 1 new unread = 2
      expect(fakeBadgeService.recordedBadge, equals(2));
    });

    test('Silent OS notification shade only triggers when push digests enabled', () async {
      final syncService = container.read(notificationSyncServiceProvider);

      final notif = BelongNotification(
        id: 'cloud-test-shade',
        type: BelongNotificationType.mention,
        authorName: 'Elena R.',
        postTitle: 'Quiet Waters',
        timestamp: DateTime.now(),
        isRead: false,
      );

      // 1. When preferences.enabled is false:
      await syncService.handleIncomingNotification(notif);
      expect(fakeLocalNotificationService.showCount, equals(0));

      // 2. When preferences.enabled is true:
      container.read(calmNotificationPreferencesProvider.notifier).state =
          const CalmNotificationPreferences(enabled: true);

      await syncService.handleIncomingNotification(notif);
      expect(fakeLocalNotificationService.showCount, equals(1));
      expect(fakeLocalNotificationService.lastTitle, equals('Belong'));
      expect(fakeLocalNotificationService.lastBody, contains('Elena R. mentioned you'));
    });

    test('handleIncomingCloudPayload parses raw FCM data payload', () async {
      final syncService = container.read(notificationSyncServiceProvider);

      final payload = {
        'id': 'fcm-payload-123',
        'type': 'directMessage',
        'authorName': 'Caleb Stone',
        'postTitle': 'Direct Message',
        'commentSnippet': 'Are you joining the sensory study?',
        'conversationId': 'dm-caleb-1',
      };

      await syncService.handleIncomingCloudPayload(payload);

      final list = container.read(belongNotificationsProvider);
      final found = list.firstWhere((n) => n.id == 'fcm-payload-123');
      expect(found.type, equals(BelongNotificationType.directMessage));
      expect(found.authorName, equals('Caleb Stone'));
      expect(found.conversationId, equals('dm-caleb-1'));
    });

    test('syncMarkAllAsRead marks all read and resets launcher badge to 0', () async {
      final syncService = container.read(notificationSyncServiceProvider);

      // Verify initial unread exists
      expect(container.read(unreadNotificationCountProvider), greaterThan(0));

      await syncService.syncMarkAllAsRead();

      expect(container.read(unreadNotificationCountProvider), equals(0));
      expect(fakeBadgeService.recordedBadge, equals(0));
    });
  });
}
