import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';

import '../../../core/appwrite/appwrite_client_factory.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/logging/app_logger.dart';
import '../../admin/data/authored_document_erase.dart';
import '../domain/post.dart';
import 'care_reaction_marks.dart';
import 'local_account_scope.dart';
import 'local_post_repository.dart';
import 'pending_post_outbox.dart';
import 'post_repository.dart';

export 'post_merge.dart';

/// Cloud copy of a reflection feed. Production uses Appwrite TablesDB.
/// Tests supply an in-memory implementation so they never open a socket.
abstract class ReflectionMirror {
  Future<void> upsertPost(Post post);
  Future<void> incrementReaction({required String postId, required String column});
  Future<List<Post>> listPosts({required String spaceKey});
  Stream<Post> watchPosts({required String spaceKey});
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  });
}

/// Appwrite TablesDB mirror for reflections and quiet digests.
class AppwriteReflectionMirror implements ReflectionMirror {
  AppwriteReflectionMirror(this.services, this.config);

  final AppwriteServices services;
  final AppwriteConfig config;

  TablesDB get _tables => services.tables;

  @override
  Future<void> upsertPost(Post post) async {
    final rowId = appwriteRowId(post.id);
    final data = reflectionRowData(post);
    try {
      await _tables.updateRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: rowId,
        data: data,
      );
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;
      await _tables.createRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: rowId,
        data: data,
      );
    }
  }

  @override
  Future<void> incrementReaction({required String postId, required String column}) =>
      _tables.incrementRowColumn(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.reflectionTableId,
        rowId: appwriteRowId(postId),
        column: column,
        value: 1,
      );

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async {
    final rows = await _tables.listRows(
      databaseId: config.databaseId,
      tableId: AppwriteConfig.reflectionTableId,
      queries: [
        Query.equal('spaceKey', canonicalSpaceKey(spaceKey)),
        Query.orderDesc('createdAt'),
        Query.limit(100),
      ],
    );
    return [for (final row in rows.rows) ?_postFromRow(row)];
  }

  @override
  Stream<Post> watchPosts({required String spaceKey}) {
    final controller = StreamController<Post>();
    final channel = Channel.tablesdb(config.databaseId)
        .table(AppwriteConfig.reflectionTableId)
        .row();
    final subscription = services.realtime.subscribe([channel]);
    final wanted = canonicalSpaceKey(spaceKey);
    final listener = subscription.stream.listen((message) {
      final post = postFromAppwritePayload(message.payload);
      if (post != null && post.spaceKey == wanted && !controller.isClosed) {
        controller.add(post);
      }
    }, onError: controller.addError);
    controller.onCancel = () async {
      await listener.cancel();
      await subscription.close();
    };
    return controller.stream;
  }

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async {
    final canonical = canonicalSpaceKey(spaceKey);
    final rowId = appwriteRowId('digest-$canonical');
    final data = {
      'spaceKey': canonical,
      'summaryMessage': summary,
      'reflectionCount': reflectionCount,
      'affirmationCount': affirmationCount,
    };
    try {
      await _tables.updateRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.quietDigestTableId,
        rowId: rowId,
        data: data,
      );
    } on AppwriteException catch (error) {
      if (error.code != 404) rethrow;
      await _tables.createRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.quietDigestTableId,
        rowId: rowId,
        data: data,
      );
    }
  }

  Post? _postFromRow(models.Row row) => postFromAppwritePayload({...row.data, r'$id': row.$id});
}

/// Reflection store. Firestore is the live copy. Appwrite is the optional mirror.
///
/// Cloud Firestore is the live copy. The on-device list is what the screen
/// reads first, so a cloud timeout does not blank the feed. Appwrite
/// `reflection_posts` is not contacted unless a [ReflectionMirror] or
/// [AppwriteServices] is passed in. Sign-in stays on Firebase Auth.
enum CloudWrite { skipped, ok, failed }

class AppwritePostRepository implements PostRepository, AccountScopedCache {
  AppwritePostRepository({
    LocalPostRepository? fallback,
    this.customFirestore,
    ReflectionMirror? mirror,
    AppwriteServices? services,
    this.isDevMode = true,
    PendingPostOutbox? outbox,
  }) : _fallback = fallback ?? LocalPostRepository(isDevMode: isDevMode),
       _mirror = mirror ?? _mirrorFrom(services),
       _outbox =
           outbox ?? PendingPostOutbox(environment: reflectionEnvironment(isDevMode: isDevMode)),
       _marks = CareReactionMarks(environment: reflectionEnvironment(isDevMode: isDevMode));

