import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Headless Patrol (`patrolWidgetTest`) for the soft-launch critical path.
///
/// These cases run under `flutter test --coverage`, so they land in
/// `coverage/lcov.info` without a device. Device Patrol (`patrolTest` in
/// `integration_test/patrol_ftl_*.dart`) and Maestro stay smoke-only.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageService.instance.clear();
  });

  tearDown(ProfileStorageService.instance.clear);

  void usePhoneSurface(PatrolTester $) {
    $.tester.view.devicePixelRatio = 1;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown($.tester.view.resetPhysicalSize);
    addTearDown($.tester.view.resetDevicePixelRatio);
  }

  patrolWidgetTest('Scenario: Home chrome, Spaces to Links, then Vote & Feedback', ($) async {
    // Given a signed-out dev build that is allowed to show Home for this
    // widget harness (the members-only wall is the next scenario).
    usePhoneSurface($);
    await $.pumpWidgetAndSettle(RefugeApp(repository: LocalPostRepository()));

    // Then the home chrome is on screen, including the narrow Vote chip.
    expect($('Belong'), findsWidgets);
    expect($(const Key('subnav_feed_tab')), findsOneWidget);
    expect($(const Key('subnav_spaces_tab')), findsOneWidget);
    expect($(const Key('open_feedback_and_voting_button')), findsOneWidget);
    expect($('Home'), findsOneWidget);

    // When the member opens Spaces and scrolls to Links.
    await $(const Key('subnav_spaces_tab')).tap();
    await $.pumpAndSettle();
    expect($(const Key('belong_spaces_directory_list')), findsOneWidget);
    await $.tester.scrollUntilVisible(
      find.text('Community Guidelines'),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('belong_spaces_directory_list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect($('LINKS'), findsOneWidget);
    expect($('DFW Church'), findsOneWidget);
    expect($('Download the Android App'), findsOneWidget);

    // When they open a pending link.
    await $(find.text('Community Guidelines')).tap();
    await $.pumpAndSettle();
    expect($('Community Guidelines'), findsWidgets);
    expect($('Return to Feed'), findsOneWidget);

    // Then back returns to Spaces, and Feed returns to the reflections.
    await $(find.text('Return to Feed')).tap();
    await $.pumpAndSettle();
    expect($(const Key('belong_spaces_directory_list')), findsOneWidget);
    await $(const Key('subnav_feed_tab')).tap();
    await $.pumpAndSettle();
    expect($(find.byType(ReflectionCard)), findsWidgets);

    // When they open Vote & Feedback.
    await $(const Key('open_feedback_and_voting_button')).tap();
    await $.pumpAndSettle();
    expect($('Belong Roadmap & Feedback'), findsOneWidget);
    expect($('Share Feedback'), findsOneWidget);
  });

  patrolWidgetTest('Scenario: an unsigned member stays on the sign-in wall', ($) async {
    // Given the members-only gate and no session.
    usePhoneSurface($);
    await $.pumpWidgetAndSettle(
      RefugeApp(
        repository: LocalPostRepository(),
        enforceSignIn: true,
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
          appFlavorProvider.overrideWithValue(AppFlavor.dev),
        ],
      ),
    );

    // Then Home, Spaces, and Vote & Feedback stay behind the wall.
    expect($(const Key('auth_gate_sign_in_wall')), findsOneWidget);
    expect($(const Key('open_feedback_and_voting_button')), findsNothing);
    expect($(const Key('subnav_spaces_tab')), findsNothing);
    expect($('Vote & Feedback'), findsNothing);
  });
}
