/// Domain model representing an unhurried reflection with intent and tone clarification.
class Post {
  final String id;
  final String authorName;
  final String spaceKey;
  final String toneTag;
  final String? specialInterestTag;
  final String content;
  final DateTime timestamp;
  final Map<String, int> reactions;

  const Post({
    required this.id,
    required this.authorName,
    required this.spaceKey,
    required this.toneTag,
    this.specialInterestTag,
    required this.content,
    required this.timestamp,
    required this.reactions,
  });

  Post copyWith({
    String? id,
    String? authorName,
    String? spaceKey,
    String? toneTag,
    String? specialInterestTag,
    String? content,
    DateTime? timestamp,
    Map<String, int>? reactions,
  }) =>
      Post(
        id: id ?? this.id,
        authorName: authorName ?? this.authorName,
        spaceKey: spaceKey ?? this.spaceKey,
        toneTag: toneTag ?? this.toneTag,
        specialInterestTag: specialInterestTag ?? this.specialInterestTag,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        reactions: reactions ?? Map<String, int>.from(this.reactions),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          authorName == other.authorName &&
          spaceKey == other.spaceKey &&
          toneTag == other.toneTag &&
          specialInterestTag == other.specialInterestTag &&
          content == other.content &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      authorName.hashCode ^
      spaceKey.hashCode ^
      toneTag.hashCode ^
      (specialInterestTag?.hashCode ?? 0) ^
      content.hashCode ^
      timestamp.hashCode;
}
