import 'package:flutter/material.dart';

import '../domain/post.dart';

/// Card widget presenting an unhurried reflection and qualitative care reaction affirmations.
class ReflectionCard extends StatelessWidget {
  final Post post;
  final bool isContrast;
  final ValueChanged<String> onAddReaction;

  const ReflectionCard({
    super.key,
    required this.post,
    required this.isContrast,
    required this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    final isMeme = post.toneTag.contains('Meme');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isMeme
              ? Colors.amber.withValues(alpha: 0.8)
              : (isContrast ? Colors.white : Theme.of(context).dividerColor),
          width: isMeme ? 2.0 : (isContrast ? 2.0 : 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                post.authorName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: isMeme
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  post.toneTag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMeme ? Colors.amber.shade800 : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (post.specialInterestTag != null && post.specialInterestTag!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                '🧩 Special Interest: ${post.specialInterestTag}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(post.content, style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => onAddReaction('pray'),
                  icon: const Text('🙏', style: TextStyle(fontSize: 12)),
                  label: Text(
                    '${post.reactions['pray'] ?? 0} Praying',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => onAddReaction('peace'),
                  icon: const Text('🤍', style: TextStyle(fontSize: 12)),
                  label: Text(
                    '${post.reactions['peace'] ?? 0} Support',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (post.reactions.containsKey('encouraged') ||
                    post.reactions.containsKey('relatable')) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => onAddReaction('encouraged'),
                    icon: const Text('🌱', style: TextStyle(fontSize: 12)),
                    label: Text(
                      '${post.reactions['encouraged'] ?? 0} Encouraged',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => onAddReaction('relatable'),
                    icon: const Text('😄', style: TextStyle(fontSize: 12)),
                    label: Text(
                      '${post.reactions['relatable'] ?? 0} Relatable',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
