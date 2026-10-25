import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

class MemoryReflectionMirror implements ReflectionMirror {
  final posts = <String, Post>{};
  final reactions = <String, int>{};
  String? digest;

  @override
  Future<void> upsertPost(Post post) async {
    posts[post.id] = post;
  }

  @override
  Future<void> incrementReaction({
    required String postId,
    required String column,
  }) async {
    reactions['$postId:$column'] = (reactions['$postId:$column'] ?? 0) + 1;
  }

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async {
    final wanted = canonicalSpaceKey(spaceKey);
    return posts.values.where((post) => post.spaceKey == wanted).toList();
  }

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async {
    digest = summary;
  }
}

void main() {
  test('auth stays on Firebase while posts move to Appwrite', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(authBackendTargetProvider), BackendTarget.firebase);
    expect(
      container.read(featureVotingBackendTargetProvider),
      BackendTarget.firebase,
    );
  });

  test('createPost mirrors to Appwrite and keeps the local copy', () async {
    final mirror = MemoryReflectionMirror();
    final repo = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      mirror: mirror,
    );
    final created = await repo.createPost(
      Post(
        id: 'post-100',
        authorName: 'Fellow Member',
        spaceKey: 'prayer',
        toneTag: '[Support]',
        content: 'A quiet note.',
        timestamp: DateTime.utc(2026, 10, 24, 12),
        reactions: const {'pray': 1},
      ),
    );

    expect(created.id, 'post-100');
    expect(mirror.posts['post-100']?.content, 'A quiet note.');
    expect(repo.isLiveConnected, isTrue);
    final stored = await repo.getPosts(spaceKey: 'prayer');
    expect(stored.map((post) => post.id), contains('post-100'));
  });

  test(
    'addReaction increments the Appwrite column and the local count',
    () async {
      final mirror = MemoryReflectionMirror();
      final repo = AppwritePostRepository(
        isDevMode: false,
        fallback: LocalPostRepository(isDevMode: false),
        mirror: mirror,
      );
      await repo.createPost(
        Post(
          id: 'post-200',
          authorName: 'Fellow Member',
          spaceKey: 'study',
          toneTag: '[Question]',
          content: 'Holding this gently.',
          timestamp: DateTime.utc(2026, 10, 24, 13),
          reactions: const {},
        ),
      );

      await repo.addReaction(postId: 'post-200', reactionType: 'peace');

      expect(mirror.reactions['post-200:peaceCount'], 1);
      final stored = await repo.getPosts(spaceKey: 'study');
      expect(
        stored.singleWhere((post) => post.id == 'post-200').reactions['peace'],
        1,
      );
    },
  );

  test('quiet digest is computed locally and mirrored', () async {
    final mirror = MemoryReflectionMirror();
    final repo = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      mirror: mirror,
    );
    await repo.createPost(
      Post(
        id: 'post-300',
        authorName: 'Community Member',
        spaceKey: 'announcements',
        toneTag: '[Announcement]',
        content: 'Welcome in.',
        timestamp: DateTime.utc(2026, 10, 24, 14),
        reactions: const {'peace': 2},
      ),
    );

    final digest = await repo.getQuietDigest(spaceKey: 'announcements');

    expect(digest, contains('1 reflections'));
    expect(digest, contains('2 care affirmations'));
    expect(mirror.digest, digest);
  });

  test('invalid Appwrite ids are rewritten into a safe row id', () {
    expect(appwriteRowId('post-100'), 'post-100');
    expect(appwriteRowId('-abc'), 'r-abc');
    expect(appwriteRowId('[#]'), 'row');
  });
}
