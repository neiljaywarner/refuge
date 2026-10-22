import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../reflections/data/post_repository.dart';
import '../../reflections/domain/comment.dart';
import '../../reflections/domain/post.dart';
import '../../reflections/presentation/reflection_card.dart';
import '../../reflections/presentation/reflections_providers.dart';
import '../../reflections/presentation/threaded_discussion_sheet.dart';
import '../../sensory_themes/domain/sensory_mode.dart';
import '../../sensory_themes/presentation/sensory_theme_controller.dart';
import 'belong_members_directory_view.dart';

/// Modal dialog/sheet displaying another member's profile, including:
/// - Activity metrics: Posts Count & Comments Count
/// - Tap to view authored posts with like counters & reaction triggers
/// - Tap to view authored comments with timestamps & discussion links
class OtherMemberProfileDialog extends HookConsumerWidget {
  final String authorName;
  final DevFellowshipMember? member;

  const OtherMemberProfileDialog({
    super.key,
    required this.authorName,
    this.member,
  });

  static Future<void> show(
    BuildContext context, {
    required String authorName,
    DevFellowshipMember? member,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => OtherMemberProfileDialog(
          authorName: authorName,
          member: member,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(memberPostsStreamProvider(authorName));
    final commentsAsync = ref.watch(memberCommentsStreamProvider(authorName));
    final currentMode = ref.watch(sensoryThemeModeProvider);
    final isContrast = currentMode == SensoryMode.contrast;
    final primary = Theme.of(context).colorScheme.primary;

    final activeTab = useState<String>('posts');

    // Find member metadata or synthesize fallback
    final effectiveMember = member ??
        kDevFellowshipMembers.cast<DevFellowshipMember?>().firstWhere(
              (m) =>
                  m != null &&
                  (m.name.toLowerCase() == authorName.toLowerCase() ||
                      authorName.toLowerCase().contains(m.name.toLowerCase()) ||
                      m.name.toLowerCase().contains(authorName.toLowerCase())),
              orElse: () => null,
            ) ??
        DevFellowshipMember(
          name: authorName,
          role: 'Fellowship Contributor',
          tagline: 'Reflecting in calm fellowship',
          bio: 'Fellow believer sharing unhurried reflections in Belong on the Spectrum.',
          churchAffiliation: 'Church Fellowship',
          isIcocMember: true,
          comfortBadges: ['Community Member', 'Gentle fellowship'],
        );

    final posts = postsAsync.value ?? <Post>[];
    final comments = commentsAsync.value ?? <Comment>[];

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(
              effectiveMember.initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        effectiveMember.name,
                        key: const Key('other_member_profile_name'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: effectiveMember.isIcocMember
                            ? primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        effectiveMember.isIcocMember ? 'ICOC' : 'Guest',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: effectiveMember.isIcocMember ? primary : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  effectiveMember.effectiveTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('other_member_profile_close_button'),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close Profile',
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bio
              Text(
                effectiveMember.bio,
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 6),

              // Church affiliation
              Row(
                children: [
                  Icon(
                    effectiveMember.isIcocMember
                        ? Icons.church_rounded
                        : Icons.spa_rounded,
                    size: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    effectiveMember.churchAffiliation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontStyle: effectiveMember.isIcocMember
                          ? FontStyle.normal
                          : FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Comfort Badges
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: effectiveMember.comfortBadges.map((badge) {
                  return Chip(
                    label: Text(badge, style: const TextStyle(fontSize: 9.5)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Interactive Activity Counters: Posts & Comments
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('profile_activity_posts_tab'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => activeTab.value = 'posts',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: activeTab.value == 'posts'
                              ? primary.withValues(alpha: 0.12)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeTab.value == 'posts'
                                ? primary
                                : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                            width: activeTab.value == 'posts' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${posts.length}',
                              key: const Key('profile_posts_count_badge'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: activeTab.value == 'posts' ? primary : null,
                              ),
                            ),
                            Text(
                              posts.length == 1 ? 'Post' : 'Posts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: activeTab.value == 'posts'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: activeTab.value == 'posts' ? primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      key: const Key('profile_activity_comments_tab'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => activeTab.value = 'comments',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: activeTab.value == 'comments'
                              ? primary.withValues(alpha: 0.12)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeTab.value == 'comments'
                                ? primary
                                : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                            width: activeTab.value == 'comments' ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${comments.length}',
                              key: const Key('profile_comments_count_badge'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: activeTab.value == 'comments' ? primary : null,
                              ),
                            ),
                            Text(
                              comments.length == 1 ? 'Comment' : 'Comments',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: activeTab.value == 'comments'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: activeTab.value == 'comments' ? primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Activity View: Posts or Comments
              if (activeTab.value == 'posts') ...[
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No reflections shared yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                else
                  for (final post in posts) ...[
                    ReflectionCard(
                      key: Key('author_post_card_${post.id}'),
                      post: post,
                      isContrast: isContrast,
                      onAddReaction: (r) => ref.read(postRepositoryProvider).addReaction(
                            postId: post.id,
                            reactionType: r,
                          ),
                      onOpenDiscussion: () => ThreadedDiscussionSheet.show(
                        context,
                        post: post,
                      ),
                    ),
                  ],
              ] else ...[
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No comments shared yet in discussions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                else
                  for (final comment in comments) ...[
                    Card(
                      key: Key('author_comment_card_${comment.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (comment.toneTag != null && comment.toneTag!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      comment.toneTag!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text(
                                  'Under Post #${comment.postId}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment.content,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(comment.timestamp),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                  ),
                                ),
                                if (comment.reactions.isNotEmpty)
                                  Row(
                                    children: comment.reactions.entries.map((e) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '${e.value} ${e.key}',
                                          style: const TextStyle(fontSize: 10.5),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('profile_done_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${dt.month}/${dt.day}';
  }
}
