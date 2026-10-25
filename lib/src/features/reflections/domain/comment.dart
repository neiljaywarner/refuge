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

  const Comment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorName,
    required this.content,
    this.toneTag,
    required this.timestamp,
    this.reactions = const {},
  });

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
  }) => Comment(
    id: id ?? this.id,
    postId: postId ?? this.postId,
    parentCommentId: parentCommentId ?? this.parentCommentId,
    authorName: authorName ?? this.authorName,
    content: content ?? this.content,
    toneTag: toneTag ?? this.toneTag,
    timestamp: timestamp ?? this.timestamp,
    reactions: reactions ?? Map<String, int>.from(this.reactions),
  );

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
