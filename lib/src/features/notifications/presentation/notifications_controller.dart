import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/app_launcher_badge_service.dart';
import '../domain/belong_notification.dart';

/// Active filter chip for Calm Notifications
enum BelongNotificationFilter {
  inbox,
  mentions,
  directMessages,
  threads,
  following;

  String get label => switch (this) {
        BelongNotificationFilter.inbox => 'Inbox',
        BelongNotificationFilter.mentions => 'Mentions',
        BelongNotificationFilter.directMessages => 'Direct Messages',
        BelongNotificationFilter.threads => 'Threads',
        BelongNotificationFilter.following => 'Following',
      };
}

/// Simulated in-memory notification seed for development & testing (#328, #329, #442).
final List<BelongNotification> kInitialNotifications = [
  BelongNotification(
    id: 'notif-mention-1',
    type: BelongNotificationType.mention,
    authorName: 'John Doe',
    postTitle: 'Markan Chiasms',
    timestamp: DateTime(2026, 10, 22, 11, 55),
    isRead: false,
    spaceKey: 'theology',
    postId: 'post-markan-chiasms',
  ),
  BelongNotification(
    id: 'notif-dm-1',
    type: BelongNotificationType.directMessage,
    authorName: 'Marty',
    postTitle: 'Direct Message',
    commentSnippet:
        'Welcome to Belong! Let me know if you need any sensory adjustments.',
    timestamp: DateTime(2026, 10, 22, 11, 30),
    isRead: false,
    conversationId: 'thread-marty',
  ),
  BelongNotification(
    id: 'notif-reply-1',
    type: BelongNotificationType.reply,
    authorName: 'Elena R.',
    postTitle: 'Prayer & Healing',
    timestamp: DateTime(2026, 10, 22, 11, 0),
    isRead: false,
    spaceKey: 'prayer',
    postId: 'post-prayer-healing',
  ),
  BelongNotification(
    id: 'notif-like-1',
    type: BelongNotificationType.like,
    authorName: 'David M.',
    postTitle: 'Sensory Friendly Worship',
    timestamp: DateTime(2026, 10, 22, 9, 0),
    isRead: false,
    spaceKey: 'fellowship',
    postId: 'post-sensory-worship',
  ),
  BelongNotification(
    id: 'notif-following-1',
    type: BelongNotificationType.following,
    authorName: 'Pastor Thomas',
    postTitle: 'Psalm 23 Meditations',
    timestamp: DateTime(2026, 10, 20, 12, 0),
    isRead: true,
    spaceKey: 'meditations',
    postId: 'post-psalm-23',
  ),
];

/// StateNotifier / Notifier managing the in-app calm notification collection.
class BelongNotificationsNotifier extends Notifier<List<BelongNotification>> {
  BelongNotificationsNotifier({
    this.badgeService,
    this.initialList,
  }) {
    if (badgeService != null) {
      _explicitBadgeService = badgeService;
    }
    if (initialList != null) {
      _explicitInitialList = initialList;
    }
  }

  final AppLauncherBadgeService? badgeService;
  final List<BelongNotification>? initialList;

  AppLauncherBadgeService? _explicitBadgeService;
  List<BelongNotification>? _explicitInitialList;
  List<BelongNotification>? _unitTestState;

  @override
  List<BelongNotification> get state {
    try {
      return super.state;
    } catch (_) {
      return _unitTestState ?? build();
    }
  }

  @override
  set state(List<BelongNotification> value) {
    _unitTestState = value;
    try {
      super.state = value;
    } catch (_) {}
    _syncBadge(value);
  }

  void _syncBadge(List<BelongNotification> list) {
    final unread = list.where((n) => !n.isRead).length;
    AppLauncherBadgeService? badge = _explicitBadgeService;
    if (badge == null) {
      try {
        badge = ref.read(appLauncherBadgeServiceProvider);
      } catch (_) {}
    }
    badge?.setBadgeCount(unread);
  }

  @override
  List<BelongNotification> build() {
    final now = DateTime.now();
    final items = _explicitInitialList ??
        initialList ??
        [
          kInitialNotifications[0].copyWith(
            id: 'notif-mention-1',
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          kInitialNotifications[1].copyWith(
            id: 'notif-dm-1',
            timestamp: now.subtract(const Duration(minutes: 30)),
          ),
          kInitialNotifications[2].copyWith(
            id: 'notif-reply-1',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
          kInitialNotifications[3].copyWith(
            id: 'notif-like-1',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
          kInitialNotifications[4].copyWith(
            id: 'notif-following-1',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ];
    _unitTestState = items;
    _syncBadge(items);
    return items;
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

  void addMentionNotification({
    required String authorName,
    required String postTitle,
    required String postId,
    required String spaceKey,
    String? commentSnippet,
  }) {
    addNotification(
      BelongNotification(
        id: 'mention-${DateTime.now().millisecondsSinceEpoch}',
        type: BelongNotificationType.mention,
        authorName: authorName,
        postTitle: postTitle,
        postId: postId,
        spaceKey: spaceKey,
        commentSnippet: commentSnippet,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void addDirectMessageNotification({
    required String senderName,
    required String conversationId,
    required String snippet,
  }) {
    addNotification(
      BelongNotification(
        id: 'dm-${DateTime.now().millisecondsSinceEpoch}',
        type: BelongNotificationType.directMessage,
        authorName: senderName,
        postTitle: 'Direct Message',
        commentSnippet: snippet,
        conversationId: conversationId,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void removeNotification(String notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
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

/// Alias provider for backwards compatibility (#356, #328).
final unreadNotificationsCountProvider = unreadNotificationCountProvider;

/// Computed provider filtering the notification feed according to active filter chip.
final filteredNotificationsProvider = Provider<List<BelongNotification>>((ref) {
  final list = ref.watch(belongNotificationsProvider);
  final filter = ref.watch(notificationActiveFilterProvider);

  return switch (filter) {
    BelongNotificationFilter.inbox => list,
    BelongNotificationFilter.mentions =>
      list.where((n) => n.type == BelongNotificationType.mention).toList(),
    BelongNotificationFilter.directMessages =>
      list.where((n) => n.type == BelongNotificationType.directMessage).toList(),
    BelongNotificationFilter.threads =>
      list.where((n) => n.type == BelongNotificationType.reply).toList(),
    BelongNotificationFilter.following => list
        .where((n) =>
            n.type == BelongNotificationType.following ||
            n.type == BelongNotificationType.like)
        .toList(),
  };
});
