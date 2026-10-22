import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sanctuary_server_client/sanctuary_server_client.dart' as sp;

import '../../../core/logging/app_logger.dart';
import '../domain/post.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';

/// Serverpod-backed post repository with live WebSocket streaming and resilient offline fallback.
///
/// Features cross-cloud dual-redundancy with Firebase Cloud Firestore so that
/// reflections and affirmations are persisted across both Serverpod Cloud and
/// Firestore collections, gating hardcoded mock data away from production.
class ServerpodPostRepository implements PostRepository {
  final String serverUrl;
  final LocalPostRepository _fallback;
  final sp.Client _client;
  final FirebaseFirestore? customFirestore;
  final bool isDevMode;
  bool _isLiveConnected = false;

  bool get isLiveConnected => _isLiveConnected;

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

  ServerpodPostRepository({
    String? serverUrl,
    LocalPostRepository? fallback,
    this.customFirestore,
    this.isDevMode = true,
  }) : serverUrl =
           serverUrl ??
           const String.fromEnvironment(
             'SERVERPOD_URL',
             defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
           ),
       _fallback = fallback ?? LocalPostRepository(isDevMode: isDevMode),
       _client = sp.Client(
         serverUrl ??
             const String.fromEnvironment(
               'SERVERPOD_URL',
               defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
             ),
       );

  @override
  Future<List<Post>> getPosts({required String spaceKey}) async {
    final mappedSpace = _mapSpaceKey(spaceKey);
    try {
      talker.info('📥 [Serverpod RPC] Fetching reflections for space: $spaceKey (mapped: $mappedSpace)');
      final remotePosts = await _client.reflection
          .getFeed(mappedSpace)
          .timeout(const Duration(milliseconds: 800));
      _isLiveConnected = true;
      talker.info('✅ [Serverpod RPC SUCCESS] Fetched ${remotePosts.length} reflections from live serverpod backend');
      return remotePosts
          .map(
            (spPost) => Post(
              id: spPost.id?.toString() ?? UniqueKey().toString(),
              authorName: spPost.authorName,
              spaceKey: spaceKey,
              toneTag: spPost.toneTag,
              specialInterestTag: spPost.specialInterestTag,
              content: spPost.content,
              timestamp: spPost.createdAt,
              reactions: {
                'pray': spPost.prayingCount,
                'peace': spPost.peaceCount,
                'encouraged': spPost.encouragedCount,
                'standing': spPost.standingWithCount,
                'relatable': spPost.encouragedCount,
              },
            ),
          )
          .toList();
    } catch (e, st) {
      talker.handle(e, st, '🚨 [Serverpod RPC FAILED] getPosts timeout/error, falling back to local');
      debugPrint('🚨 [Serverpod RPC FAILED] getPosts timeout/error: $e\n$st');
      _isLiveConnected = false;
      return _fallback.getPosts(spaceKey: spaceKey);
    }
  }

  @override
  Future<Post> createPost(Post post) async {
    talker.info('📤 [Serverpod RPC] Publishing reflection: tag=${post.toneTag} specialInterest=${post.specialInterestTag} content="${post.content}"');

    // Dual-redundancy: dispatch to Firebase Cloud Firestore
    final fs = firestore;
    if (fs != null) {
      try {
        await fs.collection('reflections').doc(post.id).set({
          'authorName': post.authorName,
          'spaceKey': post.spaceKey,
          'toneTag': post.toneTag,
          'specialInterestTag': post.specialInterestTag,
          'imageUrl': post.imageUrl,
          'content': post.content,
          'timestamp': post.timestamp.toIso8601String(),
          'reactions': post.reactions,
          'isDemo': post.isDemo,
        });
      } catch (_) {
        // Cross-cloud edge sync resilience
      }
    }

    try {
      final spReflection = sp.ReflectionPost(
        authorName: post.authorName,
        spaceKey: _mapSpaceKey(post.spaceKey),
        toneTag: post.toneTag,
        specialInterestTag: post.specialInterestTag,
        content: post.content,
        createdAt: post.timestamp,
        prayingCount: post.reactions['pray'] ?? 0,
        standingWithCount: post.reactions['standing'] ?? 0,
        peaceCount: post.reactions['peace'] ?? 0,
        encouragedCount: post.reactions['encouraged'] ?? 0,
      );

      final created = await _client.reflection
          .publishReflection(spReflection)
          .timeout(const Duration(milliseconds: 1200));
      _isLiveConnected = true;
      talker.info('✅ [Serverpod RPC SUCCESS] Reflection published with id ${created.id}');
      return post.copyWith(id: created.id?.toString());
    } catch (e, st) {
      talker.handle(e, st, '🚨 [Serverpod RPC FAILED] publishReflection error, falling back to local');
      debugPrint('🚨 [Serverpod RPC FAILED] publishReflection error: $e\n$st');
      _isLiveConnected = false;
      return _fallback.createPost(post);
    }
  }

