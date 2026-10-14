import 'package:flutter/material.dart';

import '../../sensory_themes/domain/sensory_mode.dart';

/// Shows the About Refuge & Hackathon Credits dialog, including sensory theme settings.
void showAboutSanctuaryDialog(
  BuildContext context, {
  required Color primaryColor,
  required bool isContrast,
  SensoryMode currentMode = SensoryMode.sage,
  ValueChanged<SensoryMode>? onSelectMode,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Text('🧩', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Refuge (Sanctuary) v0.1.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isContrast ? Colors.yellow : primaryColor,
                  ),
                ),
                Text(
                  'Belong on the Spectrum • belongonthespectrum.com',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isContrast
                      ? Colors.yellow.withValues(alpha: 0.1)
                      : primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  '"I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."\n— Psalm 139:14',
                  style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sensory Theme Settings (WCAG AAA):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ChoiceChip(
                    label: const Text('☀️ Clean Slate'),
                    selected: currentMode == SensoryMode.clean,
                    onSelected: (_) {
                      onSelectMode?.call(SensoryMode.clean);
                      Navigator.pop(ctx);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('🌿 Sage Botanical'),
                    selected: currentMode == SensoryMode.sage,
                    onSelected: (_) {
                      onSelectMode?.call(SensoryMode.sage);
                      Navigator.pop(ctx);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('🌙 Monastic Dark'),
                    selected: currentMode == SensoryMode.charcoal,
                    onSelected: (_) {
                      onSelectMode?.call(SensoryMode.charcoal);
                      Navigator.pop(ctx);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('👁️ High Contrast'),
                    selected: currentMode == SensoryMode.contrast,
                    onSelected: (_) {
                      onSelectMode?.call(SensoryMode.contrast);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const Divider(height: 20),
              const Text(
                'Community Purpose & Calm-Tech Moat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Created for neurodivergent individuals, autistic Christians, and friends.\n'
                '• Replaces expensive mainstream community SaaS (\$89–\$130/month) with low-cost (<\$5/month) Serverpod compute.\n'
                '• Zero dopamine manipulation: no red unread badges, no typing indicators, no algorithmic feeds, no notification anxiety.\n'
                '• Unifying Special Interest: Everyone brings their unique interests while sharing honest, unhurried reflections in safety.',
                style: TextStyle(fontSize: 11.5, height: 1.4),
              ),
              const Divider(height: 20),
              const Text(
                'Grateful Appreciation & Hackathon Credits:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '🌟 BuilderBase: For developer cloud credits, deployment infrastructure, and sponsoring the Serverpod Hackathon.\n'
                '⚡ Serverpod Team & Community: For building an outstanding full-stack Dart framework with typed protocol generation, real-time streaming, and Serverpod Insights.\n'
                '🌿 Belong on the Spectrum: For inspiring our community architecture and showing that neurodiversity is a gift.',
                style: TextStyle(fontSize: 11.5, height: 1.4),
              ),
              const Divider(height: 20),
              const Text(
                'Release Log (v0.1.0):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '• CodeWithAndrea Riverpod feature-first architecture\n'
                '• Serverpod 4 (^4.0.4) protocol models (.spy.yaml) & ORM\n'
                '• Atomic PostgreSQL qualitative care affirmations\n'
                '• Real-time WebSocket streaming with 800ms resilient offline fallback\n'
                '• Server-side Quiet Digest aggregation over space reflections\n'
                '• 4 WCAG AAA-tested sensory modes (Sage, Clean, Dark, Contrast)\n'
                '• 5 Fellowship spaces with Autism & Faith Meme support\n'
                '• Serverpod Insights native macOS desktop diagnostic profiling\n'
                '• Public GitHub Repository: neiljaywarner/refuge4serverpod',
                style: TextStyle(fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
    ),
  );
}
