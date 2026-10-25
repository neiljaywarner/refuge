import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/threaded_discussion_sheet.dart';

class FakeMemberProfileNotifier extends MemberProfileNotifier {
  final MemberProfile initial;
  FakeMemberProfileNotifier(this.initial);

  @override
  MemberProfile build() => initial;
}

void main() {
  group('Threaded Comments & Nested Discussion BDD Widget Tests', () {
    late LocalPostRepository postRepo;
    late LocalCommentRepository commentRepo;
    late Post testPost;

    setUp(() async {
      postRepo = LocalPostRepository();
      commentRepo = LocalCommentRepository();
      final posts = await postRepo.getPosts(spaceKey: 'prayer');
      testPost = posts.first; // Post '1' (David M.)
    });

    Widget createTestApp({required Widget child}) => ProviderScope(
      overrides: [
        postRepositoryProvider.overrideWithValue(postRepo),
        commentRepositoryProvider.overrideWithValue(commentRepo),
        memberProfileProvider.overrideWith(
          () => FakeMemberProfileNotifier(
            const MemberProfile(
              displayName: 'Hannah W. (Dallas)',
              email: 'hannah@example.com',
              bio: 'Autistic disciple & botanist',
              comfortBadges: ['Quiet fellowship'],
              isSignedIn: true,
              icocChurchAffiliation: 'Dallas Church of Christ',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    patrolWidgetTest(
      'ReflectionCard renders discussion reply button with live count badge',
      ($) async {
        await $.pumpWidget(
          createTestApp(
            child: ReflectionCard(
              post: testPost,
              isContrast: false,
              onAddReaction: (_) {},
            ),
          ),
        );
        await $.pumpAndSettle();

        expect($(const Key('discussion_button_1')), findsOneWidget);
        // Post 1 has 3 seeded comments
        expect($('3 Replies'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Tapping discussion button opens ThreadedDiscussionSheet and displays nested replies',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () =>
                    ThreadedDiscussionSheet.show(context, post: testPost),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        await $(const Key('open_sheet_button')).tap();
        await $.pumpAndSettle();

        // Verify sheet header and post excerpt
        expect($(const Key('threaded_discussion_sheet_title')), findsOneWidget);
        expect($('Discussion & Replies'), findsOneWidget);
        expect($(testPost.authorName), findsWidgets);

        // Verify seeded comments render
        expect($('Pastor Thomas (Melbourne)'), findsOneWidget);
        expect($('Elena R. (Colorado)'), findsOneWidget);
        expect($('David M. (UK)'), findsWidgets);

        // Verify nested reply indicator
        expect($('↳'), findsWidgets);
      },
    );

    patrolWidgetTest('Care reaction increments count on comment', ($) async {
      await $.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open_sheet_button'),
              onPressed: () =>
                  ThreadedDiscussionSheet.show(context, post: testPost),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      await $(const Key('open_sheet_button')).tap();
      await $.pumpAndSettle();

      // Pastor Thomas's comment (c1_1) has 4 pray reactions initially
      final prayBtn = $(const Key('comment_reaction_pray_c1_1'));
      expect(prayBtn, findsOneWidget);

      await prayBtn.tap();
      await $.pumpAndSettle();

      // Incremented reaction tally
      final comments = await commentRepo.getComments(postId: '1');
      final c1 = comments.firstWhere((c) => c.id == 'c1_1');
      expect(c1.reactions['pray'], 5);
    });

    patrolWidgetTest(
      'Submitting a top-level reply adds it to discussion thread',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () =>
                    ThreadedDiscussionSheet.show(context, post: testPost),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        await $(const Key('open_sheet_button')).tap();
        await $.pumpAndSettle();

        // Enter comment text
        await $(const Key('comment_input_field')).enterText(
          'Praying for peaceful sleep and gentle rhythms this evening.',
        );
        await $.pumpAndSettle();

        // Select tone chip
        await $('[Prayer]').tap();
        await $.pumpAndSettle();

        // Submit comment
        await $(const Key('submit_comment_button')).tap();
        await $.pumpAndSettle();

        // Verify comment is now visible in the list
        expect(
          $('Praying for peaceful sleep and gentle rhythms this evening.'),
          findsOneWidget,
        );
        expect($('Hannah W. (Dallas)'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Replying to a specific comment activates reply banner and creates nested reply',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () =>
                    ThreadedDiscussionSheet.show(context, post: testPost),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        await $(const Key('open_sheet_button')).tap();
        await $.pumpAndSettle();

        // Tap reply button on Pastor Thomas's comment
        await $(const Key('reply_button_c1_1')).tap();
        await $.pumpAndSettle();

        // Verify reply banner
        expect($('Replying to @Pastor Thomas (Melbourne)'), findsOneWidget);
        expect($(const Key('cancel_reply_target_button')), findsOneWidget);

        // Enter reply text
        await $(const Key('comment_input_field'))
            .enterText('That scripture from Hebrews has helped me as well.');
        await $.pumpAndSettle();

        // Select tone
        await $('[Comfort Only]').tap();
        await $.pumpAndSettle();

        // Submit reply
        await $(const Key('submit_comment_button')).tap();
        await $.pumpAndSettle();

        // Verify reply banner cleared
        expect($('Replying to @Pastor Thomas (Melbourne)'), findsNothing);

        // Verify nested comment in list
        expect(
          $('That scripture from Hebrews has helped me as well.'),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest('Closing sheet with close button pops dialog', ($) async {
      await $.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open_sheet_button'),
              onPressed: () =>
                  ThreadedDiscussionSheet.show(context, post: testPost),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      await $(const Key('open_sheet_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('close_discussion_sheet_button')), findsOneWidget);
      await $(const Key('close_discussion_sheet_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('threaded_discussion_sheet_title')), findsNothing);
    });
  });
}
