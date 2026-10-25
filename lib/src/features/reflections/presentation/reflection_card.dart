import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/belong_text_styles.dart';

import '../../profile/domain/member_profile.dart';
import '../../profile/presentation/other_member_profile_dialog.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import 'reflections_providers.dart';
import 'threaded_discussion_sheet.dart';

/// Card widget presenting an unhurried reflection and qualitative care reaction affirmations.
class ReflectionCard extends ConsumerWidget {
  final Post post;
  final bool isContrast;
  final ValueChanged<String> onAddReaction;
  final VoidCallback? onOpenDiscussion;
  final bool isHighlighted;

  const ReflectionCard({
    super.key,
    required this.post,
    required this.isContrast,
    required this.onAddReaction,
    this.onOpenDiscussion,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMeme = post.toneTag.contains('Meme');
    final text = BelongTextStyles.of(context);

    return Container(
      key: Key('reflection_card_${post.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isContrast
                  ? const Color(0xFF1A1A00)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.08))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isHighlighted
              ? (isContrast ? Colors.yellow : const Color(0xFF2E6B56))
              : (isMeme
                    ? Colors.amber.withValues(alpha: 0.8)
                    : (isContrast
                          ? Colors.white
                          : Theme.of(context).dividerColor)),
          width: (isHighlighted || isMeme || isContrast) ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        key: Key('author_tap_target_${post.id}'),
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => OtherMemberProfileDialog.show(
                          context,
                          authorName: post.authorName,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isContrast
                                    ? Colors.yellow
                                    : Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15),
                                child: Text(
                                  getInitials(post.authorName),
                                  style: text.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isContrast
                                        ? Colors.black
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.emphasis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.formattedDate(),
                      key: Key('post_timestamp_${post.id}'),
                      style: text.caption,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: isMeme
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      post.toneTag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isMeme
                            ? Colors.amber.shade800
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: Key('save_post_button_${post.id}'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: post.isSaved
                        ? 'Remove from Saved'
                        : 'Save for Later (Private)',
                    onPressed: () => ref
                        .read(postRepositoryProvider)
                        .toggleSavePost(postId: post.id),
                    icon: Icon(
                      post.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                      color: post.isSaved
                          ? (isContrast
                                ? Colors.yellow
                                : Theme.of(context).colorScheme.primary)
                          : (isContrast
                                ? Colors.white70
                                : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (post.specialInterestTag != null &&
              post.specialInterestTag!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
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
          Semantics(
            container: true,
            label: post.content,
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                key: Key('post_meme_image_${post.id}'),
                constraints: const BoxConstraints(maxHeight: 280),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isMeme
                        ? Colors.amber.shade300
                        : (isContrast ? Colors.white70 : Colors.grey.shade300),
                  ),
                ),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  semanticLabel:
                      post.specialInterestTag ?? 'Community reflection image',
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(12.0),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 18,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Wholesome Meme / GIF Attached',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) {
                    final countAsync = ref.watch(
                      postCommentCountStreamProvider(post.id),
                    );
                    final count = countAsync.value ?? 0;
                    return OutlinedButton.icon(
                      key: Key('discussion_button_${post.id}'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed:
                          onOpenDiscussion ??
                          () =>
                              ThreadedDiscussionSheet.show(context, post: post),
                      icon: const Text('💬', style: TextStyle(fontSize: 12)),
                      label: Text(
                        count == 1
                            ? '1 Reply'
                            : (count > 1 ? '$count Replies' : 'Reply'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extracts clean monogram initials for cards, stripping parenthetical roles or locations.
  static String getInitials(String name) {
    final cleaned = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), ''))
        .where((p) => p.isNotEmpty)
        .where((p) => !MemberProfile.isHonorificToken(p))
        .toList();
    return switch (parts) {
      [] => 'B',
      [final single] => single[0].toUpperCase(),
      [final first, ..., final last] => '${first[0]}${last[0]}'.toUpperCase(),
    };
  }
}
