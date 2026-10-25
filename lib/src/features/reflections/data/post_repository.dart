import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/post.dart';

/// Abstract contract decoupling the UI from local SQLite, in-memory, or Serverpod WebSockets.
abstract class PostRepository {
  Future<List<Post>> getPosts({required String spaceKey});
  Future<Post> createPost(Post post);

  /// Permanently removes every post by [authorName]. Used by a Circle-style ban.
  Future<int> deleteByAuthor({required String authorName});
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  });
  Stream<List<Post>> watchPosts({required String spaceKey});
  Future<String?> getQuietDigest({required String spaceKey});
  Future<List<Post>> getPostsByAuthor({required String authorName});
  Stream<List<Post>> watchPostsByAuthor({required String authorName});
  Future<void> toggleSavePost({required String postId});
  Future<List<Post>> getSavedPosts();
  Stream<List<Post>> watchSavedPosts();
}

/// Riverpod Provider for accessing the active PostRepository instance.
/// Must be overridden in ProviderScope at app root or in widget tests.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => throw UnimplementedError(
    'postRepositoryProvider must be initialized in ProviderScope overrides',
  ),
);
