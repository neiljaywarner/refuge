import 'package:flutter/material.dart';

/// Compact non-production marker shown in the app bar (VGV-style visibility).
class FlavorEnvironmentChip extends StatelessWidget {
  const FlavorEnvironmentChip({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$tag environment',
      child: Container(
        key: Key('flavor_environment_chip_$tag'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.shade800, width: 0.75),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.amber.shade900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
