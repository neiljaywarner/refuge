import 'package:flutter/material.dart';
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

/// Simulated in-memory notification seed for development & testing (#328, #329).
final List<BelongNotification> kInitialNotifications = [
  BelongNotification(
    id: 'notif-1',
    type: BelongNotificationType.mention,
    authorName: 'Marty (Organizer)',
    postTitle: 'Markan Chiasms in Chapter 4',
    timestamp: DateTime(2026, 10, 22, 19, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-2',
    type: BelongNotificationType.reply,
    authorName: 'Sarah Chen',
    postTitle: 'Quiet Rooms at Texas Assemblies',
    timestamp: DateTime(2026, 10, 22, 18, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-3',
    type: BelongNotificationType.like,
    authorName: 'Caleb Stone',
    postTitle: 'Sensory Safe Worship Spaces',
    timestamp: DateTime(2026, 10, 22, 16, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-4',
    type: BelongNotificationType.following,
    authorName: 'David Okafor',
    postTitle: 'Fellowship Hall Reflections',
    timestamp: DateTime(2026, 10, 20, 12, 0),
    isRead: true,
  ),
];

/// StateNotifier / Notifier managing the in-app calm notification collection.
class BelongNotificationsNotifier extends Notifier<List<BelongNotification>> {
  BelongNotificationsNotifier({
    this.badgeService,
    this.initialList,
  });

  final AppLauncherBadgeService? badgeService;
  final List<BelongNotification>? initialList;

  @override
  List<BelongNotification> build() {
    if (initialList != null) {
      _syncBadge(initialList!);
      return initialList!;
    }
    final now = DateTime.now();
    final list = [
      kInitialNotifications[0].copyWith(
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      kInitialNotifications[1].copyWith(
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      kInitialNotifications[2].copyWith(
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      kInitialNotifications[3].copyWith(
        timestamp: now.subtract(const Duration(days: 2)),
      ),
    ];
    _syncBadge(list);
    return list;
  }

  void _syncBadge(List<BelongNotification> list) {
    try {
      final unread = list.where((n) => !n.isRead).length;
      final svc = badgeService ?? ref.read(appLauncherBadgeServiceProvider);
      svc?.setBadgeCount(unread);
    } catch (_) {
      // Ignored during disconnected tests or early initialization
    }
  }

  void markAsRead(String notificationId) {
    state = [
      for (final n in state)
        if (n.id == notificationId) n.copyWith(isRead: true) else n,
    ];
    _syncBadge(state);
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        if (!n.isRead) n.copyWith(isRead: true) else n,
    ];
    _syncBadge(state);
  }

  void addNotification(BelongNotification notification) {
    state = [notification, ...state];
    _syncBadge(state);
  }

  void clearAll() {
    state = [];
    _syncBadge(state);
  }
}

/// Main provider for calm notifications.
final belongNotificationsProvider =
    NotifierProvider<BelongNotificationsNotifier, List<BelongNotification>>(
      BelongNotificationsNotifier.new,
    );

/// Active filter chip state provider.
final notificationActiveFilterProvider =
    StateProvider<BelongNotificationFilter>((ref) => BelongNotificationFilter.inbox);

/// Computed provider returning total count of unread notifications.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(belongNotificationsProvider);
  return list.where((n) => !n.isRead).length;
});

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
    BelongNotificationFilter.following => list
        .where((n) =>
            n.type == BelongNotificationType.following ||
            n.type == BelongNotificationType.like)
        .toList(),
  };
});

/// Alias for backward compatibility across navigation bar & views
final unreadNotificationsCountProvider = unreadNotificationCountProvider;
