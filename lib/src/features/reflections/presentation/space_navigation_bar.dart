import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';

/// Navigation bar allowing members to transition calmly between fellowship spaces.
class SpaceNavigationBar extends ConsumerWidget {
  final String selectedSpace;
  final ValueChanged<String> onSelectSpace;

  const SpaceNavigationBar({super.key, required this.selectedSpace, required this.onSelectSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isContrast = theme.scaffoldBackgroundColor == Colors.black &&
        theme.colorScheme.primary == const Color(0xFFFFEB3B);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                selected: isSelected,
                label: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected && isContrast ? FontWeight.bold : FontWeight.normal,
                    color: isSelected && isContrast
                        ? Colors.black
                        : (isContrast ? Colors.white : null),
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
    );
  }
}
