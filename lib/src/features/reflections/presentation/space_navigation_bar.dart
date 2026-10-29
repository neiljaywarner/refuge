import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../domain/feed_sort_option.dart';
import 'feed_sort_row.dart';
import 'reflections_providers.dart';
import 'tone_filter_row.dart';

/// Compact single-line room navigation & filter/sort header bar (#618, #671).
///
/// Consolidates the space switcher, tone filter, and feed sort controls into
/// low-clutter popup menu affordances so community reflections sit higher in
/// the viewport without three stacked horizontal chip strips.
class SpaceNavigationBar extends ConsumerWidget {
  final String selectedSpace;
  final ValueChanged<String> onSelectSpace;
  final VoidCallback? onBackToSpaces;
  final String activeFilter;
  final ValueChanged<String>? onSelectFilter;
  final FeedSortOption activeSort;
  final ValueChanged<FeedSortOption>? onSelectSort;
  final bool? isContrast;

  const SpaceNavigationBar({
    super.key,
    required this.selectedSpace,
    required this.onSelectSpace,
    this.onBackToSpaces,
    this.activeFilter = 'All',
    this.onSelectFilter,
    this.activeSort = FeedSortOption.latest,
    this.onSelectSort,
    this.isContrast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final effectiveContrast =
        isContrast ??
        (theme.scaffoldBackgroundColor == Colors.black &&
            theme.colorScheme.primary == const Color(0xFFFFEB3B));

    final spaceInfo = getBelongSpaceInfo(selectedSpace);
    final hasFilterAndSort = onSelectFilter != null || onSelectSort != null;
    final isFiltered = activeFilter != 'All';
    final shortFilterLabel = isFiltered
        ? activeFilter.replaceAll('[', '').replaceAll(']', '')
        : 'All';

    return Container(
      key: const Key('space_room_header'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: effectiveContrast ? Colors.white24 : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final showBreadcrumbs = !hasFilterAndSort || isWide;
          final showSortPrefix = constraints.maxWidth >= 620;
          final maxFilterLabelWidth = isWide ? 88.0 : 56.0;
          final maxSortLabelWidth = isWide ? 96.0 : 68.0;

          return Row(
            children: [
              if (onBackToSpaces != null && showBreadcrumbs) ...[
                Semantics(
                  button: true,
                  label: 'Back to Spaces directory',
                  child: InkWell(
                    key: const Key('space_breadcrumb_back_button'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: onBackToSpaces,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 12,
                            color: effectiveContrast ? Colors.yellow : primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Spaces',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: effectiveContrast ? Colors.yellow : primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontSize: 12,
                      color: effectiveContrast ? Colors.white54 : theme.disabledColor,
                    ),
                  ),
                ),
              ],

              // Space switcher popup menu triggered by tapping the room title
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    identifier: 'space_switcher_popup_button',
                    button: true,
                    label: 'Switch fellowship space (${spaceInfo.title})',
                    child: PopupMenuButton<String>(
                      key: const Key('space_switcher_popup_button'),
                      tooltip: 'Switch fellowship space',
                      offset: const Offset(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: effectiveContrast ? Colors.white : theme.dividerColor,
                        ),
                      ),
                      initialValue: selectedSpace,
                      onSelected: (spaceKey) {
                        selectFeedSortAfterFrame(context, () {
                          ref.read(activeSpaceKeyProvider.notifier).state = spaceKey;
                          onSelectSpace(spaceKey);
                        });
                      },
                      itemBuilder: (context) => kFellowshipSpaces.entries.map((entry) {
                        final isSelected = selectedSpace == entry.key;
                        return PopupMenuItem<String>(
                          key: Key('space_chip_${entry.key}'),
                          value: entry.key,
                          child: Semantics(
                            identifier: 'space_chip_${entry.key}',
                            button: true,
                            selected: isSelected,
                            label: entry.value,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? (effectiveContrast ? Colors.yellow : primary)
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: effectiveContrast ? Colors.yellow : primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(spaceInfo.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                spaceInfo.title,
                                key: const Key('space_room_title'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: effectiveContrast ? Colors.yellow : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: effectiveContrast
                                  ? Colors.yellow
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tone Filter popup button (#671)
              if (onSelectFilter != null) ...[
                const SizedBox(width: 6),
                Semantics(
                  identifier: 'tone_filter_popup_button',
                  button: true,
                  label: 'Filter by tone ($activeFilter)',
                  child: PopupMenuButton<String>(
                    key: const Key('tone_filter_popup_button'),
                    tooltip: 'Filter reflections by tone',
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: effectiveContrast ? Colors.white : theme.dividerColor,
                      ),
                    ),
                    initialValue: activeFilter,
                    onSelected: (filter) {
                      selectFeedSortAfterFrame(context, () {
                        ref.read(activeFilterProvider.notifier).state = filter;
                        onSelectFilter!(filter);
                      });
                    },
                    itemBuilder: (context) => kToneFilters.map((f) {
                      final isSelected = activeFilter == f;
                      final semanticsId = toneFilterSemanticsId(f);
                      return PopupMenuItem<String>(
                        key: Key(semanticsId),
                        value: f,
                        child: Semantics(
                          identifier: semanticsId,
                          button: true,
                          selected: isSelected,
                          label: f,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? (effectiveContrast ? Colors.yellow : primary)
                                        : null,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: effectiveContrast ? Colors.yellow : primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    child: _CompactPopupPill(
                      icon: Icons.filter_list_rounded,
                      prefix: showSortPrefix ? 'Filter: ' : null,
                      label: shortFilterLabel,
                      isHighlighted: isFiltered,
                      isContrast: effectiveContrast,
                      primary: primary,
                      maxLabelWidth: maxFilterLabelWidth,
                    ),
                  ),
                ),
              ],

              // Feed Sort popup button (#671)
              if (onSelectSort != null) ...[
                const SizedBox(width: 6),
                Semantics(
                  identifier: 'feed_sort_popup_button',
                  button: true,
                  label: 'Sort feed (${activeSort.label})',
                  child: PopupMenuButton<FeedSortOption>(
                    key: const Key('feed_sort_popup_button'),
                    tooltip: 'Sort feed by...',
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: effectiveContrast ? Colors.white : theme.dividerColor,
                      ),
                    ),
                    initialValue: activeSort,
                    onSelected: (opt) =>
                        selectFeedSortAfterFrame(context, () => onSelectSort!(opt)),
                    itemBuilder: (context) => FeedSortOption.values.map((opt) {
                      final isSelected = opt == activeSort;
                      return PopupMenuItem<FeedSortOption>(
                        key: Key('feed_sort_menu_item_${opt.name}'),
                        value: opt,
                        child: Semantics(
                          identifier: 'feed_sort_menu_item_${opt.name}',
                          button: true,
                          selected: isSelected,
                          label: opt.label,
                          child: SizedBox(
                            width: 240,
                            child: Row(
                              children: [
                                Text(opt.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        opt.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? (effectiveContrast ? Colors.yellow : primary)
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        opt.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: theme.brightness == Brightness.dark
                                              ? const Color(0xFFB0BEC5)
                                              : theme.textTheme.bodySmall?.color?.withValues(
                                                  alpha: 0.7,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: effectiveContrast ? Colors.yellow : primary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    child: _CompactPopupPill(
                      icon: Icons.sort_rounded,
                      prefix: showSortPrefix ? 'Sort: ' : null,
                      label: '${activeSort.emoji} ${activeSort.label}',
                      isHighlighted: activeSort != FeedSortOption.latest,
                      isContrast: effectiveContrast,
                      primary: primary,
                      maxLabelWidth: maxSortLabelWidth,
                    ),
                  ),
                ),
              ],

              if (onBackToSpaces != null && showBreadcrumbs) ...[
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'View all spaces',
                  child: InkWell(
                    key: const Key('space_breadcrumb_all_spaces_button'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: onBackToSpaces,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 14,
                            color: effectiveContrast
                                ? Colors.white70
                                : theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All Spaces',
                            style: TextStyle(
                              fontSize: 11,
                              color: effectiveContrast
                                  ? Colors.white70
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompactPopupPill extends StatelessWidget {
  const _CompactPopupPill({
    required this.icon,
    this.prefix,
    required this.label,
    required this.isHighlighted,
    required this.isContrast,
    required this.primary,
    required this.maxLabelWidth,
  });

  final IconData icon;
  final String? prefix;
  final String label;
  final bool isHighlighted;
  final bool isContrast;
  final Color primary;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isContrast
        ? Colors.black
        : (isHighlighted
              ? primary.withValues(alpha: isDark ? 0.22 : 0.14)
              : (isDark ? const Color(0xFF26332A) : primary.withValues(alpha: 0.08)));

    final borderColor = isContrast
        ? (isHighlighted ? Colors.yellow : Colors.white)
        : (isHighlighted
              ? primary
              : (isDark ? const Color(0xFF4A6B53) : primary.withValues(alpha: 0.22)));

    final fgColor = isContrast
        ? (isHighlighted ? Colors.yellow : Colors.white)
        : (isHighlighted
              ? primary
              : (isDark ? const Color(0xFFE2E8F0) : theme.textTheme.bodyMedium?.color));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isHighlighted ? 1.2 : 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isContrast ? Colors.yellow : primary),
          const SizedBox(width: 3),
          if (prefix != null)
            Text(
              prefix!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isContrast ? Colors.yellow : primary,
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: fgColor,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded, size: 14, color: fgColor),
        ],
      ),
    );
  }
}
