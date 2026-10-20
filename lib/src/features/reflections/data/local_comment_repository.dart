import 'dart:async';

import '../domain/comment.dart';
import 'comment_repository.dart';

/// In-memory, broadcast stream implementation of [CommentRepository].
///
/// Pre-seeds authentic discussion threads matching Belong on the Spectrum community culture.
class LocalCommentRepository implements CommentRepository {
  static final LocalCommentRepository instance = LocalCommentRepository();

  final List<Comment> _store = [];
  final StreamController<List<Comment>> _controller =
      StreamController<List<Comment>>.broadcast();

  LocalCommentRepository({List<Comment>? initialComments}) {
    if (initialComments != null) {
      _store.addAll(initialComments);
    } else {
      _seedInitialData();
    }
  }

  void _seedInitialData() {
    final now = DateTime.now();

    _store.addAll([
      // Thread under Post 1 (David M. prayer request)
      Comment(
        id: 'c1_1',
        postId: '1',
        authorName: 'Pastor Thomas (Melbourne)',
        content:
            'Praying for you David. Hebrews 4:10 reminds us that resting is entering His rest. Be gentle with your routine.',
        toneTag: '[Prayer]',
        timestamp: now.subtract(const Duration(minutes: 25)),
        reactions: {'pray': 4, 'peace': 3},
      ),
      Comment(
        id: 'c1_1_reply',
        postId: '1',
        parentCommentId: 'c1_1',
        authorName: 'David M. (UK)',
        content:
            'Thank you Pastor Thomas, that verse brings a lot of reassurance today. Grateful for this quiet community.',
        toneTag: '[Comfort Only]',
        timestamp: now.subtract(const Duration(minutes: 15)),
        reactions: {'peace': 2},
      ),
      Comment(
        id: 'c1_2',
        postId: '1',
        authorName: 'Elena R. (Colorado)',
        content:
            'Transitioning routines is so disorienting for autistic brains. Sending quiet prayers and holding space for you.',
        toneTag: '[Support]',
        timestamp: now.subtract(const Duration(minutes: 20)),
        reactions: {'pray': 2, 'peace': 4},
      ),

      // Thread under Post 4 (Nathan K. Church Acoustics Meme)
      Comment(
        id: 'c4_1',
        postId: '4',
        authorName: 'Caleb T. (Fort Worth)',
        content:
            'The reverberation decay calculation is too real! Loop earplugs completely changed worship service for me.',
        toneTag: '[Relatable]',
        timestamp: now.subtract(const Duration(minutes: 10)),
        reactions: {'relatable': 6},
      ),
      Comment(
        id: 'c4_1_reply',
        postId: '4',
        parentCommentId: 'c4_1',
        authorName: 'Nathan K. (Texas)',
        content:
            'Right?! Especially during the high-hat cymbal on the drum kit. Essential gear!',
        toneTag: '[Relatable]',
        timestamp: now.subtract(const Duration(minutes: 6)),
        reactions: {'relatable': 3},
      ),

      // Thread under Post 6 (Belong Organizer Welcome)
      Comment(
        id: 'c6_1',
        postId: '6',
        authorName: 'Hannah W. (Dallas)',
        content:
            'So happy to be here. My special interest is sensory gardening and native Texas wildflowers!',
        toneTag: '[Welcome]',
        timestamp: now.subtract(const Duration(minutes: 7)),
        reactions: {'encouraged': 5},
      ),
    ]);
  }

  @override
  Future<List<Comment>> getComments({required String postId}) async =>
      _getOrderedThread(postId);

  @override
  Future<Comment> addComment(Comment comment) async {
    _store.add(comment);
    _controller.add(List.unmodifiable(_store));
    return comment;
  }

  @override
  Future<void> addReaction({
    required String commentId,
    required String reactionType,
  }) async {
    final index = _store.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final existing = _store[index];
      final updatedReactions = Map<String, int>.from(existing.reactions);
      updatedReactions[reactionType] = (updatedReactions[reactionType] ?? 0) + 1;
      _store[index] = existing.copyWith(reactions: updatedReactions);
      _controller.add(List.unmodifiable(_store));
    }
  }

  @override
  Stream<List<Comment>> watchComments({required String postId}) async* {
    yield _getOrderedThread(postId);
    yield* _controller.stream.map((_) => _getOrderedThread(postId));
  }

  @override
  Future<int> getCommentCount({required String postId}) async =>
      _store.where((c) => c.postId == postId).length;

  @override
  Stream<int> watchCommentCount({required String postId}) =>
      watchComments(postId: postId).map((comments) => comments.length);

  /// Returns comments ordered hierarchically: top-level comments first,
  /// immediately followed by their child replies.
  List<Comment> _getOrderedThread(String postId) {
    final postComments = _store.where((c) => c.postId == postId).toList();
    final topLevel = postComments.where((c) => !c.isNested).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final result = <Comment>[];
    for (final parent in topLevel) {
      result.add(parent);
      final children = postComments
          .where((c) => c.parentCommentId == parent.id)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      result.addAll(children);
    }

    // Include any orphaned nested comments gracefully
    final orphaned = postComments.where(
      (c) => c.isNested && !result.any((item) => item.id == c.id),
    );
    result.addAll(orphaned);

    return result;
  }
}
