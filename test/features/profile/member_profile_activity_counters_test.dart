import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';

void main() {
  group('Member Profile Activity Counters & Drill-Down Unit TDD', () {
    late LocalPostRepository postRepo;
    late LocalCommentRepository commentRepo;

    setUp(() {
      postRepo = LocalPostRepository(isDevMode: true);
      commentRepo = LocalCommentRepository(isDevMode: true);
    });

    test('getPostsByAuthor returns reflections authored by member', () async {
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

        // 5. Switch to Comments tab
        await $(Key('profile_activity_comments_tab')).tap();
        await $.pumpAndSettle();

        expect($(find.textContaining('David M. (UK)')), findsWidgets);
        expect($(find.textContaining('brings a lot of reassurance today')), findsWidgets);

        // 6. Close profile dialog
        await $(Key('other_member_profile_close_button')).tap();
        await $.pumpAndSettle();

        expect($(Key('other_member_profile_name')), findsNothing);
      },
    );

    patrolWidgetTest(
      'Tapping member card in BelongMembersDirectoryView opens dialog with activity counts',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(
          buildHarness(
            home: Scaffold(
              body: BelongMembersDirectoryView(
                onBackToSpaces: () {},
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        // Tap Sarah Chen card in directory
        await $('Sarah Chen').tap();
        await $.pumpAndSettle();

        // Verify profile opened
        expect($(find.textContaining('Sarah Chen')), findsWidgets);
        expect($(find.textContaining('Bible Teacher & Scholar')), findsWidgets);
        expect($(Key('profile_activity_posts_tab')), findsOneWidget);

        // Close
        await $(Key('other_member_profile_close_button')).tap();
        await $.pumpAndSettle();

        expect($(Key('other_member_profile_name')), findsNothing);
      },
    );
  });
}
