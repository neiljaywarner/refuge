import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reflections_providers.dart';

const List<String> kToneFilters = [
  'All',
  '[Prayer Request]',
  '[Comfort Only]',
  '[Bible Deep-Dive]',
  '[Special Interest Infodump]',
  '[Autism & Faith Meme]',
  '[Giving Thanks]',
  '[Question]',
  '[Resource]',
];

/// Horizontal filter row allowing members to filter by intent tag.
class ToneFilterRow extends ConsumerWidget {
  final String activeFilter;
  final ValueChanged<String> onSelectFilter;

  const ToneFilterRow({
    super.key,
    required this.activeFilter,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kToneFilters.map((f) {
                  final isSelected = activeFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(f, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(activeFilterProvider.notifier).state = f;
                        onSelectFilter(f);
                      },
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
