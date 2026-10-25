import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:firebase_core/firebase_core.dart';

import '../../../core/appwrite/appwrite_client_factory.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/post.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';

/// Cloud copy of a reflection feed. Production uses Appwrite TablesDB.
/// Tests supply an in-memory implementation so they never open a socket.
abstract class ReflectionMirror {
  Future<void> upsertPost(Post post);
  Future<void> incrementReaction({
    required String postId,
    required String column,
  });
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
  Future<void> incrementReaction({
    required String postId,
    required String column,
  }) {
    return _tables.incrementRowColumn(
      databaseId: config.databaseId,
      tableId: AppwriteConfig.reflectionTableId,
      rowId: appwriteRowId(postId),
      column: column,
      value: 1,
    );
  }

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

  Post? _postFromRow(models.Row row) {
    return postFromAppwritePayload({...row.data, r'$id': row.$id});
  }
}

/// Reflection store that replaces Serverpod Cloud.
///
/// Each write goes to Appwrite and Cloud Firestore. The local cache is what
/// the screen reads first, so a cloud timeout never blanks the feed. Sign-in
/// stays on Firebase Auth.
class AppwritePostRepository implements PostRepository {
  AppwritePostRepository({
    LocalPostRepository? fallback,
    this.customFirestore,
    ReflectionMirror? mirror,
    AppwriteServices? services,
    this.isDevMode = true,
  }) : _fallback = fallback ?? LocalPostRepository(isDevMode: isDevMode),
       _mirror = mirror ?? _mirrorFrom(services);

  final LocalPostRepository _fallback;
  final FirebaseFirestore? customFirestore;
  final ReflectionMirror? _mirror;
  final bool isDevMode;
  bool _isLiveConnected = false;

  bool get isLiveConnected => _isLiveConnected;

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

