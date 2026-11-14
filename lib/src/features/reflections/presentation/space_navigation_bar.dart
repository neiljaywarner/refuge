import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_theme.dart';
import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../domain/feed_sort_option.dart';
import 'feed_sort_row.dart';
import 'reflections_providers.dart';
import 'tone_filter_row.dart';

/// Room navigation and filter/sort header (#618, #671, #484).
///
/// Wide layouts keep the space, filter, and sort on one line. Phone widths
/// give the room title its own line and let filter and sort labels use their
/// natural width, so names like "Prayer Request" stay readable in Monastic Dark.
class SpaceNavigationBar extends ConsumerWidget {
  final String selectedSpace;
  final ValueChanged<String> onSelectSpace;
  final VoidCallback? onBackToSpaces;
  final String activeFilter;
  final ValueChanged<String>? onSelectFilter;
  final FeedSortOption activeSort;
  final ValueChanged<FeedSortOption>? onSelectSort;
  final bool? isContrast;

  /// When set, the room, filter, and sort controls are at least this tall.
  /// Large-text drawers pass 48 so the targets stay tappable (#951).
  final double? minControlHeight;

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
    this.minControlHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final effectiveContrast = _resolveContrast(theme);
    final spaceInfo = getBelongSpaceInfo(selectedSpace);
    final hasFilterAndSort = onSelectFilter != null || onSelectSort != null;

