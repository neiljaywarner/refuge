import '../../../core/formatting/relative_date.dart';

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
  final bool isDemo;
  final bool isSaved;

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
    this.isDemo = false,
    this.isSaved = false,
  });

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
    bool? isDemo,
    bool? isSaved,
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
    isDemo: isDemo ?? this.isDemo,
    isSaved: isSaved ?? this.isSaved,
  );

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
    'isDemo': isDemo,
    'isSaved': isSaved,
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
      isDemo: json['isDemo'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? true,
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
          isSaved == other.isSaved;

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
      isSaved.hashCode;
}
