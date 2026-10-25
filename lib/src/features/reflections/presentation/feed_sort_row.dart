import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../domain/feed_sort_option.dart';

/// Applies [action] on the next frame so a parent rebuild does not run inside
/// [ChoiceChip]'s own `setState` during the tap.
void selectFeedSortAfterFrame(BuildContext context, VoidCallback action) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    action();
  });
}

/// Horizontal sorting affordance displaying criteria chips and a popup sort menu.
class FeedSortRow extends StatelessWidget {
  final FeedSortOption activeSort;
  final ValueChanged<FeedSortOption> onSelectSort;
  final bool isContrast;

  const FeedSortRow({
    super.key,
    required this.activeSort,
    required this.onSelectSort,
    this.isContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Row(
        children: [
          Semantics(
            identifier: 'feed_sort_popup_button',
            button: true,
            label: 'Sort feed',
            child: PopupMenuButton<FeedSortOption>(
              key: const Key('feed_sort_popup_button'),
              tooltip: 'Sort feed by...',
              offset: const Offset(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isContrast ? Colors.white : theme.dividerColor),
              ),
              initialValue: activeSort,
              onSelected: (opt) => selectFeedSortAfterFrame(context, () => onSelectSort(opt)),
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
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? primary : null,
                                  ),
                                ),
                                Text(
                                  opt.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_rounded, size: 16, color: primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isContrast
                      ? Colors.black
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isContrast
                        ? Colors.white
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 14, color: isContrast ? Colors.yellow : primary),
                    const Gap(4),
                    Text(
                      'Sort: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.yellow : primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FeedSortOption.values.map((opt) {
                  final isSelected = activeSort == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Semantics(
                      identifier: 'feed_sort_chip_${opt.name}',
                      button: true,
                      selected: isSelected,
                      label: opt.label,
                      child: ChoiceChip(
                        key: Key('feed_sort_chip_${opt.name}'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // Default checkmarks plus a Text avatar crash or
                        // truncate the strip when selection changes (#485).
                        showCheckmark: false,
                        label: Text(
                          '${opt.emoji} ${opt.label}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            selectFeedSortAfterFrame(context, () => onSelectSort(opt)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
