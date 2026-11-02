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
