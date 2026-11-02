import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/post.dart';

/// Abstract contract decoupling the UI from local SQLite, in-memory, or Serverpod WebSockets.
abstract class PostRepository {
  Future<List<Post>> getPosts({required String spaceKey});
  Future<Post> createPost(Post post);

  /// Permanently removes every post by [authorName] or [authorId].
  ///
  /// [authorId] is the Firebase uid. Name-only rows remain for older posts
  /// that were stored before the uid was written.
  Future<int> deleteByAuthor({required String authorName, String? authorId});
  Future<void> addReaction({required String postId, required String reactionType});
  Stream<List<Post>> watchPosts({required String spaceKey});
  Future<String?> getQuietDigest({required String spaceKey});
  Future<List<Post>> getPostsByAuthor({required String authorName});
  Stream<List<Post>> watchPostsByAuthor({required String authorName});
  Future<void> toggleSavePost({required String postId});
  Future<List<Post>> getSavedPosts();
  Stream<List<Post>> watchSavedPosts();
}

/// Local caches that must reset when the signed-in Firebase uid changes.
abstract interface class AccountScopedCache {
  Future<void> adoptAccount(String? accountId);
}

extension AccountScopedPostCache on PostRepository {
  Future<void> adoptSignedInAccount(String? accountId) async {
    final cache = this;
    if (cache is AccountScopedCache) {
      await (cache as AccountScopedCache).adoptAccount(accountId);
    }
  }
}

/// Riverpod Provider for accessing the active PostRepository instance.
/// Must be overridden in ProviderScope at app root or in widget tests.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => throw UnimplementedError(
    'postRepositoryProvider must be initialized in ProviderScope overrides',
  ),
);
