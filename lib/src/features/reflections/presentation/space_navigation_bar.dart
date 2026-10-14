import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';

/// Navigation bar allowing members to transition calmly between fellowship spaces.
class SpaceNavigationBar extends ConsumerWidget {
  final String selectedSpace;
  final ValueChanged<String> onSelectSpace;

  const SpaceNavigationBar({super.key, required this.selectedSpace, required this.onSelectSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
              label: Text(entry.value, style: const TextStyle(fontSize: 12)),
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
