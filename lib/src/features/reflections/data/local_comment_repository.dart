import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';

import '../domain/comment.dart';
import 'comment_repository.dart';

/// In-memory, broadcast stream implementation of [CommentRepository] with
/// Firebase Cloud Firestore dual-redundancy and dev-mode isolation.
///
/// In production (`AppFlavor.prod`), starts with an empty store so only real
/// community discussions appear. Hardcoded sample threads are gated to dev mode.
///
/// When Firestore is available, [getComments] and [watchComments] also read
/// other members' comments from the `comments` (prod) or `comments_dev` (dev)
/// collection and merge them into the local store by id (#662).
class LocalCommentRepository implements CommentRepository {
  static final LocalCommentRepository instance = LocalCommentRepository();

  final List<Comment> _store = [];
  final StreamController<List<Comment>> _controller = StreamController<List<Comment>>.broadcast();
  final FirebaseFirestore? customFirestore;

  /// Whether this repository uses dev seed data and the `comments_dev` collection.
  final bool isDevMode;

  /// Optional override for the signed-in member's uid (used by tests).
  final String? Function()? currentUid;

  /// Firestore collection for comments. Dev builds never touch prod threads.
  String get collectionName => isDevMode ? 'comments_dev' : 'comments';

  static const Duration _firestoreTimeout = Duration(seconds: 2);

