import 'package:flutter/material.dart';

import '../../../core/formatting/relative_date.dart';
import '../../../core/theme/belong_text_styles.dart';
import '../domain/comment.dart';
import '../domain/post.dart';
import '../domain/reaction_member.dart';

/// Calm, sensory-friendly bottom sheet displaying members who affirmed a reflection or comment.
class ReactionDetailsSheet extends StatefulWidget {
  final Post? post;
  final Comment? comment;
  final String initialReactionType;

  const ReactionDetailsSheet({
    super.key,
    this.post,
    this.comment,
    this.initialReactionType = 'pray',
  }) : assert(post != null || comment != null, 'Either post or comment must be provided');

  static Future<void> show(
    BuildContext context, {
    Post? post,
    Comment? comment,
    String initialReactionType = 'pray',
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ReactionDetailsSheet(
      post: post,
      comment: comment,
      initialReactionType: initialReactionType,
    ),
  );

  @override
  State<ReactionDetailsSheet> createState() => _ReactionDetailsSheetState();
}

class _ReactionDetailsSheetState extends State<ReactionDetailsSheet> {
  late String _selectedType;

  static const _reactionMetadata = <String, (String emoji, String label)>{
    'pray': ('🙏', 'Praying'),
    'peace': ('🤍', 'Support'),
    'encouraged': ('🌱', 'Encouraged'),
    'relatable': ('😄', 'Relatable'),
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialReactionType;
    // Fall back to first available reaction if selected type has 0
    final counts = _getCounts();
    if ((counts[_selectedType] ?? 0) == 0) {
      for (final key in _reactionMetadata.keys) {
        if ((counts[key] ?? 0) > 0) {
          _selectedType = key;
          break;
        }
      }
    }
  }

  Map<String, int> _getCounts() {
    final counts = <String, int>{};
    for (final key in _reactionMetadata.keys) {
      if (widget.post != null) {
        counts[key] = widget.post!.countForReaction(key);
      } else if (widget.comment != null) {
        counts[key] = widget.comment!.countForReaction(key);
      }
    }
    return counts;
  }

  List<ReactionMember> _getMembers(String type) {
    if (widget.post != null) {
      return widget.post!.membersForReaction(type);
    }
    if (widget.comment != null) {
      return widget.comment!.membersForReaction(type);
    }
    return const [];
  }

  String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = BelongTextStyles.of(context);
    final counts = _getCounts();
    final activeMembers = _getMembers(_selectedType);
    final selectedMeta = _reactionMetadata[_selectedType] ?? ('✨', 'Reaction');

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.65),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Care Affirmations', style: text.title.copyWith(fontWeight: FontWeight.w600)),
                IconButton(
                  key: const Key('reaction_sheet_close_button'),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _reactionMetadata.entries.map((entry) {
                final type = entry.key;
                final emoji = entry.value.$1;
                final label = entry.value.$2;
                final count = counts[type] ?? 0;
                final isSelected = _selectedType == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: Key('reaction_chip_$type'),
                    selected: isSelected,
                    label: Text(
                      '$emoji $label $count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = type);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 24),

          // Member List
          Expanded(
            child: activeMembers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(selectedMeta.$1, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'No members have offered ${selectedMeta.$2.toLowerCase()} yet.',
                            textAlign: TextAlign.center,
                            style: text.body.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeMembers.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final member = activeMembers[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          foregroundColor: theme.colorScheme.primary,
                          backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                              ? Text(
                                  _extractInitials(member.displayName),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(member.displayName, style: text.emphasis),
                        trailing: Text(
                          formatRelativeDate(member.timestamp),
                          style: text.caption.copyWith(color: theme.hintColor),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
