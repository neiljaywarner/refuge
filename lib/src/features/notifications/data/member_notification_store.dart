import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/member_directory_store.dart';
import '../domain/belong_notification.dart';

/// Handles written as `@name` in a reflection. The `@` is not included.
final RegExp mentionHandlePattern = RegExp(r'@([A-Za-z0-9_]+)');

Set<String> extractMentionHandles(String content) => mentionHandlePattern
    .allMatches(content)
    .map((match) => match.group(1)!.toLowerCase())
    .toSet();

/// Fields copied onto the author's public `users/{uid}` document when the
/// private `member_notifications` collection is not writable yet.
///
/// Direct-message text is replaced with a generic title. Mention text is kept
/// because the post itself is public and the bell has to show it.
Map<String, Object?> publicOutboundNotice({
  required String id,
  required String recipientUid,
  required String authorUid,
  required String authorName,
  required BelongNotificationType type,
  required String postTitle,
  String? commentSnippet,
  String? spaceKey,
  required int createdAtMillis,
}) {
  final direct = type == BelongNotificationType.directMessage;
  final snippet = direct ? null : commentSnippet?.trim();
  return {
    'id': id,
    'recipientUid': recipientUid,
    'authorUid': authorUid,
    'authorName': authorName,
    'type': type.name,
    'postTitle': direct ? 'Direct message' : postTitle,
    if (snippet != null && snippet.isNotEmpty) 'commentSnippet': snippet,
    if (spaceKey != null && spaceKey.trim().isNotEmpty) 'spaceKey': spaceKey,
    'createdAtMillis': createdAtMillis,
  };
}

/// Cross-account bell items.
///
/// Writes go to `member_notifications` when rules allow it. Until that
/// collection is deployed, the same notice is stored on the author's own
/// `users/{uid}` document, which the recipient can read. Direct-message
/// bodies are omitted from that public fallback. Seeded local notices stay
/// in memory.
class MemberNotificationStore {
  MemberNotificationStore({this.customFirestore});

  static const collectionPath = 'member_notifications';
  static const outboundNoticesField = 'outboundNotices';
  static const outboundRecipientsField = 'outboundRecipientUids';

  final FirebaseFirestore? customFirestore;

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<List<BelongNotification>> watchForRecipient(String uid) {
    if (uid.isEmpty || uid == 'guest') return Stream.value(const []);
    final fs = firestore;
    if (fs == null) return Stream.value(const []);

    final controller = StreamController<List<BelongNotification>>();
    StreamSubscription<List<BelongNotification>>? privateSub;
    StreamSubscription<List<BelongNotification>>? publicSub;

    controller.onListen = () {
      privateSub = _watchPrivate(fs, uid).listen(
        (items) {
          publicSub?.cancel();
          publicSub = null;
          if (!controller.isClosed) controller.add(items);
        },
        onError: (_) {
          if (publicSub != null || controller.isClosed) return;
          publicSub = _watchPublic(fs, uid).listen(
            (items) {
              if (!controller.isClosed) controller.add(items);
            },
            onError: (_) {
              if (!controller.isClosed) controller.add(const []);
            },
          );
        },
      );
    };
    controller.onCancel = () async {
      await privateSub?.cancel();
      await publicSub?.cancel();
    };
    return controller.stream;
  }

