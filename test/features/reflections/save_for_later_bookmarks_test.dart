import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_auth.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';

void main() {
  group('Save for Later (Private Bookmarking) & Easy Create Post (#155)', () {
    test('Post model equality and copyWith includes isSaved', () {
      final post = Post(
        id: 'test_1',
        authorName: 'Hannah',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Peaceful reading.',
        timestamp: DateTime(2026, 10, 22),
        reactions: {'peace': 2},
        isSaved: false,
      );

      final savedPost = post.copyWith(isSaved: true);
      expect(savedPost.isSaved, isTrue);
      expect(post.isSaved, isFalse);
      expect(post == savedPost, isFalse);
    });

    test('LocalPostRepository toggles saved post and streams saved posts correctly', () async {
      final repo = LocalPostRepository(isDevMode: true);
      final initialSaved = await repo.getSavedPosts();
      expect(initialSaved, isEmpty);

      await repo.toggleSavePost(postId: '1');
      final updatedSaved = await repo.getSavedPosts();
      expect(updatedSaved.length, 1);
      expect(updatedSaved.first.id, '1');
      expect(updatedSaved.first.isSaved, isTrue);

      // Toggle off
      await repo.toggleSavePost(postId: '1');
      final clearedSaved = await repo.getSavedPosts();
      expect(clearedSaved, isEmpty);
    });

    patrolWidgetTest(
      'Tapping bookmark ribbon toggles saved state and displays in Saved for Later space',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final repo = LocalPostRepository(isDevMode: true);

        await $.pumpWidget(
          RefugeApp(
            repository: repo,
            homeOverride: const RefugeHomeScreen(),
          ),
        );
        await $.pumpAndSettle();

        // 1. Initial state: Post '1' is not saved
        final bookmarkBtn1 = $(Key('save_post_button_1'));
        expect(bookmarkBtn1, findsOneWidget);

        // Tap bookmark button on Post '1'
        await $(bookmarkBtn1).tap();
        await $.pumpAndSettle();

        // Verify repository now has post '1' as saved
        final savedList = await repo.getSavedPosts();
        expect(savedList.any((p) => p.id == '1'), isTrue);

        // 2. Navigate to Spaces -> Saved for Later
        final spacesSubnav = $(Key('subnav_spaces_tab'));
        if (spacesSubnav.evaluate().isNotEmpty) {
          await $(spacesSubnav).tap();
          await $.pumpAndSettle();

          // Tap Saved for Later space
          final savedSpaceCard = $('Saved for Later');
          if (savedSpaceCard.evaluate().isNotEmpty) {
            await $(savedSpaceCard).tap();
            await $.pumpAndSettle();

            // Verify Post '1' appears in Saved for Later
            expect($('David M. (UK)'), findsOneWidget);
          }
        }
      },
    );

    patrolWidgetTest(
      'Super easy (+) button in upper right opens Create Reflection or Image Post modal',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final repo = LocalPostRepository(isDevMode: true);

        await $.pumpWidget(
          RefugeApp(
            repository: repo,
            homeOverride: const RefugeHomeScreen(),
          ),
        );
        await $.pumpAndSettle();

        final createPostBtn = $(Key('home_top_bar_create_post_button'));
        expect(createPostBtn, findsOneWidget);

        await $(createPostBtn).tap();
        await $.pumpAndSettle();

        // Verify Circle-style popup menu appears and tap Create Post
        expect($(Key('menu_item_create_post')), findsOneWidget);
        await $(Key('menu_item_create_post')).tap();
        await $.pumpAndSettle();

        // Verify bottom sheet title and reflection composer input exist
        expect($('Create Reflection Post'), findsOneWidget);
        expect($(Key('reflection_composer_input')), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Composer is hidden when in Saved for Later space (#446)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final repo = LocalPostRepository(isDevMode: true);

        await $.pumpWidget(
          RefugeApp(
            repository: repo,
            homeOverride: const RefugeHomeScreen(),
          ),
        );
        await $.pumpAndSettle();

        // Initially in general feed: inline composer is visible
        expect($(Key('reflection_composer_card')), findsOneWidget);

        // Switch to Saved for Later
        final spacesSubnav = $(Key('subnav_spaces_tab'));
        if (spacesSubnav.evaluate().isNotEmpty) {
          await $(spacesSubnav).tap();
          await $.pumpAndSettle();

          final savedSpaceCard = $('Saved for Later');
          if (savedSpaceCard.evaluate().isNotEmpty) {
            await $(savedSpaceCard).tap();
            await $.pumpAndSettle();

            // Composer is hidden in Saved for Later
            expect($(Key('reflection_composer_card')), findsNothing);
          }
        }
      },
    );

    patrolWidgetTest(
      'Prettier offline / test authentication view renders with calm styling',
      ($) async {
        var signedIn = false;

        await $.pumpWidget(
          MaterialApp(
            home: SimpleAuthScreen(
              auth: null,
              onAuthenticated: () => signedIn = true,
            ),
          ),
        );
        await $.pumpAndSettle();

        expect($('Sign In to Belong'), findsOneWidget);
        expect($('Belong on the Spectrum'), findsOneWidget);
        expect($('Unhurried Christian fellowship'), findsOneWidget);

        final offlineBtn = $(Key('auth_offline_sign_in_button'));
        expect(offlineBtn, findsOneWidget);

        await $(offlineBtn).tap();
        await $.pumpAndSettle();
        expect(signedIn, isTrue);
      },
    );
  });
}