  String? get _authorUid {
    final override = currentUid;
    if (override != null) return override();
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  LocalCommentRepository({
    List<Comment>? initialComments,
    this.isDevMode = true,
    this.customFirestore,
    this.currentUid,
  }) {
    if (initialComments != null) {
      _store.addAll(initialComments);
    } else if (isDevMode) {
      _seedInitialData();
    }
  }

  void _seedInitialData() {
    final now = DateTime.now();

    _store.addAll([
      // Thread under Post 1 (David M. prayer request)
      Comment(
        id: 'c1_1',
        postId: '1',
        authorName: 'Pastor Thomas (Melbourne)',
        content: 'Praying for you David. Hebrews 4:10 reminds us that resting is entering His rest. Be gentle with your routine.',
        toneTag: '[Prayer]',
        timestamp: now.subtract(const Duration(minutes: 25)),
        reactions: {'pray': 4, 'peace': 3},
      ),
      Comment(
        id: 'c1_1_reply',
        postId: '1',
        parentCommentId: 'c1_1',
        authorName: 'David M. (UK)',
        content: 'Thank you Pastor Thomas, that verse brings a lot of reassurance today. Grateful for this quiet community.',
        toneTag: '[Comfort Only]',
        timestamp: now.subtract(const Duration(minutes: 15)),
        reactions: {'peace': 2},
      ),
      Comment(
        id: 'c1_2',
        postId: '1',
        authorName: 'Elena R. (Colorado)',
        content: 'Transitioning routines is so disorienting for autistic brains. Sending quiet prayers and holding space for you.',
        toneTag: '[Support]',
        timestamp: now.subtract(const Duration(minutes: 20)),
        reactions: {'pray': 2, 'peace': 4},
      ),

      // Thread under Post 4 (Nathan K. Church Acoustics Meme)
      Comment(
        id: 'c4_1',
        postId: '4',
        authorName: 'Caleb T. (Fort Worth)',
        content: 'The reverberation decay calculation is too real! Loop earplugs completely changed worship service for me.',
        toneTag: '[Relatable]',
        timestamp: now.subtract(const Duration(minutes: 10)),
        reactions: {'relatable': 6},
      ),
      Comment(
        id: 'c4_1_reply',
        postId: '4',
        parentCommentId: 'c4_1',
        authorName: 'Nathan K. (Texas)',
        content: 'Right?! Especially during the high-hat cymbal on the drum kit. Essential gear!',
        toneTag: '[Relatable]',
        timestamp: now.subtract(const Duration(minutes: 6)),
        reactions: {'relatable': 3},
      ),

      // Thread under Post 6 (Belong Organizer Welcome)
      Comment(
        id: 'c6_1',
        postId: '6',
        authorName: 'Hannah W. (Dallas)',
        content: 'So happy to be here. My special interest is sensory gardening and native Texas wildflowers!',
        toneTag: '[Welcome]',
        timestamp: now.subtract(const Duration(minutes: 7)),
        reactions: {'encouraged': 5},
      ),
    ]);
  }

  @override
  Future<List<Comment>> getComments({required String postId}) async {
    final fs = firestore;
    if (fs != null) {
      try {
        final snap = await _threadQuery(fs, postId).get().timeout(_firestoreTimeout);
        _mergeRemote(snap.docs.map((doc) => commentFromFirestore(doc.id, doc.data())));
      } catch (_) {
        // Offline, timed out, or denied: show the local thread only.
      }
    }
    return _getOrderedThread(postId);
  }

  Query<Map<String, dynamic>> _threadQuery(FirebaseFirestore fs, String postId) =>
      fs.collection(collectionName).where('postId', isEqualTo: postId);

  /// Merges remote comments into [_store] by id and notifies listeners when
  /// anything changed. Remote copies replace local ones so other members'
  /// reactions show up.
  void _mergeRemote(Iterable<Comment?> remote) {
    var changed = false;
    for (final comment in remote) {
      if (comment == null) continue;
      final index = _store.indexWhere((c) => c.id == comment.id);
      if (index == -1) {
        _store.add(comment);
        changed = true;
      } else if (!_sameComment(_store[index], comment)) {
        _store[index] = comment;
        changed = true;
      }
    }
    if (changed && !_controller.isClosed) {
      _controller.add(List.unmodifiable(_store));
    }
  }

  static bool _sameComment(Comment a, Comment b) {
    if (a != b) return false;
    if (a.reactions.length != b.reactions.length) return false;
    for (final entry in a.reactions.entries) {
      if (b.reactions[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  Future<Comment> addComment(Comment comment) async {
    _store.add(comment);
    _controller.add(List.unmodifiable(_store));

    // Dual-redundancy: dispatch to Firebase Cloud Firestore
    final fs = firestore;
    if (fs != null) {
      try {
        await fs
            .collection(collectionName)
            .doc(comment.id)
            .set(firestoreCommentData(comment, authorId: _authorUid))
            .timeout(_firestoreTimeout);
      } catch (_) {
        // Silent edge fallback ensures local UX never blocks
      }
    }

    return comment;
  }

  @override
  Future<int> deleteByAuthor({required String authorName}) async {
    final name = authorName.trim().toLowerCase();
    if (name.isEmpty) return 0;
    final before = _store.length;
    final removedIds = _store
        .where((comment) => comment.authorName.trim().toLowerCase() == name)
        .map((comment) => comment.id)
        .toList();
    _store.removeWhere((comment) => comment.authorName.trim().toLowerCase() == name);
    final removed = before - _store.length;
    if (removed > 0) {
      _controller.add(List.unmodifiable(_store));
    }
    final fs = firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection(collectionName)
            .where('authorName', isEqualTo: authorName)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
        for (final id in removedIds) {
          await fs.collection(collectionName).doc(id).delete();
        }
      } catch (_) {}
    }
    return removed;
  }

  @override
  Future<void> addReaction({required String commentId, required String reactionType}) async {
    final index = _store.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final existing = _store[index];
      final updatedReactions = Map<String, int>.from(existing.reactions);
      updatedReactions[reactionType] = (updatedReactions[reactionType] ?? 0) + 1;
      _store[index] = existing.copyWith(reactions: updatedReactions);
      _controller.add(List.unmodifiable(_store));

      final fs = firestore;
      if (fs != null) {
        try {
          await fs
              .collection(collectionName)
              .doc(commentId)
              .update({'reactions.$reactionType': FieldValue.increment(1)})
              .timeout(_firestoreTimeout);
        } catch (_) {
          // Silent edge fallback
        }
      }
    }
  }

  @override
  Stream<List<Comment>> watchComments({required String postId}) {
    StreamSubscription<List<Comment>>? localSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
    late final StreamController<List<Comment>> out;
    out = StreamController<List<Comment>>(
      onListen: () {
        out.add(_getOrderedThread(postId));
        localSub = _controller.stream.listen((_) {
          if (!out.isClosed) out.add(_getOrderedThread(postId));
        });
        final fs = firestore;
        if (fs != null) {
          try {
            remoteSub = _threadQuery(fs, postId).snapshots().listen(
              (snap) =>
                  _mergeRemote(snap.docs.map((doc) => commentFromFirestore(doc.id, doc.data()))),
              onError: (Object _) {
                // Offline or denied: keep the local thread.
              },
            );
          } catch (_) {
            // Firestore unavailable: keep the local thread.
          }
        }
      },
      onCancel: () async {
        await localSub?.cancel();
        await remoteSub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<int> getCommentCount({required String postId}) async =>
      _store.where((c) => c.postId == postId).length;

  @override
  Stream<int> watchCommentCount({required String postId}) =>
      watchComments(postId: postId).map((comments) => comments.length);

  @override
  Future<List<Comment>> getCommentsByAuthor({required String authorName}) async =>
      _store.where((c) => _matchesAuthor(c.authorName, authorName)).toList();

  @override
  Stream<List<Comment>> watchCommentsByAuthor({required String authorName}) {
    Stream<List<Comment>> generator() async* {
      yield _store.where((c) => _matchesAuthor(c.authorName, authorName)).toList();
      yield* _controller.stream.map(
        (comments) => comments.where((c) => _matchesAuthor(c.authorName, authorName)).toList(),
      );
    }

    return generator().asBroadcastStream();
  }

  static bool _matchesAuthor(String commentAuthor, String targetAuthor) {
    final a = commentAuthor.trim().toLowerCase();
    final b = targetAuthor.trim().toLowerCase();
    if (a == b) return true;
    final aFirst = a.split(RegExp(r'[\s(]')).first;
    final bFirst = b.split(RegExp(r'[\s(]')).first;
    if (aFirst.isNotEmpty && bFirst.isNotEmpty && aFirst == bFirst) return true;
    return a.contains(b) || b.contains(a);
  }

  /// Returns comments ordered hierarchically: top-level comments first,
  /// immediately followed by their child replies.
  List<Comment> _getOrderedThread(String postId) {
    final postComments = _store.where((c) => c.postId == postId).toList();
    final topLevel = postComments.where((c) => !c.isNested).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final result = <Comment>[];
    for (final parent in topLevel) {
      result.add(parent);
      final children = postComments.where((c) => c.parentCommentId == parent.id).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      result.addAll(children);
    }

    // Include any orphaned nested comments gracefully
    final orphaned = postComments.where(
      (c) => c.isNested && !result.any((item) => item.id == c.id),
    );
    result.addAll(orphaned);

    return result;
  }

  @override
  Future<Map<String, DateTime>> getLatestActivityTimestamps() async {
    final map = <String, DateTime>{};
    for (final c in _store) {
      final existing = map[c.postId];
      if (existing == null || c.timestamp.isAfter(existing)) {
        map[c.postId] = c.timestamp;
      }
    }
    return map;
  }

  @override
  Future<Map<String, int>> getAllCommentCounts() async {
    final map = <String, int>{};
    for (final c in _store) {
      map[c.postId] = (map[c.postId] ?? 0) + 1;
    }
    return map;
  }
}

/// Firestore document body for [comment]. [authorId] is the Firebase uid of
/// the member who wrote it, so security rules can limit edits and deletes to
/// the author (#662).
Map<String, dynamic> firestoreCommentData(Comment comment, {String? authorId}) => {
  'postId': comment.postId,
  if (comment.parentCommentId != null) 'parentCommentId': comment.parentCommentId,
  'authorName': comment.authorName,
  if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
  'content': comment.content,
  'toneTag': comment.toneTag,
  'timestamp': comment.timestamp.toIso8601String(),
  'reactions': comment.reactions,
};

/// Parses a Firestore comment document. Returns `null` when the document has
/// no `postId` or `content`, so malformed rows never reach the thread.
Comment? commentFromFirestore(String id, Map<String, dynamic> data) {
  final postId = data['postId'];
  final content = data['content'];
  if (postId is! String || postId.isEmpty || content is! String) return null;

  final rawTimestamp = data['timestamp'];
  final DateTime timestamp = switch (rawTimestamp) {
    Timestamp ts => ts.toDate(),
    String s => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0),
    int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    _ => DateTime.fromMillisecondsSinceEpoch(0),
  };

  final reactions = <String, int>{};
  final stored = data['reactions'];
  if (stored is Map) {
    for (final entry in stored.entries) {
      final count = entry.value;
      if (count is num) reactions[entry.key.toString()] = count.toInt();
    }
  }

  final parent = data['parentCommentId'];
  return Comment(
    id: id,
    postId: postId,
    parentCommentId: parent is String && parent.isNotEmpty ? parent : null,
    authorName: data['authorName'] as String? ?? 'Fellowship Member',
    content: content,
    toneTag: data['toneTag'] as String?,
    timestamp: timestamp,
    reactions: reactions,
  );
}
