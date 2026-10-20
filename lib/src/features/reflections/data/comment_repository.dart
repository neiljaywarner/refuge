import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// Riverpod provider exposing the singleton instance of CommentRepository.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => LocalCommentRepository.instance,
);
