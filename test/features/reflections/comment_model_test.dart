import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reaction_member.dart';

void main() {
  final when = DateTime.utc(2026, 11, 1, 15, 30);
  final member = ReactionMember(
    userId: 'member-1',
    displayName: 'David M.',
    avatarUrl: 'https://example.com/avatar.png',
    timestamp: when,
  );

  Comment sample({String? parentCommentId}) => Comment(
    id: 'comment-1',
    postId: 'post-1',
    parentCommentId: parentCommentId,
    authorName: 'Sarah K.',
    content: 'A quiet reply.',
    toneTag: '[Comfort Only]',
    timestamp: when,
    reactions: const {'pray': 2, 'peace': 0},
    reactionMembers: {
      'pray': [member],
    },
  );

  test('reaction lookup prefers the member list and ignores an empty user', () {
    final comment = sample();

    expect(comment.hasMemberReacted('pray', null), isFalse);
    expect(comment.hasMemberReacted('pray', ''), isFalse);
    expect(comment.hasMemberReacted('pray', 'member-1'), isTrue);
    expect(comment.hasMemberReacted('peace', 'member-1'), isFalse);
    expect(comment.membersForReaction('peace'), isEmpty);
    expect(comment.countForReaction('pray'), 1);
    expect(comment.countForReaction('peace'), 0);
    expect(comment.countForReaction('relatable'), 0);
    expect(comment.isNested, isFalse);
    expect(sample(parentCommentId: 'parent-1').isNested, isTrue);
    expect(sample(parentCommentId: '').isNested, isFalse);
  });

  test('json keeps the parent, the tag, and the people who reacted', () {
    final restored = Comment.fromJson(sample(parentCommentId: 'parent-1').toJson());

    expect(restored, sample(parentCommentId: 'parent-1'));
    expect(restored.parentCommentId, 'parent-1');
    expect(restored.toneTag, '[Comfort Only]');
    expect(restored.reactionMembers['pray']!.single.displayName, 'David M.');
    expect(restored.reactionMembers['pray']!.single.avatarUrl, 'https://example.com/avatar.png');
  });

  test('a sparse json row uses the fellowship defaults', () {
    final restored = Comment.fromJson({
      'reactions': {'pray': 1.0, 'peace': 'nope'},
      'reactionMembers': {
        'pray': [
          {'userId': 'member-2', 'displayName': 'Fellow Member'},
          'not-a-member',
        ],
      },
    });

    expect(restored.id, isEmpty);
    expect(restored.authorName, 'Fellowship Member');
    expect(restored.content, isEmpty);
    expect(restored.reactions, {'pray': 1});
    expect(restored.reactionMembers['pray']!.single.userId, 'member-2');
    expect(restored.timestamp.difference(DateTime.now()).inMinutes.abs(), lessThan(2));
  });

  test('copyWith replaces the requested fields and clones the member lists', () {
    final comment = sample();
    final copied = comment.copyWith(content: 'Updated reply', reactions: const {'pray': 3});

    expect(copied.content, 'Updated reply');
    expect(copied.reactions, {'pray': 3});
    expect(copied.reactionMembers['pray'], isNot(same(comment.reactionMembers['pray'])));
    expect(copied.id, comment.id);
  });
}
