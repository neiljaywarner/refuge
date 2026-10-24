import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../notifications/domain/belong_notification.dart';
import '../../notifications/presentation/calm_notification_preferences_sheet.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../sensory_themes/domain/sensory_mode.dart';
import '../../sensory_themes/presentation/sensory_theme_controller.dart';

/// Calm Notification Bell view (Issue #286).
/// Presents unhurried, digestible notifications with filter chips (Inbox, Mentions, Threads, Following),
/// author avatars with lower-right action badges, relative timestamps, and a 'Mark all as read' action.
class CalmNotificationsView extends HookConsumerWidget {
  const CalmNotificationsView({
    super.key,
    this.onBackToHome,
  });

  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final currentMode = ref.watch(sensoryThemeModeProvider);
    final isContrast = currentMode == SensoryMode.contrast;

    final activeFilter = ref.watch(notificationActiveFilterProvider);
    final notifications = ref.watch(filteredNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: onBackToHome != null
            ? IconButton(
                key: const Key('notif-back-button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToHome,
              )
            : null,
        actions: [
          // Checkbox in upper right to mark all as read (greyed out if unreadCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  key: const Key('mark_all_read_checkbox'),
                  value: unreadCount == 0,
                  activeColor: isContrast ? Colors.yellow : primary,
                  checkColor: isContrast ? Colors.black : Colors.white,
                  onChanged: unreadCount == 0
                      ? null
                      : (_) => ref
                          .read(belongNotificationsProvider.notifier)
                          .markAllAsRead(),
                ),
                InkWell(
                  key: const Key('mark_all_notifications_as_read_button'),
                  borderRadius: BorderRadius.circular(4),
                  onTap: unreadCount == 0
                      ? null
                      : () => ref
                          .read(belongNotificationsProvider.notifier)
                          .markAllAsRead(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: unreadCount == 0
                            ? (isContrast
                                ? Colors.white38
                                : theme.disabledColor)
                            : (isContrast ? Colors.yellow : primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            identifier: 'notification-preferences-button',
            label: 'Calm Notification Preferences',
            child: IconButton(
              key: const Key('notification-preferences-button'),
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Calm Notification Preferences',
              onPressed: () => CalmNotificationPreferencesSheet.show(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Gentle banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isContrast
                    ? Colors.black
                    : const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isContrast
                      ? Colors.white
                      : const Color(0xFFDCECE4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_paused_outlined,
                    color: isContrast ? Colors.yellow : const Color(0xFF2E6B56),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All notifications are delivered gently without intrusive sound alerts.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isContrast
                            ? Colors.white
                            : const Color(0xFF1E4638),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips Row: Inbox, Mentions, Threads, Following
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: BelongNotificationFilter.values.map((filter) {
                final isSelected = activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    key: Key('filter_chip_${filter.name}'),
                    selected: isSelected,
                    label: Text(filter.label),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isContrast ? Colors.black : Colors.white)
                          : null,
                    ),
                    selectedColor: isContrast ? Colors.yellow : primary,
                    checkmarkColor: isContrast ? Colors.black : Colors.white,
                    onSelected: (_) {
                      ref
                          .read(notificationActiveFilterProvider.notifier)
                          .state = filter;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 12),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No notifications in ${activeFilter.label.toLowerCase()} right now.',
                        key: const Key('empty_notifications_placeholder'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _BelongNotificationCard(
                        item: item,
                        primaryColor: primary,
                        isContrast: isContrast,
                        onTap: () {
                          if (!item.isRead) {
                            ref
                                .read(belongNotificationsProvider.notifier)
                                .markAsRead(item.id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BelongNotificationCard extends StatelessWidget {
  final BelongNotification item;
  final Color primaryColor;
  final bool isContrast;
  final VoidCallback onTap;

  const _BelongNotificationCard({
    required this.item,
    required this.primaryColor,
    required this.isContrast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lower-right badge icon and background color
    final (IconData badgeIcon, Color badgeBgColor, Color badgeIconColor) =
        switch (item.type) {
      BelongNotificationType.like => (
          Icons.favorite,
          const Color(0xFFE91E63),
          Colors.white,
        ),
      BelongNotificationType.reply => (
          Icons.reply_rounded,
          const Color(0xFF2196F3),
          Colors.white,
        ),
      BelongNotificationType.mention => (
          Icons.alternate_email_rounded,
          const Color(0xFF4CAF50),
          Colors.white,
        ),
      BelongNotificationType.directMessage => (
          Icons.chat_bubble_outline_rounded,
          const Color(0xFF009688),
          Colors.white,
        ),
      BelongNotificationType.following => (
          Icons.person_add_rounded,
          const Color(0xFF9C27B0),
          Colors.white,
        ),
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: item.isRead
          ? (isContrast
              ? Colors.black
              : theme.cardColor)
          : (isContrast
              ? const Color(0xFF1A1A00)
              : primaryColor.withValues(alpha: 0.06)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isContrast
              ? (item.isRead ? Colors.white30 : Colors.yellow)
              : (item.isRead
                  ? theme.dividerColor.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.25)),
        ),
      ),
      child: ListTile(
        key: Key('notification_list_tile_${item.id}'),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: isContrast
                  ? Colors.yellow
                  : primaryColor.withValues(alpha: 0.15),
              child: Text(
                item.authorInitials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isContrast ? Colors.black : primaryColor,
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                key: Key('notification_badge_icon_${item.id}'),
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  badgeIcon,
                  size: 10,
                  color: badgeIconColor,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          item.displayMessage,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
            color: isContrast ? Colors.white : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                item.formattedTimeAgo(),
                key: Key('notification_time_ago_${item.id}'),
                style: TextStyle(
                  fontSize: 11,
                  color: isContrast
                      ? Colors.white70
                      : theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                ),
              ),
              if (item.commentSnippet != null) ...[
                const SizedBox(width: 6),
                const Text('·', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.commentSnippet!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isContrast
                          ? Colors.white70
                          : theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: item.isRead
            ? null
            : Container(
                key: Key('notification_unread_dot_${item.id}'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isContrast ? Colors.yellow : primaryColor,
                ),
              ),
      ),
    );
  }
}