  final LocalPostRepository _fallback;
  final FirebaseFirestore? customFirestore;
  final ReflectionMirror? _mirror;
  final PendingPostOutbox _outbox;
  final CareReactionMarks _marks;
  final bool isDevMode;
  bool _isLiveConnected = false;
  String? _adoptedAccount;
  bool _didAdopt = false;

  bool get isLiveConnected => _isLiveConnected;

  /// True when this repository will call the Appwrite reflection table.
  ///
  /// The default build leaves this false. Firestore is the live store.
  /// ADR-0011 keeps `reflection_posts` disabled, so the phone does not write it.
  bool get mirrorsReflections => _mirror != null;

  String get collectionName => isDevMode ? 'reflections_dev' : 'reflections';

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Firebase uid of the signed-in member, or `null` when Firebase is absent
  /// (widget tests) or nobody is signed in.
  String? get _authorUid {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static ReflectionMirror? _mirrorFrom(AppwriteServices? services) {
    // Do not open the live Appwrite project from the default build. The
    // reflection table is disabled (ADR-0011) and is not in the database the
    // phone can see. Callers that still want the spare copy pass [services].
    if (services == null) return null;
    return AppwriteReflectionMirror(services, AppwriteConfig.fromEnvironment);
  }

  /// Reloads private bookmarks and the pending outbox for [accountId].
  @override
  Future<void> adoptAccount(String? accountId) async {
    final normalized = accountId?.trim();
    final next = (normalized == null || normalized.isEmpty || normalized == 'guest')
        ? null
        : normalized;
    if (_didAdopt && _adoptedAccount == next) return;
    _didAdopt = true;
    _adoptedAccount = next;
    _outbox.adoptAccount(next);
    _fallback.dropPendingPosts();
    await _fallback.adoptAccount(next);
    await _flushPending();
  }

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    await _flushPending();
    final fsRows = <Post>[];
    var fsAuthoritative = false;
    final fs = firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection(collectionName)
            .where('spaceKey', isEqualTo: canonicalSpaceKey(spaceKey))
            .get()
            .timeout(const Duration(seconds: 2));
        fsRows.addAll(snap.docs.map((doc) => postFromFirestore(doc.id, doc.data(), spaceKey)));
        fsAuthoritative = true;
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Firestore reflection read failed');
      }
    }
    final mirrorRows = <Post>[];
    final mirror = _mirror;
    if (mirror != null) {
      try {
        mirrorRows.addAll(
          await mirror.listPosts(spaceKey: spaceKey).timeout(const Duration(seconds: 2)),
        );
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Appwrite reflection read failed');
      }
    }
    if (fsAuthoritative) {
      final pending = await _outbox.ids();
      _fallback.retainAuthoritativeSpace(
        spaceKey: spaceKey,
        cloudIds: {for (final post in fsRows) post.id},
        pendingIds: pending,
      );
      _fallback.absorbCloudPosts(fsRows);
      for (final post in fsRows) {
        await _outbox.remove(post.id);
      }
    } else if (mirrorRows.isNotEmpty) {
      _fallback.absorbCloudPosts(mirrorRows);
    }
    return _applySavedState(await _fallback.getPosts(spaceKey: spaceKey));
  }

  List<Post> _applySavedState(List<Post> posts) => [
    for (final post in posts)
      post.isSaved == _fallback.isPostSaved(post.id)
          ? post
          : post.copyWith(isSaved: _fallback.isPostSaved(post.id)),
  ];

  @override
  Future<Post> createPost(Post post) async {
    final authored = _withAuthor(post);
    final queued = await _outbox.enqueue(
      authored.copyWith(publishStatus: PostPublishStatus.pending),
    );
    final firestoreWrite = await _writeFirestore(authored);
    final appwriteWrite = await _writeAppwrite(authored);
    final status = publishStatusFor(
      queued: queued,
      firestoreWrite: firestoreWrite,
      appwriteWrite: appwriteWrite,
    );
    final saved = authored.copyWith(publishStatus: status);
    if (status == PostPublishStatus.failed) return saved;
    if (firestoreWrite == CloudWrite.ok || appwriteWrite == CloudWrite.ok) {
      await _outbox.remove(saved.id);
    }
    return _fallback.createPost(saved);
  }

  @override
  Future<void> addReaction({required String postId, required String reactionType}) =>
      toggleReaction(
        postId: postId,
        reactionType: reactionType,
        userId: 'current_user',
        displayName: 'Fellowship Member',
      );

  @override
  Future<void> toggleReaction({
    required String postId,
    required String reactionType,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final column = reactionColumn(reactionType);
    if (column == null) return;

    var before = _fallback.findPost(postId);
    if (before == null) {
      final loaded = await _readPostById(postId);
      if (loaded == null) return;
      _fallback.absorbCloudPosts([loaded]);
      before = _fallback.findPost(postId);
      if (before == null) return;
    }

    final marked = await _marks.contains(
      firestore: firestore,
      accountId: userId,
      postId: postId,
      type: reactionType,
    );
    final turningOff = before.hasMemberReacted(reactionType, userId) || marked;
    _fallback.setReactionActive(
      postId: postId,
      reactionType: reactionType,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      active: !turningOff,
    );

    void rollBack() => _fallback.setReactionActive(
      postId: postId,
      reactionType: reactionType,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      active: turningOff,
    );

    final fs = firestore;
    if (fs != null) {
      try {
        await _commitReactionCount(
          firestore: fs,
          postId: postId,
          reactionType: reactionType,
          column: column,
          delta: turningOff ? -1 : 1,
        );
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Firestore reaction write failed');
        rollBack();
        return;
      }
    }

    await _marks.record(
      firestore: fs,
      accountId: userId,
      postId: postId,
      type: reactionType,
      active: !turningOff,
    );

    // Spare copy only. A failure here must not undo a Firestore toggle, and a
    // toggle-off must not send another +1.
    final mirror = _mirror;
    if (mirror != null && !turningOff) {
      try {
        await mirror
            .incrementReaction(postId: postId, column: column)
            .timeout(const Duration(seconds: 2));
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Appwrite reaction mirror failed');
        if (fs == null) {
          rollBack();
          await _marks.record(
            firestore: fs,
            accountId: userId,
            postId: postId,
            type: reactionType,
            active: false,
          );
        }
      }
    }
  }

  Future<Post?> _readPostById(String postId) async {
    final fs = firestore;
    if (fs == null) return null;
    try {
      final snap = await fs
          .collection(collectionName)
          .doc(postId)
          .get()
          .timeout(const Duration(seconds: 2));
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return postFromFirestore(postId, data, data['spaceKey'] as String? ?? 'general_chat');
    } catch (_) {
      return null;
    }
  }

  /// Applies [delta] to the reaction map. A toggle-off reads the stored count
  /// first and does not write when that count is already zero, so the map
  /// cannot go negative. The summary column still only increases.
  Future<void> _commitReactionCount({
    required FirebaseFirestore firestore,
    required String postId,
    required String reactionType,
    required String column,
    required int delta,
  }) {
    final ref = firestore.collection(collectionName).doc(postId);
    return firestore
        .runTransaction((transaction) async {
          final snap = await transaction.get(ref);
          if (!snap.exists) {
            throw StateError('Reflection $postId is not in Firestore');
          }
          final current = _storedReactionCount(snap.data(), reactionType);
          if (delta < 0 && current <= 0) return;
          transaction.update(ref, firestoreReactionDelta(reactionType, column, delta));
        })
        .timeout(const Duration(seconds: 2));
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) {
    final controller = StreamController<List<Post>>.broadcast();
    final subscriptions = <StreamSubscription<dynamic>>[];
    var latest = <Post>[];
    var disposed = false;

    Future<void> emit(List<Post> next) async {
      latest = _applySavedState(next);
      if (!controller.isClosed) controller.add(latest);
    }

    controller.onListen = () async {
      await _flushPending();
      if (disposed) return;
      subscriptions.add(
        _fallback.watchPosts(spaceKey: spaceKey).listen((local) {
          emit(local);
        }),
      );

      final fs = firestore;
      if (fs != null) {
        subscriptions.add(
          fs
              .collection(collectionName)
              .where('spaceKey', isEqualTo: canonicalSpaceKey(spaceKey))
              .snapshots()
              .listen(
                (snap) async {
                  _isLiveConnected = true;
                  final cloudRows = snap.docs
                      .map((doc) => postFromFirestore(doc.id, doc.data(), spaceKey))
                      .toList();
                  final pending = await _outbox.ids();
                  _fallback.retainAuthoritativeSpace(
                    spaceKey: spaceKey,
                    cloudIds: {for (final post in cloudRows) post.id},
                    pendingIds: pending,
                  );
                  _fallback.absorbCloudPosts(cloudRows);
                  for (final post in cloudRows) {
                    await _outbox.remove(post.id);
                  }
                },
                onError: (Object error, StackTrace stack) {
                  talker.handle(error, stack, 'Firestore reflection watch failed');
                },
              ),
        );
      }

      final mirror = _mirror;
      if (mirror != null) {
        try {
          final rows = await mirror.listPosts(spaceKey: spaceKey);
          if (!disposed) {
            _isLiveConnected = true;
            // Appwrite list is additive. Firestore snapshots are what drop
            // deleted rows, because this mirror watch is not a full snapshot.
            _fallback.absorbCloudPosts(rows);
          }
        } catch (error, stack) {
          talker.handle(error, stack, 'Appwrite reflection list failed');
        }
        if (disposed) return;
        subscriptions.add(
          mirror
              .watchPosts(spaceKey: spaceKey)
              .listen(
                (post) {
                  _isLiveConnected = true;
                  _fallback.absorbCloudPosts([post]);
                },
                onError: (Object error, StackTrace stack) {
                  talker.handle(error, stack, 'Appwrite reflection watch failed');
                },
              ),
        );
      }
    };

    controller.onCancel = () async {
      disposed = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    };
    return controller.stream;
  }

  @override
  Future<String?> getQuietDigest({required String spaceKey}) async {
    if (canonicalSpaceKey(spaceKey) == 'saved_for_later') {
      return _fallback.getQuietDigest(spaceKey: 'saved_for_later');
    }
    final posts = await getPosts(spaceKey: spaceKey);
    if (posts.isEmpty) {
      return 'A quiet, unhurried space awaiting the first community reflection.';
    }
    final affirmations = posts.fold<int>(
      0,
      (total, post) => total + post.reactions.values.fold<int>(0, (inner, value) => inner + value),
    );
    final summary =
        'Gathered in peace • ${posts.length} reflections shared with $affirmations care affirmations.';
    try {
      await _mirror
          ?.upsertDigest(
            spaceKey: spaceKey,
            summary: summary,
            reflectionCount: posts.length,
            affirmationCount: affirmations,
          )
          .timeout(const Duration(seconds: 2));
    } catch (error, stack) {
      talker.handle(error, stack, 'Appwrite quiet digest mirror failed');
    }
    return summary;
  }

  @override
  Future<List<Post>> getPostsByAuthor({required String authorName}) =>
      _fallback.getPostsByAuthor(authorName: authorName);

  @override
  Stream<List<Post>> watchPostsByAuthor({required String authorName}) =>
      _fallback.watchPostsByAuthor(authorName: authorName);

  @override
  Future<void> toggleSavePost({required String postId}) => _fallback.toggleSavePost(postId: postId);

  @override
  Future<List<Post>> getSavedPosts() => _fallback.getSavedPosts();

  @override
  Stream<List<Post>> watchSavedPosts() => _fallback.watchSavedPosts();

  Future<CloudWrite> _writeFirestore(Post post) async {
    final fs = firestore;
    if (fs == null) return CloudWrite.skipped;
    try {
      await fs
          .collection(collectionName)
          .doc(post.id)
          .set(firestoreReflectionData(post, authorId: post.authorId ?? _authorUid))
          .timeout(const Duration(seconds: 2));
      _isLiveConnected = true;
      return CloudWrite.ok;
    } catch (error, stack) {
      talker.handle(error, stack, 'Firestore reflection mirror failed');
      return CloudWrite.failed;
    }
  }

  @override
  Future<int> deleteByAuthor({required String authorName, String? authorId}) async {
    final removed = await _fallback.deleteByAuthor(authorName: authorName, authorId: authorId);
    final uid = authorId?.trim() ?? '';
    final name = authorName.trim().toLowerCase();
    await _outbox.removeWhere((post) {
      if (uid.isNotEmpty && post.authorId == uid) return true;
      return name.isNotEmpty && post.authorName.trim().toLowerCase() == name;
    });
    final fs = firestore;
    if (fs != null && (authorName.trim().isNotEmpty || uid.isNotEmpty)) {
      try {
        await deleteAuthoredDocuments(
          collection: fs.collection(collectionName),
          authorName: authorName,
          authorId: authorId,
        );
      } catch (error, stack) {
        talker.handle(error, stack, 'Firestore ban erase failed');
        rethrow;
      }
    }
    return removed;
  }

  Future<CloudWrite> _writeAppwrite(Post post) async {
    final mirror = _mirror;
    if (mirror == null) return CloudWrite.skipped;
    try {
      await mirror.upsertPost(post).timeout(const Duration(seconds: 2));
      _isLiveConnected = true;
      return CloudWrite.ok;
    } catch (error, stack) {
      talker.handle(error, stack, 'Appwrite reflection mirror failed');
      return CloudWrite.failed;
    }
  }

  Post _withAuthor(Post post) {
    if (post.authorId != null && post.authorId!.isNotEmpty) return post;
    final uid = _authorUid;
    if (uid == null || uid.isEmpty) return post;
    return post.copyWith(authorId: uid);
  }

  Future<void> _flushPending() async {
    final pending = await _outbox.readAll();
    for (final post in pending) {
      final firestoreWrite = await _writeFirestore(post);
      final appwriteWrite = await _writeAppwrite(post);
      final status = publishStatusFor(
        queued: true,
        firestoreWrite: firestoreWrite,
        appwriteWrite: appwriteWrite,
      );
      if (firestoreWrite == CloudWrite.ok || appwriteWrite == CloudWrite.ok) {
        await _outbox.remove(post.id);
      }
      if (status == PostPublishStatus.failed) continue;
      _fallback.upsertLocal(post.copyWith(publishStatus: status));
    }
  }
}

