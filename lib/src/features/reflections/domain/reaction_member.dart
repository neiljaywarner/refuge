import 'package:flutter/foundation.dart';

/// Represents a fellowship member who offered a care reaction (pray, peace, relatable, encouraged).
@immutable
class ReactionMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime timestamp;

  const ReactionMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  factory ReactionMember.fromJson(Map<String, dynamic> json) => ReactionMember(
    userId: json['userId'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'Fellowship Member',
    avatarUrl: json['avatarUrl'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  ReactionMember copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    DateTime? timestamp,
  }) => ReactionMember(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => Object.hash(userId, displayName, avatarUrl);
}

/// Keeps names from [known] when [counts] still say that reaction happened
/// and [incoming] has nobody listed for it.
///
/// Cloud rows store a count without the member list. A later snapshot must
/// not turn "1 Relate" into an empty who-reacted sheet.
Map<String, List<ReactionMember>> retainKnownReactors({
  required Map<String, int> counts,
  required Map<String, List<ReactionMember>> incoming,
  required Map<String, List<ReactionMember>> known,
}) {
  if (known.isEmpty) return incoming;
  final merged = <String, List<ReactionMember>>{
    for (final entry in incoming.entries) entry.key: List<ReactionMember>.from(entry.value),
  };
  var changed = false;
  for (final entry in known.entries) {
    if (entry.value.isEmpty) continue;
    final have = merged[entry.key];
    if (have != null && have.isNotEmpty) continue;
    if ((counts[entry.key] ?? 0) <= 0) continue;
    merged[entry.key] = List<ReactionMember>.from(entry.value);
    changed = true;
  }
  if (!changed) return incoming;
  return merged;
}
