import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

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

/// Stable semantics id / widget key for a tone filter pill.
String toneFilterSemanticsId(String filter) {
  if (filter == 'All') return 'tone_filter_chip_all';
  final slug = filter
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'tone_filter_chip_$slug';
}

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
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const Gap(6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kToneFilters.map((f) {
                  final isSelected = activeFilter == f;
                  final semanticsId = toneFilterSemanticsId(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Semantics(
                      identifier: semanticsId,
                      button: true,
                      selected: isSelected,
                      label: f,
                      child: ChoiceChip(
                        key: Key(semanticsId),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        showCheckmark: false,
                        label: Text(f, style: const TextStyle(fontSize: 10)),
                        selected: isSelected,
                        onSelected: (_) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            ref.read(activeFilterProvider.notifier).state = f;
                            onSelectFilter(f);
                          });
                        },
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
