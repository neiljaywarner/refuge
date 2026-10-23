import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    timestamp: DateTime(2026, 10, 22, 12, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-2',
    type: BelongNotificationType.reply,
    authorName: 'Sarah Chen',
    postTitle: 'Quiet Rooms at Texas Assemblies',
    timestamp: DateTime(2026, 10, 22, 10, 30),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-3',
    type: BelongNotificationType.like,
    authorName: 'Caleb Stone',
    postTitle: 'Sensory Safe Worship Spaces',
    timestamp: DateTime(2026, 10, 21, 15, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-4',
    type: BelongNotificationType.following,
    authorName: 'David Okafor',
    postTitle: 'Fellowship Hall Reflections',
    timestamp: DateTime(2026, 10, 20, 9, 0),
    isRead: true,
  ),
];

/// StateNotifier / Notifier managing the in-app calm notification collection.
class BelongNotificationsNotifier extends Notifier<List<BelongNotification>> {
  @override
  List<BelongNotification> build() {
    final now = DateTime.now();
    return [
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
  }

  void markAsRead(String notificationId) {
    state = [
      for (final n in state)
        if (n.id == notificationId) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        if (!n.isRead) n.copyWith(isRead: true) else n,
    ];
  }

  void addNotification(BelongNotification notification) {
    state = [notification, ...state];
  }

  void clearAll() {
    state = [];
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

/// Alias for computed provider returning total count of unread notifications.
final unreadNotificationsCountProvider = unreadNotificationCountProvider;

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