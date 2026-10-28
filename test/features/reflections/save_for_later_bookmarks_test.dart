import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_auth.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReflectionMirror implements ReflectionMirror {
  _FakeReflectionMirror(this.cloudPosts);

  final List<Post> cloudPosts;

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async =>
      cloudPosts.where((p) => p.spaceKey == spaceKey).toList();

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream<Post>.empty();

  @override
  Future<void> upsertPost(Post post) async {}

  @override
  Future<void> incrementReaction({required String postId, required String column}) async {}

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Save for Later (Private Bookmarking) & Easy Create Post (#155, #669)', () {
    test('Post model equality, copyWith, and JSON serialization include isSaved (#669)', () {
      final post = Post(
        id: 'test_1',
        authorName: 'Hannah',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        specialInterestTag: 'Sacred Music',
        content: 'Peaceful reading.',
        timestamp: DateTime.utc(2026, 10, 22, 12, 30),
        reactions: {'peace': 2},
        isSaved: false,
      );

      final savedPost = post.copyWith(isSaved: true);
      expect(savedPost.isSaved, isTrue);
      expect(post.isSaved, isFalse);
      expect(post == savedPost, isFalse);

      final roundTrip = Post.fromJson(savedPost.toJson());
      expect(roundTrip, equals(savedPost));
      expect(roundTrip.isSaved, isTrue);
      expect(roundTrip.specialInterestTag, 'Sacred Music');
    });

    test(
      'SavedPostsStore & LocalPostRepository persist bookmarks across restarts (#669)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo1 = LocalPostRepository(isDevMode: true);
        await repo1.toggleSavePost(postId: '1');

        final saved1 = await repo1.getSavedPosts();
        expect(saved1.map((p) => p.id), contains('1'));

        final digest1 = await repo1.getQuietDigest(spaceKey: 'saved_for_later');
        expect(
          digest1,
          'Private sanctuary • 1 saved reflection kept for quiet, unhurried reading.',
        );

        // Simulate app restart with a fresh LocalPostRepository instance reading SharedPreferences
        final repo2 = LocalPostRepository(isDevMode: true);
        final savedAfterRestart = await repo2.getSavedPosts();
        expect(savedAfterRestart.length, 1);
        expect(savedAfterRestart.first.id, '1');
        expect(savedAfterRestart.first.isSaved, isTrue);
      },
    );

    test(
      'AppwritePostRepository & preferPost preserve isSaved across cloud merges and bookmark cloud-only posts (#669)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final cloudPost = Post(
          id: 'cloud_77',
          authorName: 'Miriam K. (Toronto)',
          spaceKey: 'prayer',
          toneTag: '[Prayer Request]',
          content: 'Cloud-origin reflection for quiet bookmarking.',
          timestamp: DateTime.utc(2026, 10, 27, 18, 0),
          reactions: {'pray': 3},
          isSaved: false,
        );

        final fallback = LocalPostRepository(isDevMode: true);
        final appwriteRepo = AppwritePostRepository(
          fallback: fallback,
          mirror: _FakeReflectionMirror([cloudPost]),
          isDevMode: true,
        );

        // Fetch posts so cloud_77 is discovered and cached
        final initialFeed = await appwriteRepo.getPosts(spaceKey: 'prayer');
        expect(initialFeed.any((p) => p.id == 'cloud_77'), isTrue);

        // Bookmark the cloud-origin post
        await appwriteRepo.toggleSavePost(postId: 'cloud_77');

        // Verify getSavedPosts includes cloud_77 with isSaved: true
        final saved = await appwriteRepo.getSavedPosts();
        expect(saved.any((p) => p.id == 'cloud_77' && p.isSaved), isTrue);

        // Verify subsequent cloud fetch does NOT overwrite isSaved: true with false
        final refreshedFeed = await appwriteRepo.getPosts(spaceKey: 'prayer');
        final refreshedCloudPost = refreshedFeed.firstWhere((p) => p.id == 'cloud_77');
        expect(refreshedCloudPost.isSaved, isTrue);
      },
    );

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

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        // 1. Initial state: Post '1' is not saved
        final bookmarkBtn1 = $(Key('save_post_button_1'));
        expect(bookmarkBtn1, findsOneWidget);

        // Tap bookmark button on Post '1'
        await $(bookmarkBtn1).tap();
        await $.pumpAndSettle();

        // Verify calm confirmation SnackBar and origin space badge appear (#669)
        expect($('🔖 Saved to your private Saved for Later space.'), findsOneWidget);
        expect($(Key('saved_post_origin_space_1')), findsOneWidget);
        expect($('🔖 Saved from 🙏 Prayer Sanctuary'), findsOneWidget);

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

            // Verify Post '1' appears in Saved for Later with origin space context
            expect($('David M. (UK)'), findsOneWidget);
            expect($(Key('saved_post_origin_space_1')), findsOneWidget);
          }
        }
      },
    );

    patrolWidgetTest(
      'Tapping Undo on the Save for Later SnackBar reverses the bookmark toggle (#669)',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final repo = LocalPostRepository(isDevMode: true);

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
        await $.pumpAndSettle();

        await $(Key('save_post_button_1')).tap();
        await $.pumpAndSettle();
        expect((await repo.getSavedPosts()).any((p) => p.id == '1'), isTrue);

        // Tap Undo on the SnackBar
        await $('Undo').tap();
        await $.pumpAndSettle();
        expect(await repo.getSavedPosts(), isEmpty);
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

        await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
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

    patrolWidgetTest('Composer is hidden when in Saved for Later space (#446)', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(600, 1600);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final repo = LocalPostRepository(isDevMode: true);

      await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
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
    });

    patrolWidgetTest('Prettier offline / test authentication view renders with calm styling', (
      $,
    ) async {
      var signedIn = false;

      await $.pumpWidget(
        MaterialApp(home: SimpleAuthScreen(auth: null, onAuthenticated: () => signedIn = true)),
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
    });
  });
}
