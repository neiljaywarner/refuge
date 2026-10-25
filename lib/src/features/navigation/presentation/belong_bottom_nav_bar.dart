import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../profile/domain/member_profile.dart';

/// Primary 4-tab Bottom Navigation Bar for **Belong on the Spectrum**
/// (`Home`, `Notifications`, `Messages`, `Search`) vetted in ADR 0005 (#18, #362).
enum BelongBottomTab {
  home('Home', Icons.home_rounded),
  notifications('Notifications', Icons.notifications_none_rounded),
  msgs('Messages', Icons.chat_bubble_outline_rounded),
  search('Search', Icons.search_rounded);

  const BelongBottomTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

final activeBottomTabProvider = StateProvider<BelongBottomTab>(
  (ref) => BelongBottomTab.home,
);

class BelongBottomNavBar extends HookConsumerWidget {
  const BelongBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.isContrast,
  });

  final BelongBottomTab currentTab;
  final ValueChanged<BelongBottomTab> onSelectTab;
  final bool isContrast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final profile = ref.watch(currentUserProfileProvider);
    final unreadNotificationsCount = profile.isSignedIn
        ? ref.watch(unreadNotificationsCountProvider)
        : 0;

    final backgroundColor = isContrast
        ? Colors.black
        : theme.scaffoldBackgroundColor;
    final topBorderColor = isContrast
        ? Colors.yellow
        : primary.withValues(alpha: 0.18);
    final bottomInset = SystemInsets.navigationBar(MediaQuery.of(context));

    return DecoratedBox(
      key: const Key('belong_bottom_nav_bar'),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: topBorderColor, width: isContrast ? 2.0 : 1.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final tab in BelongBottomTab.values)
                Expanded(
                  child: _BottomNavItem(
                    tab: tab,
                    isSelected: tab == currentTab,
                    isContrast: isContrast,
                    primaryColor: primary,
                    unreadCount: tab == BelongBottomTab.notifications
                        ? unreadNotificationsCount
                        : 0,
                    disableAnimations: disableAnimations,
                    onTap: () => onSelectTab(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.isSelected,
    required this.isContrast,
    required this.primaryColor,
    required this.unreadCount,
    required this.disableAnimations,
    required this.onTap,
  });

  final BelongBottomTab tab;
  final bool isSelected;
  final bool isContrast;
  final Color primaryColor;
  final int unreadCount;
  final bool disableAnimations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animationDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);

    // Active & inactive color schemes adhering to WCAG AAA
    final Color activeColor = isContrast ? Colors.yellow : primaryColor;
    final Color inactiveColor = isContrast
        ? Colors.white
        : (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
              Colors.grey.shade600);

    final Color currentColor = isSelected ? activeColor : inactiveColor;

    final BoxDecoration pillDecoration = isSelected
        ? BoxDecoration(
            color: isContrast
                ? Colors.black
                : primaryColor.withValues(alpha: 0.14),
            border: isContrast
                ? Border.all(color: Colors.yellow, width: 2)
                : null,
            borderRadius: BorderRadius.circular(16),
          )
        : const BoxDecoration(color: Colors.transparent);

    final Widget iconWidget =
        (tab == BelongBottomTab.notifications && unreadCount > 0)
        ? Badge.count(
            key: const Key('bottom_nav_notifications_badge'),
            count: unreadCount,
            backgroundColor: isContrast ? Colors.yellow : primaryColor,
            textColor: isContrast ? Colors.black : Colors.white,
            child: Icon(
              tab.icon,
              key: Key('bottom_nav_icon_${tab.name}'),
              color: currentColor,
              size: 22,
            ),
          )
        : Icon(
            tab.icon,
            key: Key('bottom_nav_icon_${tab.name}'),
            color: currentColor,
            size: 22,
          );

    return Semantics(
      button: true,
      identifier: 'bottom_nav_tab_${tab.name}',
      selected: isSelected,
      label: '${tab.label} tab${isSelected ? ", active" : ""}',
      child: Tooltip(
        message: tab.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('bottom_nav_tab_${tab.name}'),
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: animationDuration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: pillDecoration,
                    child: iconWidget,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tab.label,
                      key: Key('bottom_nav_label_${tab.name}'),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: currentColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
