import 'package:flutter/material.dart';

class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.title,
    required this.emoji,
    required this.description,
    this.trackedIssueNumber,
    this.extraMarkdownOrNote,
    this.onBackToFeed,
  });

  final String title;
  final String emoji;
  final String description;
  final int? trackedIssueNumber;
  final String? extraMarkdownOrNote;
  final VoidCallback? onBackToFeed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: primary.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        extraMarkdownOrNote!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
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
}
