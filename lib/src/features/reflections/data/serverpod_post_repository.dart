import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sanctuary_server_client/sanctuary_server_client.dart' as sp;

import '../../../core/logging/app_logger.dart';
import '../domain/post.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';

/// Serverpod-backed post repository with live WebSocket streaming and resilient offline fallback.
class ServerpodPostRepository implements PostRepository {
  final String serverUrl;
  final LocalPostRepository _fallback;
  final sp.Client _client;
  bool _isLiveConnected = false;

  bool get isLiveConnected => _isLiveConnected;

  ServerpodPostRepository({String? serverUrl, LocalPostRepository? fallback})
    : serverUrl =
          serverUrl ??
          const String.fromEnvironment(
            'SERVERPOD_URL',
            defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
          ),
      _fallback = fallback ?? LocalPostRepository(),
      _client = sp.Client(
        serverUrl ??
            const String.fromEnvironment(
              'SERVERPOD_URL',
              defaultValue: 'https://refuge4serverpod.api.serverpod.space/',
            ),
        onFailedCall: (context, error, stackTrace) {
          talker.handle(error, stackTrace, 'Serverpod RPC ${context.endpointName}.${context.methodName} FAILED');
          debugPrint(
            '🚨 [Serverpod RPC FAILED] ${context.endpointName}.${context.methodName}: $error',
          );
        },
        onSucceededCall: (context) {
          talker.info('Serverpod RPC ${context.endpointName}.${context.methodName} SUCCESS');
          debugPrint('✅ [Serverpod RPC SUCCESS] ${context.endpointName}.${context.methodName}');
        },
      );

  String _mapSpaceKey(String key) => switch (key) {
    'prayer' => 'prayer_care',
    'study' => 'bible_study',
    'special_interests' => 'special_interests',
    'general' => 'main_hall',
    'announcements' => 'quiet_room',
    _ => key,
  };

  @override
  Future<List<Post>> getPosts({required String spaceKey}) => _fallback.getPosts(spaceKey: spaceKey);

  @override
  Future<Post> createPost(Post post) async {
    talker.info('📤 [Serverpod RPC] Publishing reflection: tag=[${post.toneTag}] specialInterest=[${post.specialInterestTag}] content="${post.content}"');
    try {
      final spPost = sp.ReflectionPost(
        authorName: post.authorName,
        spaceKey: _mapSpaceKey(post.spaceKey),
        intentTag: post.toneTag,
        specialInterestTag: post.specialInterestTag,
        content: post.content,
        createdAt: post.timestamp.toUtc(),
        prayingCount: post.reactions['pray'] ?? 0,
        standingWithCount: post.reactions['standing'] ?? 0,
        peaceCount: post.reactions['peace'] ?? 0,
        encouragedCount: post.reactions['encouraged'] ?? 0,
      );

      final result = await _client.reflection
          .publishReflection(spPost)
          .timeout(const Duration(milliseconds: 5000));

      talker.info('✅ [Serverpod RPC SUCCESS] Reflection published: id=${result.id} tag=[${result.intentTag}] specialInterest=[${result.specialInterestTag}]');
      _isLiveConnected = true;

      return Post(
        id: result.id?.toString() ?? post.id,
        authorName: result.authorName,
        spaceKey: post.spaceKey,
        toneTag: result.intentTag,
        specialInterestTag: result.specialInterestTag,
        content: result.content,
        timestamp: result.createdAt.toLocal(),
        reactions: {
          'pray': result.prayingCount,
          'standing': result.standingWithCount,
          'peace': result.peaceCount,
          'encouraged': result.encouragedCount,
          'relatable': result.encouragedCount,
        },
      );
    } catch (e, st) {
      talker.handle(e, st, '🚨 [Serverpod RPC FAILED] createPost error, falling back to local');
      _isLiveConnected = false;
      return _fallback.createPost(post);
    }
  }

  @override
  Future<void> addReaction({required String postId, required String reactionType}) async {
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

    // 2. Connect to Serverpod streaming endpoint (persistent WebSocket stream)
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      talker.info('🔌 [Serverpod WebSocket] Connecting to live stream for space: $spaceKey (mapped: $mappedSpace)');
      final stream = _client.reflection.watchSpace(mappedSpace);

      final livePosts = <Post>[];

      await for (final spPost in stream) {
        talker.info(
          '📡 [Serverpod WebSocket EVENT] Received reflection: id=${spPost.id} author="${spPost.authorName}" tag=[${spPost.intentTag}] specialInterest=[${spPost.specialInterestTag}] content="${spPost.content}"',
        );
        debugPrint(
          '📡 [Serverpod Stream EVENT] Received post id=${spPost.id}: "${spPost.content}"',
        );
        _isLiveConnected = true;
        final post = Post(
          id: spPost.id?.toString() ?? UniqueKey().toString(),
          authorName: spPost.authorName,
          spaceKey: spaceKey,
          toneTag: spPost.intentTag,
          specialInterestTag: spPost.specialInterestTag,
          content: spPost.content,
          timestamp: spPost.createdAt.toLocal(),
          reactions: {
            'pray': spPost.prayingCount,
            'standing': spPost.standingWithCount,
            'peace': spPost.peaceCount,
            'encouraged': spPost.encouragedCount,
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
}
