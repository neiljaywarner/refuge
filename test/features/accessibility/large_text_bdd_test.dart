import 'package:flutter_test/flutter_test.dart';

import 'step/large_text_steps.dart';

void main() {
  testWidgets('The sign-in wall stays on screen', (tester) async {
    await theSignInWallIsShownAtLargeTextScales(tester);
    await theSignInTitleIsVisible(tester);
    await theForgotPasswordControlIsTappable(tester);
    await noTextOverflowIsReported(tester);
  });

  testWidgets('The home feed and bottom nav stay usable', (tester) async {
    await theHomeFeedIsShownAtLargeTextScales(tester);
    await belongAndTheHomeTabAreVisible(tester);
    await theHomeTabIsTappable(tester);
    await noTextOverflowIsReported(tester);
  });

  testWidgets('A reflection and its discussion stay usable', (tester) async {
    await aReflectionCardIsShownAtLargeTextScales(tester);
    await theDiscussionIsOpenAtLargeTextScales(tester);
    await theDiscussionTitleIsVisible(tester);
    await noTextOverflowIsReported(tester);
  });

  testWidgets('Direct messages stay usable', (tester) async {
    await aDirectMessageThreadIsOpenAtLargeTextScales(tester);
    await theMessageTitleIsVisible(tester);
    await noTextOverflowIsReported(tester);
  });

  testWidgets('Sensory and notification settings stay usable', (tester) async {
    await sensorySettingsAreOpenAtLargeTextScales(tester);
    await notificationSettingsAreOpenAtLargeTextScales(tester);
    await theFontScalingChoicesAreVisible(tester);
    await noTextOverflowIsReported(tester);
  });

  testWidgets('The feedback sheet stays usable', (tester) async {
    await theFeedbackSheetIsOpenAtLargeTextScales(tester);
    await theFeedbackTitleIsVisible(tester);
    await noTextOverflowIsReported(tester);
  });

  test(
    'A guest can still join a call at text scale 2.0',
    () {},
    skip:
        'Call UI is only on unmerged PR #905 (cursor/stream-guest-join-2e7c). '
        'Follow-up for #927 after that branch merges.',
  );
}
