import 'package:flutter/material.dart';

import '../../about/presentation/about_refuge_dialog.dart';

/// Community header anchor banner introducing Belong on the Spectrum and calm-tech grounding.
class CommunityAnchorBanner extends StatelessWidget {
  final Color primaryColor;
  final bool isContrast;

  const CommunityAnchorBanner({
    super.key,
    required this.primaryColor,
    required this.isContrast,
  });

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isContrast ? Colors.black : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isContrast
              ? Colors.yellow
              : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isContrast
                  ? Colors.yellow.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.15),
            ),
            child: const Text('🧩', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Belong on the Spectrum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isContrast ? Colors.yellow : primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• belongonthespectrum.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '"Fearfully and wonderfully made" (Psalm 139:14)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: isContrast
                        ? Colors.white70
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => showAboutSanctuaryDialog(
              context,
              primaryColor: primaryColor,
              isContrast: isContrast,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isContrast ? Colors.yellow : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
}
