import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../core/build/build_identity.dart';
import '../../../core/config/other_site_info_button.dart';
import '../../../core/logging/app_logger.dart';
import '../../sensory_themes/domain/sensory_font_scale.dart';
import '../../sensory_themes/domain/sensory_mode.dart';
import 'about_build_stamp.dart';

/// Shows the About Belong on the Spectrum & Sensory Settings dialog
/// (with all hackathon / Judge API Explorer clutter removed per Issue #18).
///
/// [buildIdentity] defaults to the compile-time dart-defines. When they are
/// absent the dialog shows git commit `unknown`, build time `unknown`, and
/// source `dev`. It does not invent a commit SHA.
/// [loadVersion] defaults to the platform package version from pubspec.
void showAboutRefugeDialog(
  BuildContext context, {
  required Color primaryColor,
  required bool isContrast,
  SensoryMode currentMode = SensoryMode.sage,
  ValueChanged<SensoryMode>? onSelectMode,
  SensoryFontScale currentFontScale = SensoryFontScale.standard,
  ValueChanged<SensoryFontScale>? onSelectFontScale,
  BuildIdentity? buildIdentity,
  Future<AppVersionLabel> Function()? loadVersion,
  VoidCallback? onOpenFeedback,
}) {
  final identity = buildIdentity ?? BuildIdentity.fromEnvironment;
  final versionFuture = (loadVersion ?? loadPackageVersion)();
  showDialog(
    context: context,
    builder: (ctx) => Semantics(
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      container: true,
      label: 'About Belong',
      child: AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: .circular(8),
              child: Image.asset(
                'assets/images/belong_logo.png',
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const Text('♾️', style: TextStyle(fontSize: 22)),
              ),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  AboutDialogTitle(
                    version: versionFuture,
                    primaryColor: primaryColor,
                    isContrast: isContrast,
                  ),
                  Text(
                    'belongonthespectrum.com • Partnered with DFW Church',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const OtherSiteInfoButton(),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Container(
                  padding: const .all(10),
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.yellow.withValues(alpha: 0.1)
                        : primaryColor.withValues(alpha: 0.08),
                    borderRadius: .circular(8),
                    border: Border.all(
                      color: isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        '"I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."',
                        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic),
                      ),
                      SizedBox(height: 4),
                      Semantics(
                        label: 'Psalm 139:14',
                        excludeSemantics: true,
                        child: Text(
                          '— Psalm 139:14',
                          style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                AboutBuildStamp(identity: identity, version: versionFuture),
                const Gap(12),
                // Dedicated High Contrast Mode Toggle (Issue #277)
                SwitchListTile(
                  contentPadding: .zero,
                  dense: true,
                  title: const Text(
                    'High Contrast Mode',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Stark black & yellow palette for maximum visual clarity',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: currentMode == SensoryMode.contrast,
                  onChanged: (val) {
                    onSelectMode?.call(val ? SensoryMode.contrast : SensoryMode.sage);
                    Navigator.pop(ctx);
                  },
                ),
                const Gap(6),
                const Text(
                  'Sensory Theme Palettes:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Gap(6),
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
                      label: const Text('🌙 Dark'),
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
                const Gap(12),
                // Sensory Font Scaling Presets (Issue #277)
                const Text(
                  'Sensory Font Scaling (Visual Ergonomics):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                const Text(
                  'Adjust typography size to relieve visual crowding and reading fatigue:',
                  style: TextStyle(fontSize: 11),
                ),
                const Gap(6),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    for (final scale in SensoryFontScale.values)
                      ChoiceChip(
                        label: Text('${scale.label} (${scale.percentage})'),
                        selected: currentFontScale == scale,
                        onSelected: (_) {
                          onSelectFontScale?.call(scale);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'About Belong on the Spectrum:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                const Text(
                  '• A welcoming Christian & neurodivergent/autistic fellowship community.\n'
                  '• Designed with calm-tech principles: zero surprise pop-ups, zero auto-playing media, and clear conversational intent tags.\n'
                  '• Community announcements and guidance are updated unhurriedly by organizers.',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
                const Divider(height: 20),
                const Text(
                  'Community Support & Feedback:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                const Text(
                  '• Primary support during open alpha is through in-app Vote & Feedback (tap Vote & Feedback on the Home screen).\n'
                  '• Need help, want to suggest an improvement, or report a quirk? Share your thoughts with zero pressure.',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (onOpenFeedback != null)
            TextButton.icon(
              key: const Key('about_dialog_open_feedback_button'),
              onPressed: () {
                Navigator.of(ctx).pop();
                onOpenFeedback();
              },
              icon: const Icon(Icons.how_to_vote_outlined, size: 16),
              label: const Text('Vote & Feedback', style: TextStyle(fontSize: 12)),
            ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TalkerScreen(talker: talker)));
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('Diagnostics & Logs', style: TextStyle(fontSize: 12)),
          ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    ),
  );
}

/// Backward-compatible alias for showAboutRefugeDialog.
void showAboutSanctuaryDialog(
  BuildContext context, {
  required Color primaryColor,
  required bool isContrast,
  SensoryMode currentMode = SensoryMode.sage,
  ValueChanged<SensoryMode>? onSelectMode,
  SensoryFontScale currentFontScale = SensoryFontScale.standard,
  ValueChanged<SensoryFontScale>? onSelectFontScale,
  BuildIdentity? buildIdentity,
  Future<AppVersionLabel> Function()? loadVersion,
  VoidCallback? onOpenFeedback,
}) => showAboutRefugeDialog(
  context,
  primaryColor: primaryColor,
  isContrast: isContrast,
  currentMode: currentMode,
  onSelectMode: onSelectMode,
  currentFontScale: currentFontScale,
  onSelectFontScale: onSelectFontScale,
  buildIdentity: buildIdentity,
  loadVersion: loadVersion,
  onOpenFeedback: onOpenFeedback,
);
