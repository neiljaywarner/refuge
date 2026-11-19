import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/community_analytics_service.dart';
import '../../../core/presentation/unbroken_body_text.dart';
import '../../../core/theme/belong_text_styles.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/domain/member_profile.dart';
import '../../profile/presentation/other_member_profile_dialog.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import 'reaction_details_sheet.dart';
import 'reflection_post_media.dart';
import 'reflections_providers.dart';
import 'threaded_discussion_sheet.dart';

/// Card widget presenting an unhurried reflection and qualitative care reaction affirmations.
class ReflectionCard extends ConsumerWidget {
  final Post post;
  final bool isContrast;
  final ValueChanged<String> onAddReaction;
  final VoidCallback? onOpenDiscussion;
  final bool isHighlighted;
  final VoidCallback? onNavigateToSaved;

  const ReflectionCard({
    super.key,
    required this.post,
    required this.isContrast,
    required this.onAddReaction,
    this.onOpenDiscussion,
    this.isHighlighted = false,
    this.onNavigateToSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMeme = post.toneTag.contains('Meme');
    final text = BelongTextStyles.of(context);

    String? currentUserId;
    try {
      currentUserId = ref.watch(authRepositoryProvider).currentSession().userId;
    } catch (_) {
      // Graceful fallback for minimal widget tests without AuthRepository
      currentUserId = null;
    }

    final hasPrayed = post.hasMemberReacted('pray', currentUserId);
    final hasSupported = post.hasMemberReacted('peace', currentUserId);
    final hasEncouraged = post.hasMemberReacted('encouraged', currentUserId);
    final hasRelated = post.hasMemberReacted('relatable', currentUserId);

    return Container(
      key: Key('reflection_card_${post.id}'),
      margin: const .symmetric(vertical: 6.0),
      padding: const .all(14.0),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isContrast
                  ? const Color(0xFF1A1A00)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.08))
            : Theme.of(context).cardColor,
        borderRadius: .circular(14.0),
        border: Border.all(
          color: isHighlighted
              ? (isContrast ? Colors.yellow : const Color(0xFF2E6B56))
              : (isMeme
                    ? Colors.amber.withValues(alpha: 0.8)
                    : (isContrast ? Colors.white : Theme.of(context).dividerColor)),
          width: (isHighlighted || isMeme || isContrast) ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                // max would fill the Wrap and push the tone tag onto the next line.
                mainAxisSize: .min,
                children: [
                  Flexible(
                    child: InkWell(
                      key: Key('author_tap_target_${post.id}'),
                      borderRadius: .circular(4),
                      onTap: () =>
                          OtherMemberProfileDialog.show(context, authorName: post.authorName),
                      child: Padding(
                        padding: const .symmetric(vertical: 2, horizontal: 2),
                        child: Row(
                          mainAxisSize: .min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: isContrast
                                  ? Colors.yellow
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                                maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 2 : 1,
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
                  Flexible(
                    child: Text(
                      post.formattedDate(),
                      key: Key('post_timestamp_${post.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.caption,
                    ),
                  ),
                  if (post.publishStatus == PostPublishStatus.pending) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Waiting to share',
                        key: Key('post_pending_${post.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption,
                      ),
                    ),
                  ],
                ],
              ),
              // Keep the 48dp save control on this line. A wrap dropped it
              // under the tag once large text made the tag wide, and that
              // pushed the reflection itself down the screen (#951).
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxTagWidth = constraints.maxWidth - 64;
                  return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxTagWidth < 80 ? constraints.maxWidth : maxTagWidth,
                        ),
                        child: Container(
                          padding: const .symmetric(horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: isMeme
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: .circular(6.0),
                          ),
                          child: Text(
                            post.toneTag,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isMeme
                                  ? Colors.amber.shade800
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        key: Key('save_post_button_${post.id}'),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.padded,
                          padding: .zero,
                        ),
                        tooltip: post.isSaved ? 'Remove from Saved' : 'Save for Later (Private)',
                        onPressed: () async {
                          final wasSaved = post.isSaved;
                          final repo = ref.read(postRepositoryProvider);
                          final analytics = ref.read(communityAnalyticsServiceProvider);
                          await repo.toggleSavePost(postId: post.id);
                          unawaited(
                            analytics.logPostSaved(
                              postId: post.id,
                              isSaved: !wasSaved,
                              spaceKey: post.spaceKey,
                            ),
                          );
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          if (messenger == null) return;
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              key: Key('save_for_later_snackbar_${post.id}'),
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      wasSaved
                                          ? 'Removed from Saved for Later.'
                                          : '🔖 Saved to your private Saved for Later space.',
                                    ),
                                  ),
                                  if (!wasSaved && onNavigateToSaved != null) ...[
                                    const SizedBox(width: 8),
                                    TextButton(
                                      key: Key('view_saved_for_later_btn_${post.id}'),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                      onPressed: () {
                                        messenger.hideCurrentSnackBar();
                                        onNavigateToSaved!();
                                      },
                                      child: const Text(
                                        'View Saved',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  repo.toggleSavePost(postId: post.id);
                                  unawaited(
                                    analytics.logPostSaved(
                                      postId: post.id,
                                      isSaved: wasSaved,
                                      spaceKey: post.spaceKey,
                                      isUndo: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 18,
                          color: post.isSaved
                              ? (isContrast ? Colors.yellow : Theme.of(context).colorScheme.primary)
                              : (isContrast ? Colors.white70 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          if (post.isSaved && post.spaceKey != 'saved_for_later') ...[
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final spaceInfo = getBelongSpaceInfo(post.spaceKey);
                return Container(
                  key: Key('saved_post_origin_space_${post.id}'),
                  padding: const .symmetric(horizontal: 8.0, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isContrast
                        ? Colors.yellow.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: .circular(6.0),
                  ),
                  child: Text(
                    '🔖 Saved from ${spaceInfo.emoji} ${spaceInfo.title}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isContrast ? Colors.yellow : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ],
          if (post.specialInterestTag != null && post.specialInterestTag!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const .symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.12),
                borderRadius: .circular(6.0),
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
            child: UnbrokenBodyText(
              key: Key('post_body_${post.id}'),
              text: post.content,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
          if (ReflectionPostMedia.isRenderableUrl(post.imageUrl)) ...[
            const SizedBox(height: 10),
            ReflectionPostMedia(
              postId: post.id,
              imageUrl: post.imageUrl!.trim(),
              isMeme: isMeme,
              isContrast: isContrast,
              semanticLabel: post.specialInterestTag ?? 'Community reflection image',
            ),
          ],
          const SizedBox(height: 12),
          // A horizontal row clips Encouraged and Relatable at text scale 2.
          // Wrap keeps every chip inside the card (#932).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildReactionButton(
                context: context,
                type: 'pray',
                emoji: '🙏',
                label: 'Praying',
                hasReacted: hasPrayed,
                count: post.countForReaction('pray'),
                key: Key('reaction_button_pray_${post.id}'),
              ),
              _buildReactionButton(
                context: context,
                type: 'peace',
                emoji: '🤍',
                label: 'Support',
                hasReacted: hasSupported,
                count: post.countForReaction('peace'),
                key: Key('reaction_button_peace_${post.id}'),
              ),
              if (post.reactions.containsKey('encouraged') ||
                  post.reactions.containsKey('relatable') ||
                  post.reactionMembers.containsKey('encouraged') ||
                  post.reactionMembers.containsKey('relatable')) ...[
                _buildReactionButton(
                  context: context,
                  type: 'encouraged',
                  emoji: '🌱',
                  label: 'Encouraged',
                  hasReacted: hasEncouraged,
                  count: post.countForReaction('encouraged'),
                  key: Key('reaction_button_encouraged_${post.id}'),
                ),
                _buildReactionButton(
                  context: context,
                  type: 'relatable',
                  emoji: '😄',
                  label: 'Relatable',
                  hasReacted: hasRelated,
                  count: post.countForReaction('relatable'),
                  key: Key('reaction_button_relatable_${post.id}'),
                ),
              ],
              Builder(
                builder: (ctx) {
                  final countAsync = ref.watch(postCommentCountStreamProvider(post.id));
                  final count = countAsync.value ?? 0;
                  return OutlinedButton.icon(
                    key: Key('discussion_button_${post.id}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed:
                        onOpenDiscussion ?? () => ThreadedDiscussionSheet.show(context, post: post),
                    icon: const Text('💬', style: TextStyle(fontSize: 12)),
                    label: Text(
                      count == 1 ? '1 Reply' : (count > 1 ? '$count Replies' : 'Reply'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required BuildContext context,
    required String type,
    required String emoji,
    required String label,
    required bool hasReacted,
    required int count,
    required Key key,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Tap to ${hasReacted ? 'remove' : 'add'} reaction • Long-press to see who reacted',
      child: GestureDetector(
        onLongPress: () =>
            ReactionDetailsSheet.show(context, post: post, initialReactionType: type),
        child: OutlinedButton.icon(
          key: key,
          style: OutlinedButton.styleFrom(
            backgroundColor: hasReacted
                ? (isContrast
                      ? const Color(0xFF2A2A00)
                      : theme.colorScheme.primary.withValues(alpha: 0.15))
                : null,
            side: BorderSide(
              color: hasReacted
                  ? (isContrast ? Colors.yellow : theme.colorScheme.primary)
                  : (isContrast ? Colors.white : theme.dividerColor),
              width: hasReacted ? 1.5 : 1.0,
            ),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () => onAddReaction(type),
          icon: Text(emoji, style: const TextStyle(fontSize: 12)),
          label: Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
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
