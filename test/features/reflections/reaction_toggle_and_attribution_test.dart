import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
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

  group('Who reacted agrees with a Relate count of 1', () {
    const reactedAt = '2026-11-02T00:00:00.000Z';

    Post relatePost() => Post(
      id: 'relate-1',
      authorName: 'Fellow Member',
      spaceKey: 'general_chat',
      toneTag: '[Relatable]',
      content: 'A quiet afternoon.',
      timestamp: DateTime.parse(reactedAt),
      reactions: const {},
    );

    test('given the current user related once, when a count-only cloud echo arrives, then who-reacted still lists them', () async {
      final repo = LocalPostRepository(isDevMode: false);
      final created = await repo.createPost(relatePost());
      await repo.toggleReaction(
        postId: created.id,
        reactionType: 'relatable',
        userId: 'member-1',
        displayName: 'Jordan M.',
      );

      // Cloud rows store the count and the author, not the member list.
      // A later snapshot must not erase the person who just related.
      final cloud = postFromFirestore(created.id, {
        'authorName': created.authorName,
        'spaceKey': created.spaceKey,
        'toneTag': created.toneTag,
        'content': created.content,
        'createdAt': reactedAt,
        'authorId': 'author-9',
        'reactions': {'relatable': 1},
      }, created.spaceKey);
      repo.absorbCloudPosts([cloud]);

      final updated = (await repo.getPosts(spaceKey: created.spaceKey))
          .firstWhere((post) => post.id == created.id);
      expect(updated.countForReaction('relatable'), 1);
      expect(updated.membersForReaction('relatable').map((member) => member.displayName), [
        'Jordan M.',
      ]);
    });

    test('given a Relate is already in the reactions map, when the shared column is also 1, then Encouraged is not invented', () {
      final post = postFromFirestore('relate-1', {
        'content': 'A quiet afternoon.',
        'createdAt': reactedAt,
        'reactions': {'relatable': 1},
        'encouragedCount': 1,
      }, 'general_chat');

      expect(post.countForReaction('relatable'), 1);
      expect(post.countForReaction('encouraged'), 0);
      expect(post.reactions.containsKey('encouraged'), isFalse);
    });

    test('given a member related on a comment, when a count-only remote copy replaces it, then who-reacted still lists them', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = LocalCommentRepository(
        initialComments: const [],
        isDevMode: false,
        customFirestore: firestore,
      );
      final comment = await repo.addComment(
        Comment(
          id: 'c-relate',
          postId: 'post_1',
          authorName: 'Alex',
          content: 'Here with you.',
          timestamp: DateTime.parse(reactedAt),
          reactions: const {},
        ),
      );
      await repo.toggleReaction(
        commentId: comment.id,
        reactionType: 'relatable',
        userId: 'member-1',
        displayName: 'Jordan M.',
      );

      await firestore.collection('comments').doc(comment.id).update({'authorName': 'Alex K.'});

      final updated = (await repo.getComments(postId: 'post_1'))
          .firstWhere((item) => item.id == comment.id);
      expect(updated.authorName, 'Alex K.');
      expect(updated.countForReaction('relatable'), 1);
      expect(updated.membersForReaction('relatable').map((member) => member.displayName), [
        'Jordan M.',
      ]);
    });
  });
}
