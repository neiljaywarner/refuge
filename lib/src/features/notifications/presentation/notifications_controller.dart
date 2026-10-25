import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../profile/domain/member_profile.dart';
import '../data/app_launcher_badge_service.dart';
import '../data/member_notification_store.dart';
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
    id: 'notif-mention-1',
    type: BelongNotificationType.mention,
    authorName: 'John Doe',
    postTitle: 'Markan Chiasms',
    timestamp: DateTime(2026, 10, 22, 11, 55),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-reply-1',
    type: BelongNotificationType.reply,
    authorName: 'Elena R.',
    postTitle: 'Prayer & Healing',
    timestamp: DateTime(2026, 10, 22, 11, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-like-1',
    type: BelongNotificationType.like,
    authorName: 'David M.',
    postTitle: 'Sensory Friendly Worship',
    timestamp: DateTime(2026, 10, 22, 9, 0),
    isRead: false,
  ),
  BelongNotification(
    id: 'notif-following-1',
    type: BelongNotificationType.following,
    authorName: 'Pastor Thomas',
    postTitle: 'Psalm 23 Meditations',
    timestamp: DateTime(2026, 10, 20, 12, 0),
    isRead: true,
  ),
];

/// StateNotifier / Notifier managing the in-app calm notification collection.
class BelongNotificationsNotifier extends Notifier<List<BelongNotification>> {
  BelongNotificationsNotifier({this.badgeService, this.initialList}) {
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
  List<BelongNotification>? _seeds;
  StreamSubscription<List<BelongNotification>>? _remoteSub;

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

  List<BelongNotification> _seededItems() {
    final now = DateTime.now();
    return _explicitInitialList ??
        initialList ??
        [
          kInitialNotifications[0].copyWith(
            id: 'notif-mention-1',
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          kInitialNotifications[1].copyWith(
            id: 'notif-reply-1',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
          kInitialNotifications[2].copyWith(
            id: 'notif-like-1',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
          kInitialNotifications[3].copyWith(
            id: 'notif-following-1',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ];
  }

  /// Prepends Firestore bell items for the signed-in account.
  ///
  /// Unit tests construct this notifier outside a provider, and widget tests
  /// often inject [initialList]. Both keep the seeded list and skip Firestore.
  void _bindRemoteNotifications() {
    _remoteSub?.cancel();
    _remoteSub = null;
    if (_explicitInitialList != null || initialList != null) return;
    try {
      final profile = ref.watch(memberProfileProvider);
      if (!profile.isSignedIn ||
          profile.userId.isEmpty ||
          profile.userId == 'guest') {
        return;
      }
      if (Firebase.apps.isEmpty) return;
      _remoteSub = ref
          .read(memberNotificationStoreProvider)
          .watchForRecipient(profile.userId)
          .listen((remote) {
            final seeds = _seeds ?? _seededItems();
            state = [...remote, ...seeds];
          }, onError: (_, _) {});
      ref.onDispose(() {
        _remoteSub?.cancel();
      });
    } catch (_) {}
  }

  @override
  List<BelongNotification> build() {
    final items = _seededItems();
    _seeds = items;
    _unitTestState = items;
    _syncBadge(items);
    _bindRemoteNotifications();
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
    StateProvider<BelongNotificationFilter>(
      (ref) => BelongNotificationFilter.inbox,
    );

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