  Stream<List<BelongNotification>> _watchPrivate(
    FirebaseFirestore fs,
    String uid,
  ) => fs
      .collection(collectionPath)
      .where('recipientUid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final items = <BelongNotification>[];
        for (final doc in snapshot.docs) {
          final parsed = _fromDoc(doc.id, doc.data());
          if (parsed != null) items.add(parsed);
        }
        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return items;
      });

  Stream<List<BelongNotification>> _watchPublic(
    FirebaseFirestore fs,
    String uid,
  ) => fs
      .collection(MemberDirectoryStore.collectionPath)
      .where(outboundRecipientsField, arrayContains: uid)
      .snapshots()
      .map((snapshot) {
        final items = <BelongNotification>[];
        for (final doc in snapshot.docs) {
          final raw = doc.data()[outboundNoticesField];
          if (raw is! List) continue;
          for (final entry in raw) {
            if (entry is! Map) continue;
            final data = Map<String, dynamic>.from(entry);
            if (data['recipientUid'] != uid) continue;
            final parsed = _fromDoc('${data['id'] ?? doc.id}', {
              ...data,
              'createdAt': data['createdAtMillis'],
            });
            if (parsed != null) items.add(parsed);
          }
        }
        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return items;
      });

  Future<void> notifyRecipient({
    required String recipientUid,
    required String authorUid,
    required String authorName,
    required BelongNotificationType type,
    required String postTitle,
    String? commentSnippet,
    String? spaceKey,
  }) async {
    if (recipientUid.isEmpty ||
        authorUid.isEmpty ||
        authorUid == 'guest' ||
        recipientUid == authorUid) {
      return;
    }
    final fs = firestore;
    if (fs == null) return;
    try {
      await fs
          .collection(collectionPath)
          .add({
            'recipientUid': recipientUid,
            'authorUid': authorUid,
            'authorName': authorName,
            'type': type.name,
            'postTitle': postTitle,
            'commentSnippet': commentSnippet,
            'spaceKey': spaceKey,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 4));
      return;
    } catch (_) {}

    final createdAtMillis = DateTime.now().millisecondsSinceEpoch;
    final notice = publicOutboundNotice(
      id: '${recipientUid}_$createdAtMillis',
      recipientUid: recipientUid,
      authorUid: authorUid,
      authorName: authorName,
      type: type,
      postTitle: postTitle,
      commentSnippet: commentSnippet,
      spaceKey: spaceKey,
      createdAtMillis: createdAtMillis,
    );
    try {
      await fs
          .collection(MemberDirectoryStore.collectionPath)
          .doc(authorUid)
          .set({
            outboundRecipientsField: FieldValue.arrayUnion([recipientUid]),
            outboundNoticesField: FieldValue.arrayUnion([notice]),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Writes one mention per `@handle` that matches a directory member.
  Future<void> notifyMentionsInContent({
    required String content,
    required String authorUid,
    required String authorName,
    String? spaceKey,
  }) async {
    final handles = extractMentionHandles(content);
    if (handles.isEmpty || authorUid.isEmpty || authorUid == 'guest') return;
    final fs = firestore;
    if (fs == null) return;
    try {
      final handleList = handles.toList();
      for (var i = 0; i < handleList.length; i += 10) {
        final chunk = handleList.sublist(
          i,
          i + 10 > handleList.length ? handleList.length : i + 10,
        );
        final snap = await fs
            .collection(MemberDirectoryStore.collectionPath)
            .where('handle', whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final recipientUid = (data['uid'] as String?) ?? doc.id;
          await notifyRecipient(
            recipientUid: recipientUid,
            authorUid: authorUid,
            authorName: authorName,
            type: BelongNotificationType.mention,
            postTitle: content,
            commentSnippet: content,
            spaceKey: spaceKey,
          );
        }
      }
    } catch (_) {}
  }

  BelongNotification? _fromDoc(String id, Map<String, dynamic> data) {
    final typeName = data['type'] as String?;
    final type = BelongNotificationType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    if (type == null) return null;
    final authorName = (data['authorName'] as String?)?.trim();
    final postTitle = (data['postTitle'] as String?)?.trim();
    if (authorName == null ||
        authorName.isEmpty ||
        postTitle == null ||
        postTitle.isEmpty) {
      return null;
    }
    return BelongNotification(
      id: id,
      type: type,
      authorName: authorName,
      postTitle: postTitle,
      timestamp: _timestampOf(data['createdAt']),
      isRead: data['isRead'] == true,
      spaceKey: data['spaceKey'] as String?,
      commentSnippet: data['commentSnippet'] as String?,
    );
  }

  DateTime _timestampOf(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.now();
  }
}

final memberNotificationStoreProvider = Provider<MemberNotificationStore>(
  (ref) => MemberNotificationStore(),
);
