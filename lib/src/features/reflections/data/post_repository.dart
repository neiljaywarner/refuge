import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/post.dart';

/// Abstract contract decoupling the UI from local SQLite, in-memory, or Serverpod WebSockets.
abstract class PostRepository {
  Future<List<Post>> getPosts({required String spaceKey});
  Future<Post> createPost(Post post);
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  });
  Stream<List<Post>> watchPosts({required String spaceKey});
  Future<String?> getQuietDigest({required String spaceKey});
}

/// Riverpod Provider for accessing the active PostRepository instance.
/// Must be overridden in ProviderScope at app root or in widget tests.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  throw UnimplementedError(
    'postRepositoryProvider must be initialized in ProviderScope overrides',
  );
});