/// Decides whether a reflection is confirmed, still waiting, or not durable.
PostPublishStatus publishStatusFor({
  required bool queued,
  required CloudWrite firestoreWrite,
  required CloudWrite appwriteWrite,
}) {
  final attempted = firestoreWrite != CloudWrite.skipped || appwriteWrite != CloudWrite.skipped;
  final confirmed = firestoreWrite == CloudWrite.ok || appwriteWrite == CloudWrite.ok;
  if (confirmed) return PostPublishStatus.confirmed;
  if (!attempted && queued) return PostPublishStatus.confirmed;
  if (queued) return PostPublishStatus.pending;
  return PostPublishStatus.failed;
}

/// Appwrite row ids allow letters, numbers, period, hyphen, and underscore.
String appwriteRowId(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  if (cleaned.isEmpty) return 'row';
  final body = RegExp(r'^[A-Za-z0-9]').hasMatch(cleaned) ? cleaned : 'r$cleaned';
  return body.length <= 36 ? body : body.substring(0, 36);
}

String canonicalSpaceKey(String key) {
  final clean = key.trim().toLowerCase();
  if (clean.isEmpty) return 'general_chat';
  return clean;
}

String? reactionColumn(String reactionType) => switch (reactionType) {
  'pray' => 'prayingCount',
  'standing' => 'standingWithCount',
  'peace' => 'peaceCount',
  'encouraged' || 'relatable' => 'encouragedCount',
  _ => null,
};

