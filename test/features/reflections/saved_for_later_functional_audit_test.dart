import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/app.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone M3a: Saved for Later Functional Audit (#846, Bruce Usability #3)', () {
    test('LocalPostRepository: bookmarking a post retains it in watchSavedPosts stream', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalPostRepository();
      
      // Initially, saved posts should be empty
      expect(await repo.getSavedPosts(), isEmpty);

      // Save post '1'
      await repo.toggleSavePost(postId: '1');
      final savedAfterToggle = await repo.getSavedPosts();
      expect(savedAfterToggle.length, equals(1));
      expect(savedAfterToggle.first.id, equals('1'));
      expect(savedAfterToggle.first.isSaved, isTrue);

      // Un-save post '1'
      await repo.toggleSavePost(postId: '1');
      expect(await repo.getSavedPosts(), isEmpty);
    });

    patrolWidgetTest('Tapping bookmark in feed toggles post and reflects in saved state', ($) async {
      SharedPreferences.setMockInitialValues({});
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final repo = LocalPostRepository(isDevMode: true);
      final fakeAnalytics = CommunityAnalyticsService(flavor: AppFlavor.dev);

      await $.pumpWidget(
        RefugeApp(
          repository: repo,
          homeOverride: const RefugeHomeScreen(),
          overrides: [
            communityAnalyticsServiceProvider.overrideWithValue(fakeAnalytics),
          ],
        ),
      );
      await $.pumpAndSettle();

      final bookmarkBtn1 = $(Key('save_post_button_1'));
      expect(bookmarkBtn1, findsOneWidget);

      await $(bookmarkBtn1).tap();
      await $.pumpAndSettle();

      // Verify calm confirmation SnackBar and origin space badge appear (#669)
      expect($('🔖 Saved to your private Saved for Later space.'), findsOneWidget);
      expect($(Key('view_saved_for_later_btn_1')), findsOneWidget);
      expect($('View Saved'), findsOneWidget);
      expect($(Key('saved_post_origin_space_1')), findsOneWidget);
      expect($('🔖 Saved from 🙏 Prayer Sanctuary'), findsOneWidget);

      // Tap View Saved on the SnackBar
      await $('View Saved').tap();
      await $.pumpAndSettle();

      // Verify navigated into Saved for Later space and post '1' is visible
      expect($(Key('saved_post_origin_space_1')), findsOneWidget);
      expect($('David M. (UK)'), findsOneWidget);

      // Verify repository updated
      final savedPosts = await repo.getSavedPosts();
      expect(savedPosts.any((p) => p.id == '1'), isTrue);
    });
  });
}
