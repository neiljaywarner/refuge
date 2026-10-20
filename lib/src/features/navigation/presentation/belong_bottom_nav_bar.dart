import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

/// Primary 4-tab Bottom Navigation Bar for **Belong on the Spectrum**
/// (`Home`, `Notifications`, `Msgs`, `Search`) vetted in ADR 0005 (#18).
enum BelongBottomTab {
  home('Home', Icons.home_rounded),
  notifications('Notifications', Icons.notifications_none_rounded),
  msgs('Msgs', Icons.chat_bubble_outline_rounded),
  search('Search', Icons.search_rounded);

  const BelongBottomTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

final activeBottomTabProvider = StateProvider<BelongBottomTab>((ref) => BelongBottomTab.home);

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
    final primary = Theme.of(context).colorScheme.primary;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: isContrast ? Colors.yellow : primary.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SalomonBottomBar(
          key: const Key('belong_bottom_nav_bar'),
          currentIndex: currentTab.index,
          onTap: (index) => onSelectTab(BelongBottomTab.values[index]),
          duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 250),
          selectedItemColor: isContrast ? Colors.yellow : primary,
          unselectedItemColor: isContrast
              ? Colors.white70
              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          items: [
            for (final tab in BelongBottomTab.values)
              SalomonBottomBarItem(
                icon: Icon(tab.icon, key: Key('bottom_nav_icon_${tab.name}')),
                title: Text(tab.label),
              ),
          ],
        ),
      ),
    );
  }
}
