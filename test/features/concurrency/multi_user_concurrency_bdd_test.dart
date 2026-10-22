import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/threaded_discussion_sheet.dart';

class FakeMemberProfileNotifier extends MemberProfileNotifier {
  final MemberProfile initial;
  FakeMemberProfileNotifier(this.initial);

  @override
  MemberProfile build() => initial;
}

void main() {
  group('Multi-User Concurrency & Real-Time Sync BDD Tests', () {
    late LocalPostRepository postRepo;
    late LocalCommentRepository sharedCommentRepo;
    late Post testPost;

    const aliceProfile = MemberProfile(
      displayName: 'Alice M. (Dallas)',
      email: 'alice@example.com',
      bio: 'Autistic disciple & botanist',
      comfortBadges: ['Quiet fellowship'],
      isSignedIn: true,
      icocChurchAffiliation: 'Dallas Church of Christ',
    );

    const bobProfile = MemberProfile(
      displayName: 'Bob T. (Fort Worth)',
      email: 'bob@example.com',
      bio: 'Audio engineer & disciple',
      comfortBadges: ['Sensory room'],
      isSignedIn: true,
      icocChurchAffiliation: 'Fort Worth Church of Christ',
    );

    setUp(() async {
      postRepo = LocalPostRepository();
      sharedCommentRepo = LocalCommentRepository();
      final posts = await postRepo.getPosts(spaceKey: 'prayer');
      testPost = posts.first; // Post '1' (David M. prayer request)
    });

    Widget createClientApp({
      Key? key,
      required MemberProfile profile,
      required Widget child,
    }) {
      return ProviderScope(
        key: key,
        overrides: [
          postRepositoryProvider.overrideWithValue(postRepo),
          commentRepositoryProvider.overrideWithValue(sharedCommentRepo),
          memberProfileProvider.overrideWith(
            () => FakeMemberProfileNotifier(profile),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    patrolWidgetTest(
      'Scenario: Real-Time Stream Synchronization Across Concurrent Disciples (Alice posts, Bob receives live)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        // 1. Mount Bob's client viewing the discussion thread
        await $.pumpWidget(
          createClientApp(
            profile: bobProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        // Verify initial seeded comments are rendered in Bob's view
        expect($('Pastor Thomas (Melbourne)'), findsOneWidget);
        expect($('Alice M. (Dallas)'), findsNothing);

        // 2. Alice concurrently submits a new comment via the shared repository
        final aliceComment = Comment(
          id: 'c_alice_live_1',
          postId: testPost.id,
          authorName: aliceProfile.displayName,
          content: 'Praying for gentle rhythms today, brother.',
          toneTag: '[Prayer]',
          timestamp: DateTime.now(),
        );

        await sharedCommentRepo.addComment(aliceComment);

        // 3. Pump Bob's view to process the stream emission
        await $.pump();
        await $.pumpAndSettle();

        // 4. Verify Bob's live UI immediately reflects Alice's reflection comment without page refresh
        expect($('Alice M. (Dallas)'), findsOneWidget);
        expect($('Praying for gentle rhythms today, brother.'), findsOneWidget);
        expect($('[Prayer]'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Scenario: Nested Reply Propagation Under Concurrent Multi-Client Browsing',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        // Seed Alice's root comment
        final aliceComment = Comment(
          id: 'c_alice_thread_1',
          postId: testPost.id,
          authorName: aliceProfile.displayName,
          content: 'Does anyone have calm sensory advice for Sunday fellowship?',
          toneTag: '[Comfort Only]',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await sharedCommentRepo.addComment(aliceComment);

        // 1. Mount Alice's client viewing the thread
        await $.pumpWidget(
          createClientApp(
            profile: aliceProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        expect($('Does anyone have calm sensory advice for Sunday fellowship?'), findsOneWidget);
        expect($('Bob T. (Fort Worth)'), findsNothing);

        // 2. Bob concurrently adds a nested reply targeting Alice's comment
        final bobReply = Comment(
          id: 'c_bob_reply_1',
          postId: testPost.id,
          parentCommentId: 'c_alice_thread_1',
          authorName: bobProfile.displayName,
          content: 'Loop earplugs and stepping into the sensory quiet room helped me!',
          toneTag: '[Relatable]',
          timestamp: DateTime.now(),
        );
        await sharedCommentRepo.addComment(bobReply);

        // 3. Stream emits to Alice's active view
        await $.pump();
        await $.pumpAndSettle();

        // 4. Verify nested reply renders in Alice's view with child indicator
        expect($('Bob T. (Fort Worth)'), findsOneWidget);
        expect(
          $('Loop earplugs and stepping into the sensory quiet room helped me!'),
          findsOneWidget,
        );
        expect($('↳'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Scenario: Concurrent Reaction Tally Reconciliation Without Lost Updates (Race condition safety)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        // Mount view
        await $.pumpWidget(
          createClientApp(
            profile: bobProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        // Comment c1_1 has initial reactions: {'pray': 4, 'peace': 3}
        final initialComments = await sharedCommentRepo.getComments(postId: testPost.id);
        final c1Initial = initialComments.firstWhere((c) => c.id == 'c1_1');
        expect(c1Initial.reactions['pray'], 4);
        expect(c1Initial.reactions['peace'], 3);

        // Concurrent atomic updates fired simultaneously by Alice and Bob
        await Future.wait([
          sharedCommentRepo.addReaction(commentId: 'c1_1', reactionType: 'pray'),
          sharedCommentRepo.addReaction(commentId: 'c1_1', reactionType: 'peace'),
        ]);

        await $.pump();
        await $.pumpAndSettle();

        // Verify both tallies are preserved atomically with zero lost updates
        final updatedComments = await sharedCommentRepo.getComments(postId: testPost.id);
        final c1Updated = updatedComments.firstWhere((c) => c.id == 'c1_1');
        expect(c1Updated.reactions['pray'], 5);
        expect(c1Updated.reactions['peace'], 4);
      },
    );

    patrolWidgetTest(
      'Scenario: Sociable Interactive Multi-Client UI Posting and Live Reconciliation',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        // 1. Mount Alice's client UI
        await $.pumpWidget(
          createClientApp(
            key: const Key('alice_client_scope'),
            profile: aliceProfile,
            child: ThreadedDiscussionSheet(
              key: const Key('alice_sheet'),
              post: testPost,
            ),
          ),
        );
        await $.pumpAndSettle();

        // Alice writes a comment through the actual UI
        await $(const Key('comment_input_field')).enterText(
          'Grace and peace to our neurodivergent fellowship tonight.',
        );
        await $.pumpAndSettle();
        await $('[Encouragement]').tap();
        await $.pumpAndSettle();
        await $(const Key('submit_comment_button')).tap();
        await $.pumpAndSettle();

        expect(
          $('Grace and peace to our neurodivergent fellowship tonight.'),
          findsOneWidget,
        );

        // 2. Switch/Mount Bob's client UI using the same shared repo
        await $.pumpWidget(
          createClientApp(
            key: const Key('bob_client_scope'),
            profile: bobProfile,
            child: ThreadedDiscussionSheet(
              key: const Key('bob_sheet'),
              post: testPost,
            ),
          ),
        );
        await $.pumpAndSettle();

        // Verify Bob sees Alice's comment immediately on mount
        expect(
          $('Grace and peace to our neurodivergent fellowship tonight.'),
          findsOneWidget,
        );
        expect($('Alice M. (Dallas)'), findsOneWidget);

        // Bob replies via the actual UI
        await $(const Key('comment_input_field')).enterText(
          'Amen Alice! Standing with you from Fort Worth.',
        );
        await $.pumpAndSettle();
        await $(ChoiceChip).$('[Relatable]').tap();
        await $.pumpAndSettle();
        await $(const Key('submit_comment_button')).tap();
        await $.pumpAndSettle();

        // 3. Both comments are visible and ordered chronologically
        expect(
          $('Amen Alice! Standing with you from Fort Worth.'),
          findsOneWidget,
        );
        expect($('Bob T. (Fort Worth)'), findsOneWidget);
      },
    );
  });
}
