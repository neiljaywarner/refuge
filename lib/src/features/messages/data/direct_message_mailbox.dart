import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_flavor.dart';
import '../../notifications/data/direct_message_push_caller.dart';
import '../../notifications/domain/belong_notification.dart';
import '../../profile/presentation/belong_members_directory_view.dart';
import '../domain/message_recipient.dart';
import '../domain/message_thread.dart';
import '../domain/stored_direct_message.dart';

fb_auth.User? _currentFirebaseUser() {
  try {
    if (Firebase.apps.isEmpty) return null;
    return fb_auth.FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}

/// Result of attempting to deliver a message to Firestore.
enum DirectMessageSendOutcome { delivered, localOnly, deviceOnly }

class DirectMessageSendResult {
  const DirectMessageSendResult({
    required this.outcome,
    required this.message,
    required this.thread,
  });

  final DirectMessageSendOutcome outcome;
  final StoredDirectMessage message;
  final MessageThread thread;
}

/// Loads recipients, persists direct messages, and builds inbox threads (#441).
abstract class DirectMessageMailbox {
  Future<List<MessageRecipient>> loadDirectory({
    required bool includeSamples,
    required bool isProduction,
  });

  Future<List<MessageThread>> loadThreads(String currentUserId);

  Future<DirectMessageSendResult> sendMessage({
    required String senderId,
    required String senderName,
    required List<MessageRecipient> recipients,
    required String content,
    String? subject,
  });

  List<BelongNotification> notificationsForUser({
    required String currentUserId,
    required List<BelongNotification> existing,
  });

  /// Permanently removes messages this sender wrote. Used by a Circle-style ban.
  Future<int> deleteBySender({
    required String senderId,
    required String senderName,
  });
}

class InMemoryDirectMessageMailbox implements DirectMessageMailbox {
  InMemoryDirectMessageMailbox({
    Map<String, StoredDirectMessage>? seed,
    Map<String, Map<String, dynamic>>? seedUsers,
  }) : _messages = {...?seed},
       _users = {...?seedUsers};

  final Map<String, StoredDirectMessage> _messages;
  final Map<String, Map<String, dynamic>> _users;

  void seedUser(String uid, Map<String, dynamic> data) {
    _users[uid] = data;
  }

  void cacheMessage(StoredDirectMessage message) {
    _messages[message.id] = message;
  }

  @override
  Future<List<MessageRecipient>> loadDirectory({
    required bool includeSamples,
    required bool isProduction,
  }) async {
    final currentId = _currentFirebaseUser()?.uid;
    final real = <MessageRecipient>[];
    for (final entry in _users.entries) {
      if (entry.key == currentId) continue;
      real.add(MessageRecipient.fromFirestoreUser(entry.key, entry.value));
    }
    if (real.isNotEmpty) return real;
    if (isProduction || !includeSamples) return real;
    return kDevFellowshipMembers.map(MessageRecipient.fromDevMember).toList();
  }

  @override
  Future<List<MessageThread>> loadThreads(String currentUserId) async {
    final docs = _messages.values
        .where((m) => m.participantIds.contains(currentUserId))
        .toList();
    return _threadsFromMessages(docs, currentUserId);
  }

  @override
  Future<DirectMessageSendResult> sendMessage({
    required String senderId,
    required String senderName,
    required List<MessageRecipient> recipients,
    required String content,
    String? subject,
  }) async {
    final recipientIds = recipients
        .where((r) => !r.isSample)
        .map((r) => r.id)
        .toList();
    final allSample = recipients.every((r) => r.isSample);
    final participantIds = <String>{
      if (!allSample) senderId,
      ...recipientIds,
    }.toList();
    final threadId = allSample
        ? 'thread-local-${DateTime.now().millisecondsSinceEpoch}'
        : StoredDirectMessage.computeThreadId(participantIds);
    final id = 'dm-${DateTime.now().millisecondsSinceEpoch}';
    final message = StoredDirectMessage(
      id: id,
      threadId: threadId,
      senderId: allSample ? 'local-sender' : senderId,
      senderName: senderName,
      recipientIds: allSample
          ? recipients.map((r) => r.id).toList()
          : recipientIds,
      recipientNames: recipients.map((r) => r.name).toList(),
      participantIds: allSample
          ? [senderId, ...recipients.map((r) => r.id)]
          : participantIds,
      subject: subject,
      content: content,
      sentAt: DateTime.now(),
    );
    if (!allSample) {
      _messages[id] = message;
    }
    final thread = _threadForMessage(message, senderId, recipients);
    return DirectMessageSendResult(
      outcome: allSample
          ? DirectMessageSendOutcome.localOnly
          : DirectMessageSendOutcome.delivered,
      message: message,
      thread: thread,
    );
  }

  @override
  List<BelongNotification> notificationsForUser({
    required String currentUserId,
    required List<BelongNotification> existing,
  }) {
    final byId = {for (final n in existing) n.id: n};
    for (final msg in _messages.values) {
      if (!msg.recipientIds.contains(currentUserId)) continue;
      if (msg.senderId == currentUserId) continue;
      final notifId = 'dm-${msg.id}';
      final prior = byId[notifId];
      byId[notifId] = BelongNotification(
        id: notifId,
        type: BelongNotificationType.directMessage,
        authorName: msg.senderName,
        postTitle: 'Direct Message',
        commentSnippet: msg.content,
        conversationId: msg.threadId,
        timestamp: msg.sentAt,
        isRead: prior?.isRead ?? false,
      );
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  @override
  Future<int> deleteBySender({
    required String senderId,
    required String senderName,
  }) async {
    final id = senderId.trim();
    final name = senderName.trim().toLowerCase();
    final before = _messages.length;
    _messages.removeWhere(
      (_, message) =>
          (id.isNotEmpty && message.senderId == id) ||
          (name.isNotEmpty && message.senderName.trim().toLowerCase() == name),
    );
    return before - _messages.length;
  }
}

class FirestoreDirectMessageMailbox implements DirectMessageMailbox {
  FirestoreDirectMessageMailbox({
    FirebaseFirestore? firestore,
    this.isProduction = false,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final bool isProduction;
  final InMemoryDirectMessageMailbox _offline = InMemoryDirectMessageMailbox();

  static const collection = 'direct_messages';
  static const sendTimeout = Duration(seconds: 8);

  FirebaseFirestore? get _db {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  @override
  Future<List<MessageRecipient>> loadDirectory({
    required bool includeSamples,
    required bool isProduction,
  }) async {
    final db = _db;
    final user = _currentFirebaseUser();
    if (db == null || user == null) {
      return _offline.loadDirectory(
        includeSamples: includeSamples,
        isProduction: isProduction,
      );
    }
    try {
      final snap = await db.collection('users').get();
      final real = <MessageRecipient>[];
      for (final doc in snap.docs) {
        if (doc.id == user.uid) continue;
        real.add(MessageRecipient.fromFirestoreUser(doc.id, doc.data()));
      }
      real.sort((a, b) => a.name.compareTo(b.name));
      if (real.isNotEmpty) return real;
      if (isProduction || !includeSamples) return real;
      return kDevFellowshipMembers.map(MessageRecipient.fromDevMember).toList();
    } catch (_) {
      return _offline.loadDirectory(
        includeSamples: includeSamples,
        isProduction: isProduction,
      );
    }
  }

  @override
  Future<List<MessageThread>> loadThreads(String currentUserId) async {
    final db = _db;
    if (db == null) {
      return _offline.loadThreads(currentUserId);
    }
    try {
      final snap = await db
          .collection(collection)
          .where('participantIds', arrayContains: currentUserId)
          .get();
      final messages = snap.docs
          .map((d) => StoredDirectMessage.fromMap(d.id, d.data()))
          .toList();
      return _threadsFromMessages(messages, currentUserId);
    } catch (_) {
      return _offline.loadThreads(currentUserId);
    }
  }

  @override
  Future<DirectMessageSendResult> sendMessage({
    required String senderId,
    required String senderName,
    required List<MessageRecipient> recipients,
    required String content,
    String? subject,
  }) async {
    final allSample = recipients.every((r) => r.isSample);
    if (allSample) {
      return _offline.sendMessage(
        senderId: senderId,
        senderName: senderName,
        recipients: recipients,
        content: content,
        subject: subject,
      );
    }

    final recipientIds = recipients.map((r) => r.id).toList();
    final participantIds = <String>{senderId, ...recipientIds}.toList();
    final threadId = StoredDirectMessage.computeThreadId(participantIds);
    final id = 'dm-${DateTime.now().millisecondsSinceEpoch}';
    final message = StoredDirectMessage(
      id: id,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      recipientIds: recipientIds,
      recipientNames: recipients.map((r) => r.name).toList(),
      participantIds: participantIds,
      subject: subject,
      content: content,
      sentAt: DateTime.now(),
    );
    final thread = _threadForMessage(message, senderId, recipients);

    final db = _db;
    if (db == null) {
      return DirectMessageSendResult(
        outcome: DirectMessageSendOutcome.deviceOnly,
        message: message,
        thread: thread,
      );
    }

    try {
      await db
          .collection(collection)
          .doc(id)
          .set(message.toMap())
          .timeout(sendTimeout);
      // Keep the row on this device too. The recipient's bell can show it
      // in the same session when the Firestore read is not deployed yet.
      _offline.cacheMessage(message);
      if (shouldRequestDirectMessagePush(DirectMessageSendOutcome.delivered.name)) {
        unawaited(requestDirectMessagePush(id));
      }
      return DirectMessageSendResult(
        outcome: DirectMessageSendOutcome.delivered,
        message: message,
        thread: thread,
      );
    } catch (e, st) {
      debugPrint('Direct message Firestore write failed: $e\n$st');
      _offline.cacheMessage(message);
      return DirectMessageSendResult(
        outcome: DirectMessageSendOutcome.deviceOnly,
        message: message,
        thread: thread,
      );
    }
  }

  @override
  List<BelongNotification> notificationsForUser({
    required String currentUserId,
    required List<BelongNotification> existing,
  }) {
    return _offline.notificationsForUser(
      currentUserId: currentUserId,
      existing: existing,
    );
  }

  Future<void> hydrateFromFirestore(String currentUserId) async {
    final db = _db;
    if (db == null) return;
    try {
      final snap = await db
          .collection(collection)
          .where('participantIds', arrayContains: currentUserId)
          .get();
      for (final doc in snap.docs) {
        _offline.cacheMessage(StoredDirectMessage.fromMap(doc.id, doc.data()));
      }
    } catch (_) {}
  }

  @override
  Future<int> deleteBySender({
    required String senderId,
    required String senderName,
  }) async {
    final removedOffline = await _offline.deleteBySender(
      senderId: senderId,
      senderName: senderName,
    );
    final db = _db;
    if (db == null) return removedOffline;
    var removed = removedOffline;
    try {
      final byId = senderId.trim().isEmpty
          ? null
          : await db
                .collection(collection)
                .where('senderId', isEqualTo: senderId)
                .get();
      final byName = senderName.trim().isEmpty
          ? null
          : await db
                .collection(collection)
                .where('senderName', isEqualTo: senderName)
                .get();
      final docs = {...?byId?.docs, ...?byName?.docs};
      for (final doc in docs) {
        await doc.reference.delete();
        removed++;
      }
    } catch (_) {}
    return removed;
  }
}

List<MessageThread> _threadsFromMessages(
  List<StoredDirectMessage> messages,
  String currentUserId,
) {
  final byThread = <String, List<StoredDirectMessage>>{};
  for (final msg in messages) {
    byThread.putIfAbsent(msg.threadId, () => []).add(msg);
  }
  final threads = <MessageThread>[];
  for (final entry in byThread.entries) {
    final sorted = [...entry.value]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final last = sorted.last;
    final otherNames = last.participantIds
        .where((id) => id != currentUserId)
        .map((id) {
          final match = sorted.reversed.firstWhere(
            (m) => m.senderId == id || m.recipientIds.contains(id),
            orElse: () => last,
          );
          if (match.senderId == id) return match.senderName;
          final idx = match.recipientIds.indexOf(id);
          if (idx >= 0 && idx < match.recipientNames.length) {
            return match.recipientNames[idx];
          }
          return 'Fellow Member';
        })
        .toList();
    final participantName = otherNames.isEmpty
        ? 'Fellow Member'
        : otherNames.length == 1
        ? otherNames.first
        : '${otherNames.first} & ${otherNames.length - 1} others';
    final initials = participantName.isNotEmpty
        ? MessageRecipient(id: 'x', name: participantName, tagline: '').initials
        : 'B';
    threads.add(
      MessageThread(
        id: entry.key,
        participantName: participantName,
        avatarInitials: initials,
        subject: last.subject,
        messageType: otherNames.length > 1 ? 'Group' : 'Direct',
        recipientNames: otherNames,
        previewSnippet: last.content,
        lastActivity: last.sentAt,
        messages: [
          for (final m in sorted)
            DirectMessage(
              id: m.id,
              senderName: m.senderId == currentUserId ? 'You' : m.senderName,
              isFromMe: m.senderId == currentUserId,
              content: m.content,
              sentAt: m.sentAt,
            ),
        ],
      ),
    );
  }
  threads.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  return threads;
}

MessageThread _threadForMessage(
  StoredDirectMessage message,
  String senderId,
  List<MessageRecipient> recipients,
) {
  final participantName = recipients.length == 1
      ? recipients.first.name
      : '${recipients.first.name} & ${recipients.length - 1} others';
  final initials = recipients.first.initials;
  return MessageThread(
    id: message.threadId,
    participantName: participantName,
    avatarInitials: initials,
    subject: message.subject,
    messageType: recipients.length > 1 ? 'Group' : 'Direct',
    recipientNames: recipients.map((r) => r.name).toList(),
    previewSnippet: message.content,
    lastActivity: message.sentAt,
    messages: [
      DirectMessage(
        id: message.id,
        senderName: 'You',
        isFromMe: true,
        content: message.content,
        sentAt: message.sentAt,
      ),
    ],
  );
}

DirectMessageMailbox createDirectMessageMailbox({
  AppFlavor flavor = AppFlavor.dev,
}) {
  return FirestoreDirectMessageMailbox(isProduction: flavor.isProduction);
}
