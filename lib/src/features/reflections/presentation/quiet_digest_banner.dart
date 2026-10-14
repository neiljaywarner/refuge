import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';
import 'reflections_providers.dart';

/// Banner rendering the server-computed QuietDigest aggregate for the active space.
class QuietDigestBanner extends ConsumerWidget {
  final Color primaryColor;
  final bool isContrast;
  final String? legacyMessage;

  const QuietDigestBanner({
    super.key,
    required this.primaryColor,
    required this.isContrast,
    this.legacyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSpace = ref.watch(activeSpaceKeyProvider);
    final digestAsync = ref.watch(quietDigestProvider(activeSpace));

    final message = legacyMessage ?? digestAsync.valueOrNull;
    if (message == null || message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isContrast
            ? Colors.yellow.withValues(alpha: 0.1)
            : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_twilight, size: 15, color: isContrast ? Colors.yellow : primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isContrast ? Colors.yellow : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
