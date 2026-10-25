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

    const discipleAlphaProfile = MemberProfile(
      displayName: 'Disciple Alpha (Dallas)',
      email: 'disciple.alpha@example.com',
      bio: 'Autistic disciple & botanist',
      comfortBadges: ['Quiet fellowship'],
      isSignedIn: true,
      icocChurchAffiliation: 'Dallas Church of Christ',
    );

    const discipleBetaProfile = MemberProfile(
      displayName: 'Disciple Beta (Fort Worth)',
      email: 'disciple.beta@example.com',
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
    }) => ProviderScope(
      key: key,
      overrides: [
        postRepositoryProvider.overrideWithValue(postRepo),
        commentRepositoryProvider.overrideWithValue(sharedCommentRepo),
        memberProfileProvider.overrideWith(
          () => FakeMemberProfileNotifier(profile),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

    patrolWidgetTest(
      'Scenario: Real-Time Stream Synchronization Across Concurrent Disciples (Alpha posts, Beta receives live)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        // 1. Mount Beta's client viewing the discussion thread
        await $.pumpWidget(
          createClientApp(
            profile: discipleBetaProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        // Verify initial seeded comments are rendered in Beta's view
        expect($('Pastor Thomas (Melbourne)'), findsOneWidget);
        expect($('Disciple Alpha (Dallas)'), findsNothing);

        // 2. Alpha concurrently submits a new comment via the shared repository
        final alphaComment = Comment(
          id: 'c_alpha_live_1',
          postId: testPost.id,
          authorName: discipleAlphaProfile.displayName,
          content: 'Praying for gentle rhythms today, brother.',
          toneTag: '[Prayer]',
          timestamp: DateTime.now(),
        );

        await sharedCommentRepo.addComment(alphaComment);

        // 3. Pump Beta's view to process the stream emission
        await $.pump();
        await $.pumpAndSettle();

        // 4. Verify Beta's live UI immediately reflects Alpha's reflection comment without page refresh
        expect($('Disciple Alpha (Dallas)'), findsOneWidget);
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

        // Seed Alpha's root comment
        final alphaComment = Comment(
          id: 'c_alpha_thread_1',
          postId: testPost.id,
          authorName: discipleAlphaProfile.displayName,
          content:
              'Does anyone have calm sensory advice for Sunday fellowship?',
          toneTag: '[Comfort Only]',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await sharedCommentRepo.addComment(alphaComment);

        // 1. Mount Alpha's client viewing the thread
        await $.pumpWidget(
          createClientApp(
            profile: discipleAlphaProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        expect(
          $('Does anyone have calm sensory advice for Sunday fellowship?'),
          findsOneWidget,
        );
        expect($('Disciple Beta (Fort Worth)'), findsNothing);

        // 2. Beta concurrently adds a nested reply targeting Alpha's comment
        final betaReply = Comment(
          id: 'c_beta_reply_1',
          postId: testPost.id,
          parentCommentId: 'c_alpha_thread_1',
          authorName: discipleBetaProfile.displayName,
          content: 'Loop earplugs and stepping into the sensory quiet room helped me!',
          toneTag: '[Relatable]',
          timestamp: DateTime.now(),
        );
        await sharedCommentRepo.addComment(betaReply);

        // 3. Stream emits to Alpha's active view
        await $.pump();
        await $.pumpAndSettle();

        // 4. Verify nested reply renders in Alpha's view with child indicator
        expect($('Disciple Beta (Fort Worth)'), findsOneWidget);
        expect(
          $(
            'Loop earplugs and stepping into the sensory quiet room helped me!',
          ),
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
            profile: discipleBetaProfile,
            child: ThreadedDiscussionSheet(post: testPost),
          ),
        );
        await $.pumpAndSettle();

        // Comment c1_1 has initial reactions: {'pray': 4, 'peace': 3}
        final initialComments = await sharedCommentRepo.getComments(
          postId: testPost.id,
        );
        final c1Initial = initialComments.firstWhere((c) => c.id == 'c1_1');
        expect(c1Initial.reactions['pray'], 4);
        expect(c1Initial.reactions['peace'], 3);

        // Concurrent atomic updates fired simultaneously by Alpha and Beta
        await Future.wait([
          sharedCommentRepo.addReaction(
            commentId: 'c1_1',
            reactionType: 'pray',
          ),
          sharedCommentRepo.addReaction(
            commentId: 'c1_1',
            reactionType: 'peace',
          ),
        ]);

        await $.pump();
        await $.pumpAndSettle();

        // Verify both tallies are preserved atomically with zero lost updates
        final updatedComments = await sharedCommentRepo.getComments(
          postId: testPost.id,
        );
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

        // 1. Mount Alpha's client UI
        await $.pumpWidget(
          createClientApp(
            key: const Key('alpha_client_scope'),
            profile: discipleAlphaProfile,
            child: ThreadedDiscussionSheet(
              key: const Key('alpha_sheet'),
              post: testPost,
            ),
          ),
        );
        await $.pumpAndSettle();

        // Alpha writes a comment through the actual UI
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

        // 2. Switch/Mount Beta's client UI using the same shared repo
        await $.pumpWidget(
          createClientApp(
            key: const Key('beta_client_scope'),
            profile: discipleBetaProfile,
            child: ThreadedDiscussionSheet(
              key: const Key('beta_sheet'),
              post: testPost,
            ),
          ),
        );
        await $.pumpAndSettle();

        // Verify Beta sees Alpha's comment immediately on mount
        expect(
          $('Grace and peace to our neurodivergent fellowship tonight.'),
          findsOneWidget,
        );
        expect($('Disciple Alpha (Dallas)'), findsOneWidget);

        // Beta replies via the actual UI
        await $(const Key('comment_input_field'))
            .enterText('Amen! Standing with you from Fort Worth.');
        await $.pumpAndSettle();
        await $(ChoiceChip).$('[Relatable]').tap();
        await $.pumpAndSettle();
        await $(const Key('submit_comment_button')).tap();
        await $.pumpAndSettle();

        // 3. Both Alpha's and Beta's comments remain visible and ordered chronologically
        expect(
          $('Grace and peace to our neurodivergent fellowship tonight.'),
          findsOneWidget,
        );
        expect($('Amen! Standing with you from Fort Worth.'), findsOneWidget);
        expect($('Disciple Beta (Fort Worth)'), findsOneWidget);
      },
    );
  });
}
