import '../../../core/formatting/relative_date.dart';
import 'reaction_member.dart';

/// How far a reflection got past this device.
///
/// [confirmed] is stored in a cloud the fellowship can read, or there is no
/// cloud configured and a durable local copy exists.
/// [pending] is durable on this device and still waiting for that cloud.
/// [failed] never became durable, so the composer must keep the draft.
enum PostPublishStatus { confirmed, pending, failed }

/// Domain model representing an unhurried reflection with intent, tone, and optional calm media/GIF.
class Post {
  final String id;
  final String authorName;
  final String spaceKey;
  final String toneTag;
  final String? specialInterestTag;
  final String? imageUrl;
  final String content;
  final DateTime timestamp;
  final Map<String, int> reactions;

  /// Members who reacted with care, keyed by reaction type (e.g. pray, peace, relatable, encouraged).
  final Map<String, List<ReactionMember>> reactionMembers;

  final bool isDemo;
  final bool isSaved;

  /// Firebase uid of the member who wrote this reflection, when known.
  final String? authorId;

  /// Local delivery state. Cloud rows are [PostPublishStatus.confirmed].
  final PostPublishStatus publishStatus;

  const Post({
    required this.id,
    required this.authorName,
    required this.spaceKey,
    required this.toneTag,
    this.specialInterestTag,
    this.imageUrl,
    required this.content,
    required this.timestamp,
    required this.reactions,
    this.reactionMembers = const {},
    this.isDemo = false,
    this.isSaved = false,
    this.authorId,
    this.publishStatus = PostPublishStatus.confirmed,
  });

  /// Whether a specific [userId] has actively reacted with [reactionType].
  bool hasMemberReacted(String reactionType, String? userId) {
    if (userId == null || userId.isEmpty) return false;
    final members = reactionMembers[reactionType];
    if (members == null) return false;
    return members.any((m) => m.userId == userId);
  }

  /// List of all members who affirmed this reflection with [reactionType].
  List<ReactionMember> membersForReaction(String reactionType) =>
      reactionMembers[reactionType] ?? const [];

  /// Reaction count for [reactionType], preferring [reactionMembers] length when available.
  int countForReaction(String reactionType) {
    final members = reactionMembers[reactionType];
    if (members != null && members.isNotEmpty) return members.length;
    return reactions[reactionType] ?? 0;
  }

  /// Same relative or calendar label as a direct message, using [timestamp].
  String formattedDate([DateTime? clockNow]) => formatRelativeDate(timestamp, clockNow);

  Post copyWith({
    String? id,
    String? authorName,
    String? spaceKey,
    String? toneTag,
    String? specialInterestTag,
    String? imageUrl,
    String? content,
    DateTime? timestamp,
    Map<String, int>? reactions,
    Map<String, List<ReactionMember>>? reactionMembers,
    bool? isDemo,
    bool? isSaved,
    String? authorId,
    PostPublishStatus? publishStatus,
  }) => Post(
    id: id ?? this.id,
    authorName: authorName ?? this.authorName,
    spaceKey: spaceKey ?? this.spaceKey,
    toneTag: toneTag ?? this.toneTag,
    specialInterestTag: specialInterestTag ?? this.specialInterestTag,
    imageUrl: imageUrl ?? this.imageUrl,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    reactions: reactions ?? Map<String, int>.from(this.reactions),
    reactionMembers: reactionMembers ?? _cloneReactionMembers(this.reactionMembers),
    isDemo: isDemo ?? this.isDemo,
    isSaved: isSaved ?? this.isSaved,
    authorId: authorId ?? this.authorId,
    publishStatus: publishStatus ?? this.publishStatus,
  );

  static Map<String, List<ReactionMember>> _cloneReactionMembers(
    Map<String, List<ReactionMember>> source,
  ) => {for (final entry in source.entries) entry.key: List<ReactionMember>.from(entry.value)};

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'spaceKey': spaceKey,
    'toneTag': toneTag,
    if (specialInterestTag != null) 'specialInterestTag': specialInterestTag,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'content': content,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'reactions': reactions,
    if (reactionMembers.isNotEmpty)
      'reactionMembers': {
        for (final entry in reactionMembers.entries)
          entry.key: entry.value.map((m) => m.toJson()).toList(),
      },
    'isDemo': isDemo,
    'isSaved': isSaved,
    if (authorId != null && authorId!.isNotEmpty) 'authorId': authorId,
    'publishStatus': publishStatus.name,
  };

  factory Post.fromJson(Map<String, dynamic> json) {
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

    return Post(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName'] as String? ?? 'Fellowship Member',
      spaceKey: json['spaceKey'] as String? ?? 'general_chat',
      toneTag: json['toneTag'] as String? ?? '[Support]',
      specialInterestTag: json['specialInterestTag'] as String?,
      imageUrl: json['imageUrl'] as String?,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      reactions: parsedReactions,
      reactionMembers: parsedReactionMembers,
      isDemo: json['isDemo'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? true,
      authorId: json['authorId'] as String?,
      publishStatus:
          PostPublishStatus.values.asNameMap()[json['publishStatus']] ??
          PostPublishStatus.confirmed,
    );
  }

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
          imageUrl == other.imageUrl &&
          content == other.content &&
          timestamp == other.timestamp &&
          isDemo == other.isDemo &&
          isSaved == other.isSaved &&
          authorId == other.authorId &&
          publishStatus == other.publishStatus;

  @override
  int get hashCode =>
      id.hashCode ^
      authorName.hashCode ^
      spaceKey.hashCode ^
      toneTag.hashCode ^
      specialInterestTag.hashCode ^
      imageUrl.hashCode ^
      content.hashCode ^
      timestamp.hashCode ^
      isDemo.hashCode ^
      isSaved.hashCode ^
      authorId.hashCode ^
      publishStatus.hashCode;
}
