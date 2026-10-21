import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';

void main() {
  group('Comment Domain Model Unit Tests', () {
    test('Comment copyWith modifies fields immutably', () {
      final now = DateTime.now();
      final comment = Comment(
        id: 'c1',
        postId: 'p1',
        authorName: 'Alex M.',
        content: 'Original comment',
        toneTag: '[Comfort Only]',
        timestamp: now,
        reactions: {'peace': 2},
      );

      expect(comment.isNested, isFalse);

      final updated = comment.copyWith(content: 'Updated reflection reply');
      expect(updated.content, 'Updated reflection reply');
      expect(updated.id, 'c1');
      expect(updated.reactions['peace'], 2);
      expect(comment.content, 'Original comment');

      final nested = comment.copyWith(parentCommentId: 'c0');
      expect(nested.isNested, isTrue);
      expect(nested.parentCommentId, 'c0');
    });

    test('Comment equality and hashCode behave predictably', () {
      final now = DateTime.now();
      final c1 = Comment(
        id: 'c1',
        postId: 'p1',
        authorName: 'Alex M.',
        content: 'Gentle words',
        timestamp: now,
      );
      final c2 = Comment(
        id: 'c1',
        postId: 'p1',
        authorName: 'Alex M.',
        content: 'Gentle words',
        timestamp: now,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('LocalCommentRepository Unit Tests', () {
    test('Retrieves seeded comments and identifies nested replies for post 1', () async {
      final repo = LocalCommentRepository();
      final comments = await repo.getComments(postId: '1');

      expect(comments, isNotEmpty);
      final topLevel = comments.where((c) => !c.isNested).toList();
      final nested = comments.where((c) => c.isNested).toList();

      expect(topLevel, isNotEmpty);
      expect(nested, isNotEmpty);
      expect(nested.first.parentCommentId, equals(topLevel.first.id));
    });

    test('addComment creates top-level comment and broadcasts stream', () async {
      final repo = LocalCommentRepository();
      final now = DateTime.now();

      final newComment = Comment(
        id: 'test_c_1',
        postId: 'test_post',
        authorName: 'Sarah L.',
        content: 'Thank you for this uplifting reflection.',
        toneTag: '[Encouragement]',
        timestamp: now,
      );

      final created = await repo.addComment(newComment);
      expect(created.id, 'test_c_1');

      final allComments = await repo.getComments(postId: 'test_post');
      expect(allComments.length, 1);
      expect(allComments.first.content, 'Thank you for this uplifting reflection.');
      expect(allComments.first.toneTag, '[Encouragement]');
      expect(allComments.first.isNested, isFalse);

      final count = await repo.getCommentCount(postId: 'test_post');
      expect(count, 1);
    });

    test('addComment creates nested reply with parentCommentId', () async {
      final repo = LocalCommentRepository();
      final now = DateTime.now();

      final parent = Comment(
        id: 'parent_1',
        postId: 'test_thread',
        authorName: 'Pastor Thomas',
        content: 'Rest is spiritual.',
        timestamp: now,
      );
      await repo.addComment(parent);

      final reply = Comment(
        id: 'reply_1',
        postId: 'test_thread',
        parentCommentId: 'parent_1',
        authorName: 'David M.',
        content: 'Amen pastor.',
        toneTag: '[Comfort Only]',
        timestamp: now.add(const Duration(minutes: 5)),
      );
      await repo.addComment(reply);

      final threaded = await repo.getComments(postId: 'test_thread');
      expect(threaded.length, 2);
      expect(threaded[1].isNested, isTrue);
      expect(threaded[1].parentCommentId, 'parent_1');
    });

    test('addReaction increments reaction tally on a comment', () async {
      final repo = LocalCommentRepository();
      final comments = await repo.getComments(postId: '1');
      final firstComment = comments.first;
      final initialPray = firstComment.reactions['pray'] ?? 0;

      await repo.addReaction(commentId: firstComment.id, reactionType: 'pray');

      final updated = await repo.getComments(postId: '1');
      final updatedComment = updated.firstWhere((c) => c.id == firstComment.id);
      expect(updatedComment.reactions['pray'], initialPray + 1);
    });

    test('watchComments streams live updates', () async {
      final repo = LocalCommentRepository();
      final stream = repo.watchComments(postId: 'stream_post');

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      await Future<void>.delayed(Duration.zero);

      await repo.addComment(
        Comment(
          id: 'live_1',
          postId: 'stream_post',
          authorName: 'Grace',
          content: 'Live streaming comment',
          timestamp: DateTime.now(),
        ),
      );

      await expectation;
    });
  });
}
