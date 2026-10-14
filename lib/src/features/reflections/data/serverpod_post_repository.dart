import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sanctuary_server_client/sanctuary_server_client.dart' as sp;

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
          .timeout(const Duration(milliseconds: 1200));

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
    } catch (_) {
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
        await _client.reflection
            .affirmCare(parsedId, keyMap[reactionType] ?? reactionType)
            .timeout(const Duration(milliseconds: 1200));
        _isLiveConnected = true;
        return;
      } catch (_) {
        _isLiveConnected = false;
      }
    }
    return _fallback.addReaction(postId: postId, reactionType: reactionType);
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) async* {
    // 1. Instantly yield local fallback so user never sees a blank screen or loading spinner
    yield await _fallback.getPosts(spaceKey: spaceKey);

    // 2. Try to connect to Serverpod streaming endpoint
    try {
      final mappedSpace = _mapSpaceKey(spaceKey);
      final stream = _client.reflection
          .watchSpace(mappedSpace)
          .timeout(const Duration(milliseconds: 800));

      final livePosts = <Post>[];

      await for (final spPost in stream) {
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
        yield List<Post>.from(livePosts);
      }
    } catch (_) {
      // 3. Fallback gracefully to local stream
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
      return digest.summaryMessage;
    } catch (_) {
      _isLiveConnected = false;
      return _fallback.getQuietDigest(spaceKey: spaceKey);
    }
  }
}
