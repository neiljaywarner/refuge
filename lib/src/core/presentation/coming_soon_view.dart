import 'package:flutter/material.dart';

import 'system_insets.dart';

/// Reusable, calm "Coming Soon / Pending" placeholder view used for:
/// - `Notifications` bottom navigation tab (Issue #27)
/// - `Msgs` (Direct Messages) bottom navigation tab (Issue #27)
/// - `Actually Autistic Events` space item (Issue #28)
/// - Pending `Links` (`Community Guidelines` #29).
/// Phone download links open the install guide instead (#737).
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.title,
    required this.emoji,
    required this.description,
    this.trackedIssueNumber,
    this.extraMarkdownOrNote,
    this.onBackToFeed,
    this.showPwaInstallGuide = false,
  });

  final String title;
  final String emoji;
  final String description;
  final int? trackedIssueNumber;
  final String? extraMarkdownOrNote;
  final VoidCallback? onBackToFeed;
  final bool showPwaInstallGuide;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const .all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: .circular(16),
              side: BorderSide(color: primary.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const .all(24),
              child: Column(
                mainAxisSize: .min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const .symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: .circular(999),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                    ),
                  ),
                  if (extraMarkdownOrNote != null && extraMarkdownOrNote!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const .all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.06),
                        borderRadius: .circular(10),
                      ),
                      child: Text(
                        extraMarkdownOrNote!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                  if (showPwaInstallGuide) ...[
                    const SizedBox(height: 14),
                    FilledButton.tonalIcon(
                      key: const ValueKey('pwa_guide_button'),
                      onPressed: () => _showPwaGuideModal(context),
                      icon: const Icon(Icons.install_mobile_rounded, size: 18),
                      label: const Text('📱 How to Add to Home Screen (PWA Guide)'),
                    ),
                  ],
                  if (trackedIssueNumber != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tracked on GitHub Roadmap • Issue #$trackedIssueNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (onBackToFeed != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onBackToFeed,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Return to Feed'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPwaGuideModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: .vertical(top: .circular(24))),
      builder: (modalContext) {
        final theme = Theme.of(modalContext);
        final primary = theme.colorScheme.primary;
        return SystemBottomInset(
          child: SafeArea(
            child: Padding(
              padding: const .fromLTRB(24, 20, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                          borderRadius: .circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('📱', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8, width: 12),
                        Expanded(
                          child: Text(
                            'Add Belong to Your Home Screen',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belong is built as a lightweight Progressive Web App (PWA). You can install it on your phone in 10 seconds without an App Store account or large download.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPlatformCard(
                      theme: theme,
                      icon: Icons.android_rounded,
                      accentColor: primary,
                      platformTitle: 'Android (Google Chrome)',
                      steps: [
                        '1. Tap the three dots menu (⋮) in the top-right corner of Chrome.',
                        '2. Tap "Install and create shortcut" (or "Install app").',
                        '3. Tap "Install" or "Add" to confirm.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPlatformCard(
                      theme: theme,
                      icon: Icons.apple_rounded,
                      accentColor: primary,
                      platformTitle: 'iPhone & iPad (Apple Safari)',
                      steps: [
                        '1. Tap the Share button (square with arrow ⬆️) at the bottom of Safari.',
                        '2. Scroll down slightly and tap "Add to Home Screen" (➕).',
                        '3. Tap "Add" in the top-right corner to confirm.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const .all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: .circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: .start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Why Web App? Under 5 MB (no storage bloat), sensory-friendly fullscreen mode, and updates deploy instantly with zero waiting on store review queues.',
                              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('pwa_guide_dismiss_button'),
                        onPressed: () => Navigator.of(modalContext).pop(),
                        child: const Text('Got it!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatformCard({
    required ThemeData theme,
    required IconData icon,
    required Color accentColor,
    required String platformTitle,
    required List<String> steps,
  }) => Container(
    width: double.infinity,
    padding: const .all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: .circular(12),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(width: 8),
            Text(platformTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        for (final step in steps)
          Padding(
            padding: const .only(bottom: 4),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    ),
  );
}
