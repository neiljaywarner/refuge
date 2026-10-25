import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/belong_notification.dart';
import '../domain/calm_notification_preferences.dart';
import '../domain/calm_push_payload.dart';
import '../presentation/notifications_controller.dart';
import 'app_launcher_badge_service.dart';
import 'calm_local_notification_service.dart';
import 'fcm_messaging_service.dart';
import 'notification_permissions_service.dart';

/// Service responsible for real-time cloud webhook dispatch, multi-device sync,
/// and silent OS notification shade integration (#530).
class NotificationSyncService {
  NotificationSyncService({
    required this.ref,
    CalmLocalNotificationService? localNotifications,
    AppLauncherBadgeService? badgeService,
  })  : _localNotifications =
            localNotifications ?? ref.read(calmLocalNotificationServiceProvider),
        _badgeService =
            badgeService ?? ref.read(appLauncherBadgeServiceProvider);

  final Ref ref;
  final CalmLocalNotificationService _localNotifications;
  final AppLauncherBadgeService _badgeService;

  final _incomingStreamController =
      StreamController<BelongNotification>.broadcast();

  Stream<BelongNotification> get onNotificationReceived =>
      _incomingStreamController.stream;

  /// Handles an incoming notification from a Serverpod streaming connection,
  /// FCM data payload, or cloud webhook invalidation (#530).
  Future<void> handleIncomingNotification(
    BelongNotification notification, {
    bool postSystemNotification = true,
  }) async {
    // 1. Add to local notifications collection
    final notifier = ref.read(belongNotificationsProvider.notifier);
    notifier.addNotification(notification);

    // 2. Broadcast on stream
    _incomingStreamController.add(notification);

    // 3. Update native launcher badge
    final currentList = ref.read(belongNotificationsProvider);
    final unreadCount = currentList.where((n) => !n.isRead).length;
    await _badgeService.setBadgeCount(unreadCount);

    // 4. If push digests are enabled in member preferences, deliver silent OS notification
    final prefs = ref.read(calmNotificationPreferencesProvider);
    if (prefs.enabled && postSystemNotification) {
      final quiet = prefs.schedule == CalmDigestSchedule.immediateGentle ||
          prefs.schedule == CalmDigestSchedule.muted;
      if (notification.type == BelongNotificationType.directMessage && !quiet) {
        await _localNotifications.showMessageNotification(
          title: 'Belong',
          body: notification.displayMessage,
          payload: notification.id,
        );
      } else {
        await _localNotifications.showSilentNotification(
          title: 'Belong',
          body: notification.displayMessage,
          payload: notification.id,
        );
      }
    }
  }

  bool _alreadyPostedByFcm(Map<String, dynamic> data) {
    return data['type'] == 'direct_message' || data['category'] == 'direct_message';
  }

  /// Parses raw cloud data map and processes it as a BelongNotification.
  Future<void> handleIncomingCloudPayload(Map<String, dynamic> data) async {
    try {
      final notif = BelongNotification.fromJson(data);
      await handleIncomingNotification(
        notif,
        postSystemNotification: !_alreadyPostedByFcm(data),
      );
    } catch (_) {
      // Fallback: extract title and body using calmPushDisplayFromParts
      final display = calmPushDisplayFromParts(data: data);
      final fallbackNotif = BelongNotification(
        id: data['id']?.toString() ??
            'cloud-${DateTime.now().millisecondsSinceEpoch}',
        type: BelongNotificationType.mention,
        authorName: data['authorName']?.toString() ?? 'Fellow Member',
        postTitle: display.title,
        commentSnippet: display.body,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await handleIncomingNotification(
        fallbackNotif,
        postSystemNotification: !_alreadyPostedByFcm(data),
      );
    }
  }

  /// Synchronizes "mark all read" across devices, updating local state and launcher badge.
  Future<void> syncMarkAllAsRead() async {
    final notifier = ref.read(belongNotificationsProvider.notifier);
    notifier.markAllAsRead();
    await _badgeService.clearBadge();
  }

  void dispose() {
    _incomingStreamController.close();
  }
}

/// Provider for [NotificationSyncService].
final notificationSyncServiceProvider =
    Provider<NotificationSyncService>((ref) {
  final service = NotificationSyncService(ref: ref);
  Future<void> forward(Map<String, dynamic> data) {
    return service.handleIncomingCloudPayload(data);
  }

  FcmMessagingService.cloudPayloadHandler = forward;
  ref.onDispose(() {
    if (identical(FcmMessagingService.cloudPayloadHandler, forward)) {
      FcmMessagingService.cloudPayloadHandler = null;
    }
    service.dispose();
  });
  return service;
});
