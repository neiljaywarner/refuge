import 'package:equatable/equatable.dart';

/// Supported notification interaction types for Belong on the Spectrum.
enum BelongNotificationType {
  mention,
  reply,
  like,
  following;

  String get label => switch (this) {
    BelongNotificationType.mention => 'Mentions',
    BelongNotificationType.reply => 'Threads',
    BelongNotificationType.like => 'Likes',
    BelongNotificationType.following => 'Following',
  };
}

/// Filter categories for the Calm Notifications inbox.
enum BelongNotificationFilter {
  inbox('Inbox'),
  mentions('Mentions'),
  threads('Threads'),
  following('Following');

  const BelongNotificationFilter(this.label);
  final String label;
}

/// Rich notification model for the Belong Calm Notifications feed.
class BelongNotification extends Equatable {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final BelongNotificationType type;
  final String postTitle;
  final String? commentSnippet;
  final DateTime timestamp;
  final bool isRead;

  const BelongNotification({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.type,
    required this.postTitle,
    this.commentSnippet,
    required this.timestamp,
    this.isRead = false,
  });

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
  /// e.g. "John Doe mentioned you in a comment on 'Markan Chiasms'"
  String get displayMessage {
    switch (type) {
      case BelongNotificationType.mention:
        return '$authorName mentioned you in a comment on "$postTitle"';
      case BelongNotificationType.reply:
        return '$authorName replied to your comment on "$postTitle"';
      case BelongNotificationType.like:
        return '$authorName liked your reflection on "$postTitle"';
      case BelongNotificationType.following:
        return '$authorName posted a new reflection in "$postTitle"';
    }
  }

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

    // Older than 7 days, format as "Sep 7th"
    return _formatMonthDay(timestamp);
  }

  static String _formatMonthDay(DateTime dt) {
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
    final monthStr = months[dt.month - 1];
    final day = dt.day;

    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
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
        default:
          suffix = 'th';
      }
    }

    return '$monthStr $day$suffix';
  }

  BelongNotification copyWith({
    String? id,
    String? authorName,
    String? authorAvatarUrl,
    BelongNotificationType? type,
    String? postTitle,
    String? commentSnippet,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return BelongNotification(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      type: type ?? this.type,
      postTitle: postTitle ?? this.postTitle,
      commentSnippet: commentSnippet ?? this.commentSnippet,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authorName,
    authorAvatarUrl,
    type,
    postTitle,
    commentSnippet,
    timestamp,
    isRead,
  ];
}