Map<String, dynamic> reflectionRowData(Post post) => {
  'authorName': post.authorName,
  'spaceKey': canonicalSpaceKey(post.spaceKey),
  'intentTag': post.toneTag.isEmpty ? '[Support]' : post.toneTag,
  if (post.specialInterestTag != null && post.specialInterestTag!.isNotEmpty)
    'specialInterestTag': post.specialInterestTag,
  if (post.imageUrl != null && post.imageUrl!.isNotEmpty) 'imageUrl': post.imageUrl,
  'content': post.content,
  'createdAt': post.timestamp.toUtc().toIso8601String(),
  'prayingCount': post.reactions['pray'] ?? 0,
  'standingWithCount': post.reactions['standing'] ?? 0,
  'peaceCount': post.reactions['peace'] ?? 0,
  'encouragedCount': post.reactions['encouraged'] ?? post.reactions['relatable'] ?? 0,
  'isDemo': post.isDemo,
};

Map<String, dynamic> firestoreReflectionData(Post post, {String? authorId}) => {
  ...reflectionRowData(post),
  if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
  'toneTag': post.toneTag,
  'timestamp': post.timestamp.toIso8601String(),
  'reactions': post.reactions,
};

/// Firestore merge payload for one care reaction. Bumps both the summary
/// column (for Appwrite parity) and the `reactions` map that
/// [postFromFirestore] prefers, so every member sees the new count (#662).
Map<String, dynamic> firestoreReactionIncrement(String reactionType, String column) => {
  column: FieldValue.increment(1),
  'reactions': {reactionType: FieldValue.increment(1)},
};

