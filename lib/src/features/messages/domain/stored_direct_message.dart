import 'package:flutter/foundation.dart';

/// One persisted direct message document in Firestore `direct_messages` (#441).
@immutable
class StoredDirectMessage {
  const StoredDirectMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.recipientIds,
    required this.recipientNames,
    required this.participantIds,
    required this.content,
    required this.sentAt,
    this.subject,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final List<String> recipientIds;
  final List<String> recipientNames;
  final List<String> participantIds;
  final String? subject;
  final String content;
  final DateTime sentAt;

  static String computeThreadId(List<String> participantIds) {
    final sorted = [...participantIds]..sort();
    return sorted.join('_');
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientIds': recipientIds,
      'recipientNames': recipientNames,
      'participantIds': participantIds,
      if (subject != null && subject!.isNotEmpty) 'subject': subject,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory StoredDirectMessage.fromMap(String id, Map<String, dynamic> data) {
    final sentRaw = data['sentAt'];
    final sentAt = sentRaw is String
        ? (DateTime.tryParse(sentRaw) ?? DateTime.now())
        : DateTime.now();
    return StoredDirectMessage(
      id: id,
      threadId: data['threadId'] as String? ?? id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Fellow Member',
      recipientIds: _stringList(data['recipientIds']),
      recipientNames: _stringList(data['recipientNames']),
      participantIds: _stringList(data['participantIds']),
      subject: data['subject'] as String?,
      content: data['content'] as String? ?? '',
      sentAt: sentAt,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
