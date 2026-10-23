import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

void main() {
  group('Member Profile Activity Counters & Drill-Down Unit TDD', () {
    late LocalPostRepository postRepo;
    late LocalCommentRepository commentRepo;

    setUp(() {
      postRepo = LocalPostRepository(isDevMode: true);
      commentRepo = LocalCommentRepository(isDevMode: true);
    });

    test('getPostsByAuthor returns posts filtered by member name', () async {
      final davidPosts = await postRepo.getPostsByAuthor(authorName: 'David M. (UK)');
      expect(davidPosts.length, 1);
      expect(davidPosts.first.authorName, 'David M. (UK)');
      expect(davidPosts.first.content, contains('routine has been disorienting'));

      final nathanPosts = await postRepo.getPostsByAuthor(authorName: 'Nathan K. (Texas)');
      expect(nathanPosts.length, 1);
      expect(nathanPosts.first.content, contains('reverberation decay'));
    });

    test('getCommentsByAuthor returns comments authored by member', () async {
      final davidComments = await commentRepo.getCommentsByAuthor(authorName: 'David M. (UK)');
      expect(davidComments.length, 1);
      expect(davidComments.first.content, contains('brings a lot of reassurance today'));

      final pastorComments = await commentRepo.getCommentsByAuthor(authorName: 'Pastor Thomas (Melbourne)');
      expect(pastorComments.length, 1);
      expect(pastorComments.first.content, contains('Hebrews 4:10 reminds us'));
    });
  });

  group('Member Profile Activity Counters BDD Widget Tests', () {
    Widget buildHarness({Widget? home, LocalPostRepository? customPostRepo}) {
      final repo = customPostRepo ?? LocalPostRepository(isDevMode: true);
      return RefugeApp(
        repository: repo,
        homeOverride: home,
      );
    }

    patrolWidgetTest(
      'Tapping author on ReflectionCard opens profile dialog with posts & comments count',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildHarness());
        await $.pumpAndSettle();

        // 1. Verify David M. (UK) post is rendered in feed
        expect($(Key('author_tap_target_1')), findsOneWidget);

        // 2. Tap on author name to open profile
        await $(Key('author_tap_target_1')).tap();
        await $.pumpAndSettle();

        // 3. Verify dialog header
        expect($(Key('other_member_profile_name')), findsOneWidget);
        expect($(find.textContaining('David M. (UK)')), findsWidgets);
        expect($(find.textContaining('Transitioning to a new routine')), findsWidgets);

        // 4. Verify activity counter badges: 1 Post and 1 Comment
        expect($(Key('profile_activity_posts_tab')), findsOneWidget);
        expect($(Key('profile_activity_comments_tab')), findsOneWidget);
        expect($(Key('profile_posts_count_badge')), findsOneWidget);
        expect($(Key('profile_comments_count_badge')), findsOneWidget);
        expect($('1'), findsWidgets);

        // 5. In Posts view, verify post card is visible with reaction counter
        expect($(Key('author_post_card_1')), findsOneWidget);
        expect($(Key('author_post_card_1')).$('6 Praying'), findsOneWidget);

        // 6. Tap reaction to like post from profile
        await $(Key('author_post_card_1')).$('6 Praying').tap();
        await $.pumpAndSettle();
        expect($(Key('author_post_card_1')).$('7 Praying'), findsOneWidget);

        // 7. Switch to Comments tab
        await $(Key('profile_activity_comments_tab')).tap();
        await $.pumpAndSettle();

        // 8. Verify authored comment is displayed
        expect($(Key('author_comment_card_c1_1_reply')), findsOneWidget);
        expect($(find.textContaining('reassurance today')), findsOneWidget);

        // 9. Close dialog with Done button
        await $(Key('profile_done_button')).tap();
        await $.pumpAndSettle();

        expect($(Key('other_member_profile_name')), findsNothing);
      },
    );

    patrolWidgetTest(
      'Tapping a member in Members Directory opens profile with activity counters',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          buildHarness(
            home: const Scaffold(
              body: BelongMembersDirectoryView(),
            ),
          ),
        );
        await $.pumpAndSettle();

        // Find Nathan K. card in directory
        final nathanCard = $(Key('dev_member_card_nathan_k___texas_'));
        expect(nathanCard, findsOneWidget);

        // Tap Nathan K. card
        await nathanCard.tap();
        await $.pumpAndSettle();

        // Verify profile opened
        expect($(find.textContaining('Nathan K. (Texas)')), findsWidgets);
        expect($(find.textContaining('Church Acoustics')), findsWidgets);
        expect($(Key('profile_activity_posts_tab')), findsOneWidget);

        // Close
        await $(Key('other_member_profile_close_button')).tap();
        await $.pumpAndSettle();

        expect($(Key('other_member_profile_name')), findsNothing);
      },
    );
  });
}
