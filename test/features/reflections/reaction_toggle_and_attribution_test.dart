import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reaction_member.dart';

void main() {
  group('ReactionMember Domain Model Tests', () {
    test('serializes and deserializes cleanly to/from JSON', () {
      final now = DateTime.utc(2026, 11, 2, 1, 0, 0);
      final member = ReactionMember(
        userId: 'user_123',
        displayName: 'Neil W.',
        avatarUrl: 'https://example.com/avatar.png',
        timestamp: now,
      );

      final json = member.toJson();
      expect(json['userId'], 'user_123');
      expect(json['displayName'], 'Neil W.');
      expect(json['avatarUrl'], 'https://example.com/avatar.png');
      expect(json['timestamp'], '2026-11-02T01:00:00.000Z');

      final deserialized = ReactionMember.fromJson(json);
      expect(deserialized, equals(member));
    });

    test('supports copyWith and value equality', () {
      final now = DateTime.now();
      final m1 = ReactionMember(userId: 'u1', displayName: 'Carina W.', timestamp: now);
      final m2 = m1.copyWith(displayName: 'Carina Warner');

      expect(m2.displayName, 'Carina Warner');
      expect(m2.userId, 'u1');
      expect(m1.displayName, 'Carina W.');
    });
  });

  group('Post Reaction Attribution & Toggle Tests', () {
    test('hasMemberReacted, membersForReaction and countForReaction behave correctly', () {
      final now = DateTime.now();
      final post = Post(
        id: 'p1',
        authorName: 'Santi',
        spaceKey: 'general_chat',
        toneTag: '[Relatable]',
        content: 'Sensory overload during fellowship lunch',
        timestamp: now,
        reactions: {'relatable': 1},
        reactionMembers: {
          'relatable': [ReactionMember(userId: 'user_bruce', displayName: 'Bruce', timestamp: now)],
        },
      );

      expect(post.hasMemberReacted('relatable', 'user_bruce'), isTrue);
      expect(post.hasMemberReacted('relatable', 'user_other'), isFalse);
      expect(post.hasMemberReacted('pray', 'user_bruce'), isFalse);
      expect(post.countForReaction('relatable'), 1);
      expect(post.membersForReaction('relatable').first.displayName, 'Bruce');
    });

    test('LocalPostRepository.toggleReaction toggles ON and OFF idempotently', () async {
      final repo = LocalPostRepository(isDevMode: false);
      final post = await repo.createPost(
        Post(
          id: 'test_post_1',
          authorName: 'Jordan',
          spaceKey: 'general_chat',
          toneTag: '[Support]',
          content: 'Need some prayer tonight',
          timestamp: DateTime.now(),
          reactions: {'pray': 0},
        ),
      );

      // 1. Initial State: 0 praying
      expect(post.countForReaction('pray'), 0);

      // 2. Toggle ON by Neil
      await repo.toggleReaction(
        postId: post.id,
        reactionType: 'pray',
        userId: 'neil_uid',
        displayName: 'Neil',
      );

      var updated = (await repo.getPosts(spaceKey: 'general_chat'))
          .firstWhere((p) => p.id == post.id);
      expect(updated.countForReaction('pray'), 1);
      expect(updated.hasMemberReacted('pray', 'neil_uid'), isTrue);
      expect(updated.membersForReaction('pray').first.displayName, 'Neil');

      // 3. Toggle OFF by Neil (second tap must remove, NOT increment to 2!)
      await repo.toggleReaction(
        postId: post.id,
        reactionType: 'pray',
        userId: 'neil_uid',
        displayName: 'Neil',
      );

      updated = (await repo.getPosts(spaceKey: 'general_chat')).firstWhere((p) => p.id == post.id);
      expect(updated.countForReaction('pray'), 0);
      expect(updated.hasMemberReacted('pray', 'neil_uid'), isFalse);
      expect(updated.membersForReaction('pray'), isEmpty);

      // 4. Two different members can react independently
      await repo.toggleReaction(
        postId: post.id,
        reactionType: 'pray',
        userId: 'neil_uid',
        displayName: 'Neil',
      );
      await repo.toggleReaction(
        postId: post.id,
        reactionType: 'pray',
        userId: 'carina_uid',
        displayName: 'Carina',
      );

      updated = (await repo.getPosts(spaceKey: 'general_chat')).firstWhere((p) => p.id == post.id);
      expect(updated.countForReaction('pray'), 2);
      expect(updated.hasMemberReacted('pray', 'neil_uid'), isTrue);
      expect(updated.hasMemberReacted('pray', 'carina_uid'), isTrue);
      expect(updated.membersForReaction('pray').map((m) => m.displayName).toList(), [
        'Neil',
        'Carina',
      ]);
    });
  });

  group('Comment Reaction Attribution & Toggle Tests', () {
    test('LocalCommentRepository.toggleReaction toggles ON and OFF', () async {
      final repo = LocalCommentRepository(isDevMode: false);
      final comment = await repo.addComment(
        Comment(
          id: 'c_test_1',
          postId: 'post_1',
          authorName: 'Alex',
          content: 'Here with you in spirit',
          timestamp: DateTime.now(),
          reactions: {'peace': 0},
        ),
      );

      expect(comment.countForReaction('peace'), 0);

      // Toggle ON
      await repo.toggleReaction(
        commentId: comment.id,
        reactionType: 'peace',
        userId: 'member_1',
        displayName: 'Sam',
      );

      var comments = await repo.getComments(postId: 'post_1');
      var updated = comments.firstWhere((c) => c.id == comment.id);
      expect(updated.countForReaction('peace'), 1);
      expect(updated.hasMemberReacted('peace', 'member_1'), isTrue);

      // Toggle OFF
      await repo.toggleReaction(
        commentId: comment.id,
        reactionType: 'peace',
        userId: 'member_1',
        displayName: 'Sam',
      );

      comments = await repo.getComments(postId: 'post_1');
      updated = comments.firstWhere((c) => c.id == comment.id);
      expect(updated.countForReaction('peace'), 0);
      expect(updated.hasMemberReacted('peace', 'member_1'), isFalse);
    });
  });
}
