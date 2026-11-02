import 'reaction_member.dart';

/// Domain model representing a thoughtful, unhurried discussion reply or comment.
///
/// Supports nested replies by optionally referencing a [parentCommentId].
class Comment {
  final String id;
  final String postId;
  final String? parentCommentId;
  final String authorName;
  final String content;
  final String? toneTag;
  final DateTime timestamp;
  final Map<String, int> reactions;

  /// Members who reacted with care, keyed by reaction type (e.g. pray, peace, relatable, encouraged).
  final Map<String, List<ReactionMember>> reactionMembers;

  const Comment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorName,
    required this.content,
    this.toneTag,
    required this.timestamp,
    this.reactions = const {},
    this.reactionMembers = const {},
  });

  /// Whether a specific [userId] has actively reacted with [reactionType].
  bool hasMemberReacted(String reactionType, String? userId) {
    if (userId == null || userId.isEmpty) return false;
    final members = reactionMembers[reactionType];
    if (members == null) return false;
    return members.any((m) => m.userId == userId);
  }

  /// List of all members who affirmed this comment with [reactionType].
  List<ReactionMember> membersForReaction(String reactionType) =>
      reactionMembers[reactionType] ?? const [];

  /// Reaction count for [reactionType], preferring [reactionMembers] length when available.
  int countForReaction(String reactionType) {
    final members = reactionMembers[reactionType];
    if (members != null && members.isNotEmpty) return members.length;
    return reactions[reactionType] ?? 0;
  }

  /// Whether this comment is a nested reply to another comment.
  bool get isNested => parentCommentId != null && parentCommentId!.isNotEmpty;

  Comment copyWith({
    String? id,
    String? postId,
    String? parentCommentId,
    String? authorName,
    String? content,
    String? toneTag,
    DateTime? timestamp,
    Map<String, int>? reactions,
    Map<String, List<ReactionMember>>? reactionMembers,
  }) => Comment(
    id: id ?? this.id,
    postId: postId ?? this.postId,
    parentCommentId: parentCommentId ?? this.parentCommentId,
    authorName: authorName ?? this.authorName,
    content: content ?? this.content,
    toneTag: toneTag ?? this.toneTag,
    timestamp: timestamp ?? this.timestamp,
    reactions: reactions ?? Map<String, int>.from(this.reactions),
    reactionMembers: reactionMembers ?? _cloneReactionMembers(this.reactionMembers),
  );

  static Map<String, List<ReactionMember>> _cloneReactionMembers(
    Map<String, List<ReactionMember>> source,
  ) => {for (final entry in source.entries) entry.key: List<ReactionMember>.from(entry.value)};

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    if (parentCommentId != null) 'parentCommentId': parentCommentId,
    'authorName': authorName,
    'content': content,
    if (toneTag != null) 'toneTag': toneTag,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'reactions': reactions,
    if (reactionMembers.isNotEmpty)
      'reactionMembers': {
        for (final entry in reactionMembers.entries)
          entry.key: entry.value.map((m) => m.toJson()).toList(),
      },
  };

  factory Comment.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
    final parsedReactions = <String, int>{};
    if (rawReactions is Map) {
      for (final entry in rawReactions.entries) {
        final value = entry.value;
        if (value is num) {
          parsedReactions[entry.key.toString()] = value.toInt();
        }
      }
    }

    final rawReactionMembers = json['reactionMembers'];
    final parsedReactionMembers = <String, List<ReactionMember>>{};
    if (rawReactionMembers is Map) {
      for (final entry in rawReactionMembers.entries) {
        final list = entry.value;
        if (list is List) {
          parsedReactionMembers[entry.key.toString()] = list
              .whereType<Map<String, dynamic>>()
              .map(ReactionMember.fromJson)
              .toList();
        }
      }
    }

    return Comment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      parentCommentId: json['parentCommentId'] as String?,
      authorName: json['authorName'] as String? ?? 'Fellowship Member',
      content: json['content'] as String? ?? '',
      toneTag: json['toneTag'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      reactions: parsedReactions,
      reactionMembers: parsedReactionMembers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          postId == other.postId &&
          parentCommentId == other.parentCommentId &&
          authorName == other.authorName &&
          content == other.content &&
          toneTag == other.toneTag &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      postId.hashCode ^
      (parentCommentId?.hashCode ?? 0) ^
      authorName.hashCode ^
      content.hashCode ^
      (toneTag?.hashCode ?? 0) ^
      timestamp.hashCode;
}
