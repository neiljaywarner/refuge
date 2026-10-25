import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

/// Interaction category for Belong calm notifications (#327, #442).
enum BelongNotificationType {
  mention,
  directMessage,
  reply,
  like,
  following;

  String get label => switch (this) {
        BelongNotificationType.mention => 'Mention',
        BelongNotificationType.directMessage => 'Direct Message',
        BelongNotificationType.reply => 'Reply',
        BelongNotificationType.like => 'Like',
        BelongNotificationType.following => 'Following',
      };
}

/// Domain model for a calm notification item in **Belong on the Spectrum** (#327, #329, #442).
class BelongNotification extends Equatable {
  const BelongNotification({
    required this.id,
    required this.type,
    required this.authorName,
    required this.postTitle,
    required this.timestamp,
    this.authorAvatarUrl,
    this.isRead = false,
    this.spaceKey,
    this.postId,
    this.commentSnippet,
    this.conversationId,
  });

  final String id;
  final BelongNotificationType type;
  final String authorName;
  final String postTitle;
  final DateTime timestamp;
  final String? authorAvatarUrl;
  final bool isRead;
  final String? spaceKey;
  final String? postId;
  final String? commentSnippet;
  final String? conversationId;

  @override
  List<Object?> get props => [
        id,
        type,
        authorName,
        postTitle,
        timestamp,
        authorAvatarUrl,
        isRead,
        spaceKey,
        postId,
        commentSnippet,
        conversationId,
      ];

  /// Author initials for the Avatar widget fallback, stripping parentheses,
  /// punctuation, and bracketed qualifiers (e.g. "Pastor Thomas (Melbourne)" -> "PT").
  String get authorInitials {
    final cleanName =
        authorName.replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), '').trim();
    final parts = cleanName
        .split(RegExp(r'[\s_.-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      final fallbackParts =
          authorName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (fallbackParts.isEmpty) return '?';
      final firstChar =
          fallbackParts[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      return firstChar.isNotEmpty ? firstChar[0].toUpperCase() : '?';
    }

    final firstLetter = parts[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (parts.length == 1) {
      return firstLetter.isNotEmpty ? firstLetter[0].toUpperCase() : '?';
    }
    final lastLetter = parts.last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (firstLetter.isEmpty && lastLetter.isEmpty) return '?';
    if (firstLetter.isEmpty) return lastLetter[0].toUpperCase();
    if (lastLetter.isEmpty) return firstLetter[0].toUpperCase();
    return (firstLetter[0] + lastLetter[0]).toUpperCase();
  }

  /// Human-readable title message following the user's specification:
  /// e.g. "Sarah L. mentioned you in a comment on 'Markan Chiasms'"
  String get displayMessage => switch (type) {
        BelongNotificationType.mention =>
          '$authorName mentioned you in a comment on "$postTitle"',
        BelongNotificationType.directMessage =>
          '$authorName sent you a direct message: "${commentSnippet ?? postTitle}"',
        BelongNotificationType.reply =>
          '$authorName replied to your comment on "$postTitle"',
        BelongNotificationType.like =>
          '$authorName liked your reflection on "$postTitle"',
        BelongNotificationType.following =>
          '$authorName posted a new reflection in "$postTitle"',
      };

  /// Relative human-readable timestamp:
  /// e.g. "1 hr ago", "2 days ago", "Sep 7th", "Just now"
  String formattedTimeAgo([DateTime? clockNow]) {
    final now = clockNow ?? DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h hr${h == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }

    return _formatCalendarDate(timestamp);
  }

  static String _formatCalendarDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = months[dt.month - 1];
    final day = dt.day;

    // Ordinal suffix (1st, 2nd, 3rd, 4th...)
    String suffix = 'th';
    if (day < 11 || day > 13) {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
      }
    }

    return '$monthName $day$suffix';
  }

  BelongNotification copyWith({
    String? id,
    BelongNotificationType? type,
    String? authorName,
    String? postTitle,
    DateTime? timestamp,
    String? authorAvatarUrl,
    bool? isRead,
    String? spaceKey,
    String? postId,
    String? commentSnippet,
    String? conversationId,
  }) {
    return BelongNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      authorName: authorName ?? this.authorName,
      postTitle: postTitle ?? this.postTitle,
      timestamp: timestamp ?? this.timestamp,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isRead: isRead ?? this.isRead,
      spaceKey: spaceKey ?? this.spaceKey,
      postId: postId ?? this.postId,
      commentSnippet: commentSnippet ?? this.commentSnippet,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  /// Converts notification to JSON map for cloud sync and webhook dispatch (#530).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'authorName': authorName,
      'postTitle': postTitle,
      'timestamp': timestamp.toIso8601String(),
      'authorAvatarUrl': authorAvatarUrl,
      'isRead': isRead,
      'spaceKey': spaceKey,
      'postId': postId,
      'commentSnippet': commentSnippet,
      'conversationId': conversationId,
    };
  }

  /// Creates a [BelongNotification] from JSON map.
  factory BelongNotification.fromJson(Map<String, dynamic> json) {
    return BelongNotification(
      id: json['id'] as String,
      type: BelongNotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BelongNotificationType.mention,
      ),
      authorName: json['authorName'] as String? ?? 'Community Member',
      postTitle: json['postTitle'] as String? ?? 'Reflection',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      spaceKey: json['spaceKey'] as String?,
      postId: json['postId'] as String?,
      commentSnippet: json['commentSnippet'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }
}