    return Container(
      key: const Key('space_room_header'),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: effectiveContrast
                ? Colors.white24
                : (theme.brightness == Brightness.dark
                      ? theme.dividerColor
                      : theme.dividerColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this width the room title, filter, and sort cannot share one
          // line without clipping names like "Prayer Request" (#484).
          final phoneChrome = hasFilterAndSort && constraints.maxWidth < 960;
          final showBreadcrumbs = onBackToSpaces != null && !phoneChrome;
          final showPrefix = !phoneChrome;
          final maxFilterLabelWidth = phoneChrome ? 280.0 : 200.0;
          final maxSortLabelWidth = phoneChrome ? 280.0 : 180.0;

          final title = _spaceSwitcher(
            context: context,
            ref: ref,
            theme: theme,
            primary: primary,
            effectiveContrast: effectiveContrast,
            spaceInfo: spaceInfo,
            minControlHeight: minControlHeight,
          );
          final filter = _filterControl(
            context: context,
            ref: ref,
            theme: theme,
            primary: primary,
            effectiveContrast: effectiveContrast,
            showPrefix: showPrefix,
            maxLabelWidth: maxFilterLabelWidth,
            minControlHeight: minControlHeight,
          );
          final sort = _sortControl(
            context: context,
            ref: ref,
            theme: theme,
            primary: primary,
            effectiveContrast: effectiveContrast,
            showPrefix: showPrefix,
            maxLabelWidth: maxSortLabelWidth,
            minControlHeight: minControlHeight,
          );
          final prayerReentry = selectedSpace != 'prayer'
              ? _returnToPrayerSanctuaryButton(context, ref, theme, primary, effectiveContrast)
              : null;

          if (phoneChrome) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    if (prayerReentry != null) ...[const SizedBox(width: 6), prayerReentry],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [?filter, ?sort],
                ),
              ],
            );
          }

          return Row(
            children: [
              if (showBreadcrumbs) ...[
                _backBreadcrumb(effectiveContrast, primary),
                _slash(theme, effectiveContrast),
              ],
              Expanded(child: title),
              if (prayerReentry != null) ...[const SizedBox(width: 6), prayerReentry],
              if (filter != null) ...[const SizedBox(width: 6), filter],
              if (sort != null) ...[const SizedBox(width: 6), sort],
              if (showBreadcrumbs) ...[
                const SizedBox(width: 4),
                _allSpacesButton(theme, effectiveContrast),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _resolveContrast(ThemeData theme) =>
      isContrast ??
      (theme.scaffoldBackgroundColor == Colors.black &&
          theme.colorScheme.primary == const Color(0xFFFFEB3B));

  Widget _backBreadcrumb(bool effectiveContrast, Color primary) => Semantics(
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
  );

  Widget _slash(ThemeData theme, bool effectiveContrast) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '/',
      style: TextStyle(
        fontSize: 12,
        color: effectiveContrast ? Colors.white54 : theme.disabledColor,
      ),
    ),
  );

  Widget _allSpacesButton(ThemeData theme, bool effectiveContrast) => Semantics(
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
              color: effectiveContrast ? Colors.white70 : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              'All Spaces',
              style: TextStyle(
                fontSize: 11,
                color: effectiveContrast ? Colors.white70 : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _returnToPrayerSanctuaryButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
    bool effectiveContrast,
  ) => Semantics(
    button: true,
    label: 'Return to Prayer Sanctuary',
    child: InkWell(
      key: const Key('return_to_prayer_sanctuary_button'),
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        selectFeedSortAfterFrame(context, () {
          ref.read(activeSpaceKeyProvider.notifier).state = 'prayer';
          onSelectSpace('prayer');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: effectiveContrast
              ? Colors.yellow.withValues(alpha: 0.2)
              : primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: effectiveContrast ? Colors.yellow : primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🙏', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              'Prayer Sanctuary',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: effectiveContrast ? Colors.yellow : primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _spaceSwitcher({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required Color primary,
    required bool effectiveContrast,
    required BelongSpaceInfo spaceInfo,
    double? minControlHeight,
  }) => Align(
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
          side: BorderSide(color: effectiveContrast ? Colors.white : theme.dividerColor),
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
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? (effectiveContrast ? Colors.yellow : primary) : null,
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
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: minControlHeight == null ? 3 : 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spaceInfo.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  spaceInfo.title,
                  key: const Key('space_room_title'),
                  style: TextStyle(
                    fontSize: 14,
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
                    : (theme.brightness == Brightness.dark
                          ? MonasticChrome.label
                          : theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget? _filterControl({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required Color primary,
    required bool effectiveContrast,
    required bool showPrefix,
    required double maxLabelWidth,
    double? minControlHeight,
  }) {
    if (onSelectFilter == null) return null;
    final isFiltered = activeFilter != 'All';
    final shortFilterLabel = isFiltered
        ? activeFilter.replaceAll('[', '').replaceAll(']', '')
        : 'All';
    return Semantics(
      identifier: 'tone_filter_popup_button',
      button: true,
      label: 'Filter by tone ($activeFilter)',
      child: PopupMenuButton<String>(
        key: const Key('tone_filter_popup_button'),
        tooltip: 'Filter reflections by tone',
        offset: const Offset(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: effectiveContrast ? Colors.white : theme.dividerColor),
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
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? (effectiveContrast ? Colors.yellow : primary) : null,
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
          prefix: showPrefix ? 'Filter: ' : null,
          label: shortFilterLabel,
          labelKey: const Key('tone_filter_active_label'),
          isHighlighted: isFiltered,
          isContrast: effectiveContrast,
          primary: primary,
          maxLabelWidth: maxLabelWidth,
          minHeight: minControlHeight,
        ),
      ),
    );
  }

  Widget? _sortControl({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required Color primary,
    required bool effectiveContrast,
    required bool showPrefix,
    required double maxLabelWidth,
    double? minControlHeight,
  }) {
    if (onSelectSort == null) return null;
    return Semantics(
      identifier: 'feed_sort_popup_button',
      button: true,
      label: 'Sort feed (${activeSort.label})',
      child: PopupMenuButton<FeedSortOption>(
        key: const Key('feed_sort_popup_button'),
        tooltip: 'Sort feed by...',
        offset: const Offset(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: effectiveContrast ? Colors.white : theme.dividerColor),
        ),
        initialValue: activeSort,
        onSelected: (opt) => selectFeedSortAfterFrame(context, () => onSelectSort!(opt)),
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
                    Text(opt.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                              fontSize: 12,
                              color: theme.brightness == Brightness.dark
                                  ? MonasticChrome.label
                                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
          prefix: showPrefix ? 'Sort: ' : null,
          label: '${activeSort.emoji} ${activeSort.label}',
          labelKey: const Key('feed_sort_active_label'),
          isHighlighted: activeSort != FeedSortOption.latest,
          isContrast: effectiveContrast,
          primary: primary,
          maxLabelWidth: maxLabelWidth,
          minHeight: minControlHeight,
        ),
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
    this.minHeight,
    this.labelKey,
  });

  final IconData icon;
  final String? prefix;
  final String label;
  final bool isHighlighted;
  final bool isContrast;
  final Color primary;
  final double maxLabelWidth;
  final double? minHeight;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monastic = !isContrast && theme.brightness == Brightness.dark;

    final bgColor = isContrast
        ? Colors.black
        : isHighlighted
        ? (monastic ? MonasticChrome.selectedFill : primary.withValues(alpha: 0.14))
        : (monastic ? MonasticChrome.controlFill : primary.withValues(alpha: 0.08));

    final borderColor = isContrast
        ? (isHighlighted ? Colors.yellow : Colors.white)
        : isHighlighted
        ? primary
        : (monastic ? MonasticChrome.controlBorder : primary.withValues(alpha: 0.22));

    final fgColor = isContrast
        ? (isHighlighted ? Colors.yellow : Colors.white)
        : isHighlighted
        ? primary
        : (monastic ? MonasticChrome.label : theme.textTheme.bodyMedium?.color);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Horizontal padding, icon, gap, dropdown, and the 1px border on
        // each side. The label uses whatever room is left so a bounded
        // phone row ellipsizes instead of overflowing.
        const chrome = 56.0;
        final bounded = constraints.maxWidth.isFinite;
        final room = bounded ? constraints.maxWidth - chrome : maxLabelWidth;
        final labelMax = room < maxLabelWidth ? (room < 36 ? 36.0 : room) : maxLabelWidth;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: minHeight == null ? 6 : 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isContrast ? Colors.yellow : primary),
              const SizedBox(width: 4),
              if (prefix != null)
                Text(
                  prefix!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isContrast ? Colors.yellow : primary,
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: labelMax),
                child: Text(
                  label,
                  key: labelKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: fgColor),
            ],
          ),
        );
      },
    );
  }
}
