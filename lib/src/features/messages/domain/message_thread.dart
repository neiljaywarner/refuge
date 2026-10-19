import 'package:flutter/foundation.dart';

/// Represents a single message exchange in a direct message thread.
@immutable
class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.senderName,
    required this.isFromMe,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final String senderName;
  final bool isFromMe;
  final String content;
  final DateTime sentAt;
}

/// A conversation thread between members in the Belong community.
@immutable
class MessageThread {
  const MessageThread({
    required this.id,
    required this.participantName,
    required this.avatarInitials,
    required this.previewSnippet,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isBatchedDigest = true,
    this.messages = const [],
  });

  final String id;
  final String participantName;
  final String avatarInitials;
  final String previewSnippet;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isBatchedDigest;
  final List<DirectMessage> messages;

  MessageThread copyWith({
    String? id,
    String? participantName,
    String? avatarInitials,
    String? previewSnippet,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isBatchedDigest,
    List<DirectMessage>? messages,
  }) {
    return MessageThread(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      previewSnippet: previewSnippet ?? this.previewSnippet,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isBatchedDigest: isBatchedDigest ?? this.isBatchedDigest,
      messages: messages ?? this.messages,
    );
  }

  /// Default welcoming seed threads for Belong on the Spectrum pre-alpha.
  static List<MessageThread> sampleThreads() {
    final now = DateTime.now();
    return [
      MessageThread(
        id: 'thread-welcome',
        participantName: 'Marty & Community Team',
        avatarInitials: 'MC',
        previewSnippet: 'Welcome to Belong on the Spectrum! Glad you are here with us.',
        lastActivity: now.subtract(const Duration(minutes: 15)),
        unreadCount: 1,
        isBatchedDigest: true,
        messages: [
          DirectMessage(
            id: 'msg-1',
            senderName: 'Marty',
            isFromMe: false,
            content: 'Welcome to Belong! Take your time exploring the spaces. No pressure to post or interact until you feel completely ready.',
            sentAt: now.subtract(const Duration(minutes: 15)),
          ),
        ],
      ),
      MessageThread(
        id: 'thread-board-games',
        participantName: 'Sensory Game Night Group',
        avatarInitials: 'SG',
        previewSnippet: 'Bringing Wingspan and Cascadia this Friday! Quiet room reserved.',
        lastActivity: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isBatchedDigest: true,
        messages: [
          DirectMessage(
            id: 'msg-2',
            senderName: 'Alex',
            isFromMe: false,
            content: 'Bringing Wingspan and Cascadia this Friday! Quiet room is reserved if anyone needs a quiet break.',
            sentAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      MessageThread(
        id: 'thread-quiet-cowork',
        participantName: 'Silent Co-Presence Fellowship',
        avatarInitials: 'CP',
        previewSnippet: 'Tomorrow 2 PM: cameras optional, ambient lo-fi, zero masking.',
        lastActivity: now.subtract(const Duration(hours: 6)),
        unreadCount: 0,
        isBatchedDigest: true,
        messages: [
          DirectMessage(
            id: 'msg-3',
            senderName: 'Jordan',
            isFromMe: false,
            content: 'Tomorrow at 2 PM: cameras optional, mic muted by default, ambient lo-fi, zero masking.',
            sentAt: now.subtract(const Duration(hours: 6)),
          ),
        ],
      ),
    ];
  }
}