  static ReflectionMirror? _mirrorFrom(AppwriteServices? services) {
    final resolved =
        services ?? createAppwriteServices(AppwriteConfig.fromEnvironment);
    if (resolved == null) return null;
    return AppwriteReflectionMirror(resolved, AppwriteConfig.fromEnvironment);
  }

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    final local = await _fallback.getPosts(spaceKey: spaceKey);
    final cloud = <Post>[];
    final fs = firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection(collectionName)
            .where('spaceKey', isEqualTo: canonicalSpaceKey(spaceKey))
            .get()
            .timeout(const Duration(seconds: 2));
        cloud.addAll(
          snap.docs.map(
            (doc) => postFromFirestore(doc.id, doc.data(), spaceKey),
          ),
        );
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Firestore reflection read failed');
      }
    }
    final mirror = _mirror;
    if (mirror != null) {
      try {
        cloud.addAll(
          await mirror
              .listPosts(spaceKey: spaceKey)
              .timeout(const Duration(seconds: 2)),
        );
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Appwrite reflection read failed');
      }
    }
    if (cloud.isEmpty) return local;
    return mergePosts(local, cloud);
  }

  @override
  Future<Post> createPost(Post post) async {
    final saved = await _fallback.createPost(post);
    await _writeFirestore(saved);
    await _writeAppwrite(saved);
    return saved;
  }

  @override
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  }) async {
    await _fallback.addReaction(postId: postId, reactionType: reactionType);
    final column = reactionColumn(reactionType);
    final fs = firestore;
    if (fs != null && column != null) {
      try {
        await fs
            .collection(collectionName)
            .doc(postId)
            .set({column: FieldValue.increment(1)}, SetOptions(merge: true))
            .timeout(const Duration(seconds: 2));
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Firestore reaction mirror failed');
      }
    }
    final mirror = _mirror;
    if (mirror != null && column != null) {
      try {
        await mirror
            .incrementReaction(postId: postId, column: column)
            .timeout(const Duration(seconds: 2));
        _isLiveConnected = true;
      } catch (error, stack) {
        talker.handle(error, stack, 'Appwrite reaction mirror failed');
      }
    }
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) {
    final controller = StreamController<List<Post>>.broadcast();
    final subscriptions = <StreamSubscription<dynamic>>[];
    var latest = <Post>[];
    var disposed = false;

    Future<void> emit(List<Post> next) async {
      latest = next;
      if (!controller.isClosed) controller.add(latest);
    }

    controller.onListen = () async {
      latest = await _fallback.getPosts(spaceKey: spaceKey);
      if (disposed) return;
      await emit(List<Post>.from(latest));

      subscriptions.add(
        _fallback.watchPosts(spaceKey: spaceKey).listen((local) {
          emit(mergePosts(local, latest));
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
                (snap) {
                  _isLiveConnected = true;
                  emit(
                    mergePosts(
                      latest,
                      snap.docs
                          .map(
                            (doc) =>
                                postFromFirestore(doc.id, doc.data(), spaceKey),
                          )
                          .toList(),
                    ),
                  );
                },
                onError: (Object error, StackTrace stack) {
                  talker.handle(
                    error,
                    stack,
                    'Firestore reflection watch failed',
                  );
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
            await emit(mergePosts(latest, rows));
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
                  emit(mergePosts(latest, [post]));
                },
                onError: (Object error, StackTrace stack) {
                  talker.handle(
                    error,
                    stack,
                    'Appwrite reflection watch failed',
                  );
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
    final posts = await getPosts(spaceKey: spaceKey);
    if (posts.isEmpty) {
      return 'A quiet, unhurried space awaiting the first community reflection.';
    }
    final affirmations = posts.fold<int>(
      0,
      (total, post) =>
          total +
          post.reactions.values.fold<int>(0, (inner, value) => inner + value),
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
  Future<void> toggleSavePost({required String postId}) =>
      _fallback.toggleSavePost(postId: postId);

  @override
  Future<List<Post>> getSavedPosts() => _fallback.getSavedPosts();

  @override
  Stream<List<Post>> watchSavedPosts() => _fallback.watchSavedPosts();

  Future<void> _writeFirestore(Post post) async {
    final fs = firestore;
    if (fs == null) return;
    try {
      await fs
          .collection(collectionName)
          .doc(post.id)
          .set(firestoreReflectionData(post))
          .timeout(const Duration(seconds: 2));
      _isLiveConnected = true;
    } catch (error, stack) {
      talker.handle(error, stack, 'Firestore reflection mirror failed');
    }
  }

  @override
  Future<int> deleteByAuthor({required String authorName}) async {
    final removed = await _fallback.deleteByAuthor(authorName: authorName);
    final fs = firestore;
    if (fs != null && authorName.trim().isNotEmpty) {
      try {
        final snap = await fs
            .collection(collectionName)
            .where('authorName', isEqualTo: authorName)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
    return removed;
  }

  Future<void> _writeAppwrite(Post post) async {
    final mirror = _mirror;
    if (mirror == null) return;
    try {
      await mirror.upsertPost(post).timeout(const Duration(seconds: 2));
      _isLiveConnected = true;
    } catch (error, stack) {
      talker.handle(error, stack, 'Appwrite reflection mirror failed');
    }
  }
}

/// Appwrite row ids allow letters, numbers, period, hyphen, and underscore.
String appwriteRowId(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  if (cleaned.isEmpty) return 'row';
  final body = RegExp(r'^[A-Za-z0-9]').hasMatch(cleaned)
      ? cleaned
      : 'r$cleaned';
  return body.length <= 36 ? body : body.substring(0, 36);
}

String canonicalSpaceKey(String key) {
  final clean = key.trim().toLowerCase();
  if (clean.isEmpty) return 'general_chat';
  return clean;
}

String? reactionColumn(String reactionType) {
  return switch (reactionType) {
    'pray' => 'prayingCount',
    'standing' => 'standingWithCount',
    'peace' => 'peaceCount',
    'encouraged' || 'relatable' => 'encouragedCount',
    _ => null,
  };
}

Map<String, dynamic> reflectionRowData(Post post) {
  return {
    'authorName': post.authorName,
    'spaceKey': canonicalSpaceKey(post.spaceKey),
    'intentTag': post.toneTag.isEmpty ? '[Support]' : post.toneTag,
    if (post.specialInterestTag != null && post.specialInterestTag!.isNotEmpty)
      'specialInterestTag': post.specialInterestTag,
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
      'imageUrl': post.imageUrl,
    'content': post.content,
    'createdAt': post.timestamp.toUtc().toIso8601String(),
    'prayingCount': post.reactions['pray'] ?? 0,
    'standingWithCount': post.reactions['standing'] ?? 0,
    'peaceCount': post.reactions['peace'] ?? 0,
    'encouragedCount':
        post.reactions['encouraged'] ?? post.reactions['relatable'] ?? 0,
    'isDemo': post.isDemo,
  };
}

Map<String, dynamic> firestoreReflectionData(Post post) {
  return {
    ...reflectionRowData(post),
    'toneTag': post.toneTag,
    'timestamp': post.timestamp.toIso8601String(),
    'reactions': post.reactions,
  };
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
  fill('encouraged', 'encouragedCount');
  return Post(
    id: id,
    authorName: data['authorName'] as String? ?? 'Fellowship Member',
    spaceKey: data['spaceKey'] as String? ?? canonicalSpaceKey(spaceKey),
    toneTag:
        data['toneTag'] as String? ??
        data['intentTag'] as String? ??
        '[Support]',
    specialInterestTag: data['specialInterestTag'] as String?,
    imageUrl: data['imageUrl'] as String?,
    content: data['content'] as String? ?? '',
    timestamp:
        DateTime.tryParse(
          data['createdAt'] as String? ?? data['timestamp'] as String? ?? '',
        ) ??
        DateTime.now(),
    reactions: reactions,
    isDemo: data['isDemo'] as bool? ?? false,
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
    timestamp:
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
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

List<Post> mergePosts(List<Post> base, List<Post> overlay) {
  final byId = <String, Post>{for (final post in base) post.id: post};
  for (final post in overlay) {
    final existing = byId[post.id];
    byId[post.id] = existing == null ? post : preferPost(existing, post);
  }
  final merged = byId.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return merged;
}

/// Keeps the newer reflection. Equal timestamps keep the copy with more care
/// affirmations, so a local tap is not overwritten by a stale cloud row.
Post preferPost(Post current, Post incoming) {
  if (incoming.timestamp.isAfter(current.timestamp)) return incoming;
  if (current.timestamp.isAfter(incoming.timestamp)) return current;
  final currentScore = current.reactions.values.fold<int>(
    0,
    (total, value) => total + value,
  );
  final incomingScore = incoming.reactions.values.fold<int>(
    0,
    (total, value) => total + value,
  );
  return incomingScore >= currentScore ? incoming : current;
}
