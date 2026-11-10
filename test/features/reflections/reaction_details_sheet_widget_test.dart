import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reaction_member.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reaction_details_sheet.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

void main() {
  group('ReactionDetailsSheet Widget Tests', () {
    testWidgets('renders Care Affirmations sheet and lists reacting members', (tester) async {
      final now = DateTime.now();
      final post = Post(
        id: 'post_sheet_1',
        authorName: 'Santi',
        spaceKey: 'general_chat',
        toneTag: '[Relatable]',
        content: 'Loved today\'s quiet walk in the park.',
        timestamp: now,
        reactions: {'pray': 2, 'peace': 1},
        reactionMembers: {
          'pray': [
            ReactionMember(
              userId: 'u1',
              displayName: 'Neil Warner',
              timestamp: now.subtract(const Duration(minutes: 5)),
            ),
            ReactionMember(
              userId: 'u2',
              displayName: 'Carina Warner',
              timestamp: now.subtract(const Duration(minutes: 2)),
            ),
          ],
          'peace': [
            ReactionMember(
              userId: 'u3',
              displayName: 'Bruce',
              timestamp: now.subtract(const Duration(minutes: 1)),
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_sheet_btn'),
                onPressed: () =>
                    ReactionDetailsSheet.show(ctx, post: post, initialReactionType: 'pray'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_btn')));
      await tester.pumpAndSettle();

      // Header verified
      expect(find.text('Care Affirmations'), findsOneWidget);

      // Filter chips verified
      expect(find.byKey(const Key('reaction_chip_pray')), findsOneWidget);
      expect(find.byKey(const Key('reaction_chip_peace')), findsOneWidget);

      // Members in 'pray' tab verified
      expect(find.text('Neil Warner'), findsOneWidget);
      expect(find.text('Carina Warner'), findsOneWidget);

      // Switch to 'peace' tab
      await tester.tap(find.byKey(const Key('reaction_chip_peace')));
      await tester.pumpAndSettle();

      expect(find.text('Bruce'), findsOneWidget);
      expect(find.text('Neil Warner'), findsNothing);

      // Close button dismisses sheet
      await tester.tap(find.byKey(const Key('reaction_sheet_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Care Affirmations'), findsNothing);
    });

    testWidgets('ReflectionCard long-press opens ReactionDetailsSheet', (tester) async {
      final now = DateTime.now();
      final post = Post(
        id: 'post_card_test',
        authorName: 'Alex',
        spaceKey: 'prayer',
        toneTag: '[Support]',
        content: 'Grateful for this calm space.',
        timestamp: now,
        reactions: {'pray': 1},
        reactionMembers: {
          'pray': [ReactionMember(userId: 'u_tester', displayName: 'Jordan M.', timestamp: now)],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
            ),
          ),
        ),
      );

      // Long press on pray button
      await tester.longPress(find.byKey(const Key('reaction_button_pray_post_card_test')));
      await tester.pumpAndSettle();

      expect(find.text('Care Affirmations'), findsOneWidget);
      expect(find.text('Jordan M.'), findsOneWidget);
    });

    testWidgets('given a Relate count of 1, long-press lists the member instead of no one', (
      tester,
    ) async {
      const reactedAt = '2026-11-02T00:00:00.000Z';
      final repo = LocalPostRepository(isDevMode: false);
      final created = await repo.createPost(
        Post(
          id: 'relate-web',
          authorName: 'Fellow Member',
          spaceKey: 'general_chat',
          toneTag: '[Relatable]',
          content: 'A quiet afternoon.',
          timestamp: DateTime.parse(reactedAt),
          reactions: const {},
        ),
      );
      await repo.toggleReaction(
        postId: created.id,
        reactionType: 'relatable',
        userId: 'member-1',
        displayName: 'Jordan M.',
      );
      repo.absorbCloudPosts([
        postFromFirestore(created.id, {
          'authorName': created.authorName,
          'spaceKey': created.spaceKey,
          'toneTag': created.toneTag,
          'content': created.content,
          'createdAt': reactedAt,
          'authorId': 'author-9',
          'reactions': {'relatable': 1},
        }, created.spaceKey),
      ]);
      final post = (await repo.getPosts(spaceKey: created.spaceKey))
          .firstWhere((item) => item.id == created.id);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('1 Relatable'), findsOneWidget);

      await tester.longPress(find.byKey(Key('reaction_button_relatable_${post.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Care Affirmations'), findsOneWidget);
      expect(find.text('Jordan M.'), findsOneWidget);
      expect(find.text('No members have offered relatable yet.'), findsNothing);
    });

    testWidgets('given only a Relate, the Encouraged control does not also show a count of 1', (
      tester,
    ) async {
      final post = postFromFirestore('relate-column', {
        'authorName': 'Fellow Member',
        'content': 'A quiet afternoon.',
        'spaceKey': 'general_chat',
        'toneTag': '[Relatable]',
        'createdAt': '2026-11-02T00:00:00.000Z',
        'reactions': {'relatable': 1},
        'encouragedCount': 1,
      }, 'general_chat');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('1 Relatable'), findsOneWidget);
      expect(find.text('1 Encouraged'), findsNothing);
    });

    testWidgets('given a comment Relate count of 1, the who-reacted sheet lists that member', (
      tester,
    ) async {
      const reactedAt = '2026-11-02T00:00:00.000Z';
      final firestore = FakeFirebaseFirestore();
      final repo = LocalCommentRepository(
        initialComments: const [],
        isDevMode: false,
        customFirestore: firestore,
      );
      final created = await repo.addComment(
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
        commentId: created.id,
        reactionType: 'relatable',
        userId: 'member-1',
        displayName: 'Jordan M.',
      );
      await firestore.collection('comments').doc(created.id).update({'authorName': 'Alex K.'});
      final comment = (await repo.getComments(postId: 'post_1'))
          .firstWhere((item) => item.id == created.id);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReactionDetailsSheet.show(
                  context,
                  comment: comment,
                  initialReactionType: 'relatable',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      expect(comment.countForReaction('relatable'), 1);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Jordan M.'), findsOneWidget);
      expect(find.text('No members have offered relatable yet.'), findsNothing);
    });
  });
}