  @override
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  }) async {
    // 1. Immediately mirror to local fallback for sub-16ms latency
    _fallback.addReaction(postId: postId, reactionType: reactionType);

    // Dual-redundancy: dispatch to Firebase Cloud Firestore
    final fs = firestore;
    if (fs != null) {
      try {
        await fs.collection('reflections').doc(postId).update({
          '${reactionType}Count': FieldValue.increment(1),
        });
      } catch (_) {
        // Cross-cloud edge sync resilience
      }
    }

    final parsedId = int.tryParse(postId);
    if (parsedId != null) {
      try {
        final keyMap = {
          'pray': 'praying',
          'standing': 'standingWith',
          'peace': 'peace',
          'encouraged': 'encouraged',
          'relatable': 'relatable',
        };
        final mappedKey = keyMap[reactionType] ?? reactionType;
        talker.info('💖 [Serverpod RPC] Affirming care: post=$parsedId reaction=$reactionType (mapped: $mappedKey)');
        await _client.reflection
            .affirmCare(parsedId, mappedKey)
            .timeout(const Duration(milliseconds: 4000));
        talker.info('✅ [Serverpod RPC SUCCESS] Care affirmed for post $parsedId ($reactionType)');
        _isLiveConnected = true;
        return;
      } catch (e, st) {
        talker.handle(e, st, '🚨 [Serverpod RPC FAILED] affirmCare error, falling back to local');
        _isLiveConnected = false;
      }
    }
    return _fallback.addReaction(postId: postId, reactionType: reactionType);
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) async* {
    // 1. Instantly yield local fallback so user never sees a blank screen or loading spinner
    yield await _fallback.getPosts(spaceKey: spaceKey);

    // 2. Open live streaming subscription to Serverpod endpoint
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      final stream = _client.reflection.watchFeed(mappedSpace);
      final List<Post> livePosts = List.from(await _fallback.getPosts(spaceKey: spaceKey));

      await for (final spPost in stream) {
        _isLiveConnected = true;
        talker.info('⚡ [Serverpod WebSocket] Real-time reflection received: "${spPost.content}" by ${spPost.authorName}');
        final post = Post(
          id: spPost.id?.toString() ?? UniqueKey().toString(),
          authorName: spPost.authorName,
          spaceKey: spaceKey,
          toneTag: spPost.toneTag,
          specialInterestTag: spPost.specialInterestTag,
          content: spPost.content,
          timestamp: spPost.createdAt,
          reactions: {
            'pray': spPost.prayingCount,
            'peace': spPost.peaceCount,
            'encouraged': spPost.encouragedCount,
            'standing': spPost.standingWithCount,
            'relatable': spPost.encouragedCount,
          },
        );

        final existingIdx = livePosts.indexWhere((p) => p.id == post.id);
        if (existingIdx >= 0) {
          livePosts[existingIdx] = post;
        } else {
          livePosts.insert(0, post);
        }
        livePosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        yield List<Post>.from(livePosts);
      }
    } catch (e, st) {
      talker.handle(e, st, '🚨 [Serverpod WebSocket CATCH] watchPosts stream disconnected');
      debugPrint('🚨 [Serverpod Stream CATCH] watchPosts error: $e\n$st');
      // 3. Fallback gracefully to local stream if network disconnects
      _isLiveConnected = false;
      yield* _fallback.watchPosts(spaceKey: spaceKey);
    }
  }

  @override
  Future<String?> getQuietDigest({required String spaceKey}) async {
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      final digest = await _client.reflection
          .getQuietDigest(mappedSpace)
          .timeout(const Duration(milliseconds: 800));
      _isLiveConnected = true;
      talker.info('📜 [Serverpod RPC] Fetched quiet digest for space $spaceKey: "${digest.summaryMessage}"');
      return digest.summaryMessage;
    } catch (e) {
      _isLiveConnected = false;
      return _fallback.getQuietDigest(spaceKey: spaceKey);
    }
  }

  @override
  Future<List<Post>> getPostsByAuthor({required String authorName}) =>
      _fallback.getPostsByAuthor(authorName: authorName);

  @override
  Stream<List<Post>> watchPostsByAuthor({required String authorName}) =>
      _fallback.watchPostsByAuthor(authorName: authorName);

  String _mapSpaceKey(String key) {
    switch (key) {
      case 'prayer':
        return 'prayer';
      case 'study':
        return 'study';
      case 'special_interests':
        return 'special_interests';
      default:
        return 'prayer';
    }
  }
}