/// Update payload for a toggle. [delta] is `1` when the member turns the
/// reaction on and `-1` when they turn it off.
///
/// The reactions map is what the feed displays. Rules allow that map to move
/// in either direction. The summary column only increases, because the live
/// rules reject a lower column value. A toggle-off therefore leaves the
/// column where it is and corrects the map.
Map<String, dynamic> firestoreReactionDelta(String reactionType, String column, int delta) => {
  'reactions.$reactionType': FieldValue.increment(delta),
  if (delta > 0) column: FieldValue.increment(delta),
};

int _storedReactionCount(Map<String, dynamic>? data, String reactionType) {
  final stored = data?['reactions'];
  if (stored is Map) {
    final value = stored[reactionType];
    if (value is num) return value.toInt();
  }
  return 0;
}

Post postFromFirestore(String id, Map<String, dynamic> data, String spaceKey) {
  final reactions = <String, int>{};
  final stored = data['reactions'];
  if (stored is Map) {
    for (final entry in stored.entries) {
      final count = entry.value;
      if (count is num) reactions[entry.key.toString()] = count.toInt();
    }
  }
  void fill(String key, String field) {
    final value = data[field];
    if (value is num && !reactions.containsKey(key)) {
      reactions[key] = value.toInt();
    }
  }

  fill('pray', 'prayingCount');
  fill('standing', 'standingWithCount');
  fill('peace', 'peaceCount');
  // encouragedCount is shared by Encouraged and Relate. Once the reactions
  // map names one of them, copying the column onto the other invents a count
  // whose who-reacted list is empty.
  if (!reactions.containsKey('encouraged') && !reactions.containsKey('relatable')) {
    fill('encouraged', 'encouragedCount');
  }
  return Post(
    id: id,
    authorName: data['authorName'] as String? ?? 'Fellowship Member',
    spaceKey: data['spaceKey'] as String? ?? canonicalSpaceKey(spaceKey),
    toneTag: data['toneTag'] as String? ?? data['intentTag'] as String? ?? '[Support]',
    specialInterestTag: data['specialInterestTag'] as String?,
    imageUrl: data['imageUrl'] as String?,
    content: data['content'] as String? ?? '',
    timestamp:
        DateTime.tryParse(data['createdAt'] as String? ?? data['timestamp'] as String? ?? '') ??
        DateTime.now(),
    reactions: reactions,
    isDemo: data['isDemo'] as bool? ?? false,
    authorId: data['authorId'] as String?,
  );
}

Post? postFromAppwritePayload(Map<String, dynamic> payload) {
  final nested = payload['data'];
  final data = <String, dynamic>{
    ...payload,
    if (nested is Map) ...Map<String, dynamic>.from(nested),
  };
  final id = (data[r'$id'] ?? data['id'])?.toString();
  final content = data['content'];
  if (id == null || id.isEmpty || content is! String) return null;
  final encouraged = (data['encouragedCount'] as num?)?.toInt() ?? 0;
  return Post(
    id: id,
    authorName: data['authorName'] as String? ?? 'Fellowship Member',
    spaceKey: data['spaceKey'] as String? ?? 'general_chat',
    toneTag: data['intentTag'] as String? ?? '[Support]',
    specialInterestTag: data['specialInterestTag'] as String?,
    imageUrl: data['imageUrl'] as String?,
    content: content,
    timestamp: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
    reactions: {
      'pray': (data['prayingCount'] as num?)?.toInt() ?? 0,
      'standing': (data['standingWithCount'] as num?)?.toInt() ?? 0,
      'peace': (data['peaceCount'] as num?)?.toInt() ?? 0,
      'encouraged': encouraged,
      'relatable': encouraged,
    },
    isDemo: data['isDemo'] as bool? ?? false,
  );
}
