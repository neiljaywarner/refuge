import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../domain/comment.dart';
import 'local_comment_repository.dart';

/// Contract decoupling comment storage, streaming, and reactions from backend implementations.
abstract class CommentRepository {
  /// Fetches comments for a specific post.
  Future<List<Comment>> getComments({required String postId});

  /// Adds a new comment or nested discussion reply.
  Future<Comment> addComment(Comment comment);

  /// Increments a care reaction tally for a comment.
  Future<void> addReaction({required String commentId, required String reactionType});

  /// Asynchronously watches live comment additions and reaction updates for a post.
  Stream<List<Comment>> watchComments({required String postId});

  /// Returns total count of comments for a given post.
  Future<int> getCommentCount({required String postId});

  /// Streams the total comment count for a given post.
  Stream<int> watchCommentCount({required String postId});

  /// Fetches comments authored by a specific member.
  Future<List<Comment>> getCommentsByAuthor({required String authorName});

  /// Streams comments authored by a specific member.
  Stream<List<Comment>> watchCommentsByAuthor({required String authorName});
}

/// Riverpod provider exposing the configured CommentRepository.
///
/// In production (`AppFlavor.prod`), initializes an empty repository with
/// zero hardcoded mock data and live Firestore dual-redundancy. In dev/QA,
/// seeds authentic discussion threads.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  return LocalCommentRepository(isDevMode: !flavor.isProduction);
});
