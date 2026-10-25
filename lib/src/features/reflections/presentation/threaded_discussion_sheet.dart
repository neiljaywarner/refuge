import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../admin/data/admin_banning_repository.dart';
import '../../admin/domain/ban_standing.dart';
import '../../admin/presentation/account_paused_banner.dart';
import '../../profile/domain/member_profile.dart';
import '../data/comment_repository.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import 'reflections_providers.dart';

/// Modal bottom sheet providing calm, threaded discussion replies under reflections.
class ThreadedDiscussionSheet extends HookConsumerWidget {
  final Post post;

  const ThreadedDiscussionSheet({super.key, required this.post});

  static Future<void> show(BuildContext context, {required Post post}) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SystemBottomInset(child: ThreadedDiscussionSheet(post: post)),
  );

  static const List<String> availableToneTags = [
    'None',
    '[Comfort Only]',
    '[Relatable]',
    '[Encouragement]',
    '[Prayer]',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(postCommentsStreamProvider(post.id));
    final currentProfile = ref.watch(memberProfileProvider);

    final replyingTo = useState<Comment?>(null);
    final selectedTone = useState<String>('None');
    final textController = useTextEditingController();
    useListenable(textController);
    final isPaused = ref.watch(isCurrentMemberBannedProvider);
    final canSubmit = !isPaused && textController.text.trim().isNotEmpty;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isPaused) {
      return const Material(child: Center(child: AccountPausedLockout()));
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Discussion & Replies',
                          key: const Key('threaded_discussion_sheet_title'),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('close_discussion_sheet_button'),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close discussion',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Original Post Context Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: isDark ? 0.7 : 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0] : 'P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post.toneTag,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // Threaded Comments List
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading comments: $err')),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined, size: 44, color: theme.disabledColor),
                          const SizedBox(height: 12),
                          Text(
                            'No replies yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to share an unhurried, gentle thought.',
                            key: const Key('empty_comments_placeholder'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentTile(
                      key: Key('comment_item_${comment.id}'),
                      comment: comment,
                      onReply: () => replyingTo.value = comment,
                      onReaction: (reaction) => ref
                          .read(commentRepositoryProvider)
                          .addReaction(commentId: comment.id, reactionType: reaction),
                    );
                  },
                );
              },
            ),
          ),

          // Composer Area
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Replying to banner
                    if (replyingTo.value != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            const Icon(Icons.reply, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Replying to @${replyingTo.value!.authorName}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              key: const Key('cancel_reply_target_button'),
                              icon: const Icon(Icons.close, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Cancel reply',
                              onPressed: () => replyingTo.value = null,
                            ),
                          ],
                        ),
                      ),

                    // Tone Tag Picker Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: availableToneTags.map((tag) {
                          final isSelected = selectedTone.value == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(tag, style: const TextStyle(fontSize: 10)),
                              selected: isSelected,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onSelected: (val) {
                                if (val) selectedTone.value = tag;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Input Field and Submit Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('comment_input_field'),
                              controller: textController,
                              maxLines: 4,
                              minLines: 1,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: replyingTo.value != null
                                    ? 'Write a gentle reply to @${replyingTo.value!.authorName}...'
                                    : 'Share an unhurried, gentle thought...',
                                hintStyle: TextStyle(fontSize: 12, color: theme.hintColor),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.dividerColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            key: const Key('submit_comment_button'),
                            icon: const Icon(Icons.send, size: 18),
                            tooltip: 'Submit reply',
                            onPressed: canSubmit
                                ? () async {
                                    final text = textController.text.trim();
                                    if (text.isEmpty) return;

                                    final author = currentProfile.displayName.isNotEmpty
                                        ? currentProfile.displayName
                                        : 'Fellowship Member';

                                    final newComment = Comment(
                                      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                                      postId: post.id,
                                      parentCommentId: replyingTo.value?.id,
                                      authorName: author,
                                      content: text,
                                      toneTag: selectedTone.value == 'None'
                                          ? null
                                          : selectedTone.value,
                                      timestamp: DateTime.now(),
                                    );

                                    final created = await createContributionUnlessBanned(
                                      isBanned: ref.read(isCurrentMemberBannedProvider),
                                      create: () async {
                                        await ref
                                            .read(commentRepositoryProvider)
                                            .addComment(newComment);
                                      },
                                    );
                                    if (!created) return;

                                    textController.clear();
                                    replyingTo.value = null;
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;
  final ValueChanged<String> onReaction;

  const _CommentTile({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNested = comment.isNested;

    Widget content = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNested ? theme.cardColor.withValues(alpha: 0.6) : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: isNested ? 0.3 : 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Tone Tag Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        comment.authorName.isNotEmpty ? comment.authorName[0] : 'M',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        comment.authorName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (comment.toneTag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comment.toneTag!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimeAgo(comment.timestamp),
                style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Comment Content
          Text(comment.content, style: const TextStyle(fontSize: 12.5, height: 1.4)),

          const SizedBox(height: 8),

          // Reactions & Reply Action
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _reactionButton(
                  context,
                  key: Key('comment_reaction_pray_${comment.id}'),
                  emoji: '🙏',
                  count: comment.reactions['pray'] ?? 0,
                  onTap: () => onReaction('pray'),
                ),
                const SizedBox(width: 6),
                _reactionButton(
                  context,
                  key: Key('comment_reaction_peace_${comment.id}'),
                  emoji: '🤍',
                  count: comment.reactions['peace'] ?? 0,
                  onTap: () => onReaction('peace'),
                ),
                if (comment.reactions.containsKey('encouraged') ||
                    comment.reactions.containsKey('relatable')) ...[
                  const SizedBox(width: 6),
                  _reactionButton(
                    context,
                    key: Key('comment_reaction_encouraged_${comment.id}'),
                    emoji: '🌱',
                    count: comment.reactions['encouraged'] ?? 0,
                    onTap: () => onReaction('encouraged'),
                  ),
                  const SizedBox(width: 6),
                  _reactionButton(
                    context,
                    key: Key('comment_reaction_relatable_${comment.id}'),
                    emoji: '😄',
                    count: comment.reactions['relatable'] ?? 0,
                    onTap: () => onReaction('relatable'),
                  ),
                ],
                const SizedBox(width: 12),
                TextButton.icon(
                  key: Key('reply_button_${comment.id}'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: const Icon(Icons.reply, size: 13),
                  label: const Text('Reply', style: TextStyle(fontSize: 10.5)),
                  onPressed: onReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isNested) {
      return Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 14, right: 8),
              width: 14,
              height: 14,
              alignment: Alignment.center,
              child: const Text('↳', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return content;
  }

  Widget _reactionButton(
    BuildContext context, {
    required Key key,
    required String emoji,
    required int count,
    required VoidCallback onTap,
  }) => InkWell(
    key: key,
    borderRadius: BorderRadius.circular(6),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    ),
  );

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
