import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_launcher_badge_service.dart';
import '../domain/belong_notification.dart';

/// Active filter chip for Calm Notifications
enum BelongNotificationFilter {
  inbox,
  mentions,
  threads,
  following;

  String get label => switch (this) {
        BelongNotificationFilter.inbox => 'Inbox',
        BelongNotificationFilter.mentions => 'Mentions',
        BelongNotificationFilter.threads => 'Threads',
        BelongNotificationFilter.following => 'Following',
      };
}

/// Provider for the active filter chip in the Notifications inbox.
final notificationActiveFilterProvider =
    StateProvider<BelongNotificationFilter>(
  (ref) => BelongNotificationFilter.inbox,
);

/// State notifier managing the list of calm notifications.
class BelongNotificationsNotifier
    extends StateNotifier<List<BelongNotification>> {
  final AppLauncherBadgeService? badgeService;

  BelongNotificationsNotifier({
    this.badgeService,
    List<BelongNotification>? initialList,
  }) : super(initialList ?? _seedNotifications()) {
    _syncLauncherBadge();
  }

  static List<BelongNotification> _seedNotifications() {
    final now = DateTime.now();
    return [
      BelongNotification(
        id: 'notif-mention-1',
        authorName: 'John Doe',
        type: BelongNotificationType.mention,
        postTitle: 'Markan Chiasms',
        commentSnippet: 'Thanks @rachel for highlighting Mark 2:27!',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      BelongNotification(
        id: 'notif-reply-1',
        authorName: 'Elena R.',
        type: BelongNotificationType.reply,
        postTitle: 'Prayer & Healing',
        commentSnippet: 'Praying for soothing rest after your errands today.',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: false,
      ),
      BelongNotification(
        id: 'notif-like-1',
        authorName: 'David M.',
        type: BelongNotificationType.like,
        postTitle: 'Sensory Friendly Worship',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: false,
      ),
      BelongNotification(
        id: 'notif-following-1',
        authorName: 'Pastor Thomas',
        type: BelongNotificationType.following,
        postTitle: 'Psalm 23 Meditations',
        commentSnippet: 'Gathering by quiet waters this Wednesday evening.',
        timestamp: DateTime(now.year, 9, 7, 14, 30),
        isRead: true,
      ),
    ];
  }

  /// Marks all notifications as read and clears badges.
  void markAllAsRead() {
    state = [
      for (final n in state)
        if (!n.isRead) n.copyWith(isRead: true) else n,
    ];
    _syncLauncherBadge();
  }

  /// Marks an individual notification as read.
  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    _syncLauncherBadge();
  }

  /// Adds a new notification and increments unread count.
  void addNotification(BelongNotification notification) {
    state = [notification, ...state];
    _syncLauncherBadge();
  }

  void clearAll() {
    state = [];
    _syncLauncherBadge();
  }

  void _syncLauncherBadge() {
    final unread = state.where((n) => !n.isRead).length;
    badgeService?.setBadgeCount(unread);
  }
}

/// Primary provider for notifications list.
final belongNotificationsProvider =
    StateNotifierProvider<
      BelongNotificationsNotifier,
      List<BelongNotification>
    >((ref) {
      final badgeService = ref.watch(appLauncherBadgeServiceProvider);
      return BelongNotificationsNotifier(badgeService: badgeService);
    });

/// Computed provider for unread notifications count.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(belongNotificationsProvider);
  return list.where((n) => !n.isRead).length;
});

/// Alias provider for backwards compatibility with any singular callers.
final unreadNotificationCountProvider = unreadNotificationsCountProvider;

/// Computed provider filtering the notification feed according to active filter chip.
final filteredNotificationsProvider = Provider<List<BelongNotification>>((ref) {
  final list = ref.watch(belongNotificationsProvider);
  final filter = ref.watch(notificationActiveFilterProvider);

  return switch (filter) {
    BelongNotificationFilter.inbox => list,
    BelongNotificationFilter.mentions =>
      list.where((n) => n.type == BelongNotificationType.mention).toList(),
    BelongNotificationFilter.threads =>
      list.where((n) => n.type == BelongNotificationType.reply).toList(),
    BelongNotificationFilter.following =>
      list
          .where(
            (n) =>
                n.type == BelongNotificationType.following ||
                n.type == BelongNotificationType.like,
          )
          .toList(),
  };
});
