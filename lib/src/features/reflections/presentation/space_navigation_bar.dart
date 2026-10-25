import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';

/// Navigation bar allowing members to transition calmly between fellowship spaces,
/// featuring a clear human-readable room title and breadcrumb (#618).
class SpaceNavigationBar extends ConsumerWidget {
  final String selectedSpace;
  final ValueChanged<String> onSelectSpace;
  final VoidCallback? onBackToSpaces;

  const SpaceNavigationBar({
    super.key,
    required this.selectedSpace,
    required this.onSelectSpace,
    this.onBackToSpaces,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isContrast =
        theme.scaffoldBackgroundColor == Colors.black &&
        theme.colorScheme.primary == const Color(0xFFFFEB3B);

    final spaceInfo = getBelongSpaceInfo(selectedSpace);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky room title / breadcrumb header (#618)
        Container(
          key: const Key('space_room_header'),
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: isContrast ? Colors.white24 : theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              if (onBackToSpaces != null) ...[
                Semantics(
                  button: true,
                  label: 'Back to Spaces directory',
                  child: InkWell(
                    key: const Key('space_breadcrumb_back_button'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: onBackToSpaces,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 12,
                            color: isContrast ? Colors.yellow : primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Spaces',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isContrast ? Colors.yellow : primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontSize: 12,
                      color: isContrast ? Colors.white54 : theme.disabledColor,
                    ),
                  ),
                ),
              ],
              Text(spaceInfo.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spaceInfo.title,
                  key: const Key('space_room_title'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isContrast ? Colors.yellow : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onBackToSpaces != null)
                Semantics(
                  button: true,
                  label: 'View all spaces',
                  child: InkWell(
                    key: const Key('space_breadcrumb_all_spaces_button'),
                    borderRadius: BorderRadius.circular(6),
                    onTap: onBackToSpaces,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 13,
                            color: isContrast ? Colors.white70 : theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All Spaces',
                            style: TextStyle(
                              fontSize: 11,
                              color: isContrast ? Colors.white70 : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Space selection chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kFellowshipSpaces.entries.map((entry) {
                final isSelected = selectedSpace == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    key: Key('space_chip_${entry.key}'),
                    selected: isSelected,
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected && (isContrast || theme.brightness == Brightness.dark)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected && isContrast
                            ? Colors.black
                            : (isContrast
                                  ? Colors.white
                                  : (theme.brightness == Brightness.dark
                                        ? (isSelected
                                              ? const Color(0xFF8CD4A2)
                                              : const Color(0xFFE2E8F0))
                                        : null)),
                      ),
                    ),
                    onSelected: (_) {
                      ref.read(activeSpaceKeyProvider.notifier).state = entry.key;
                      onSelectSpace(entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
