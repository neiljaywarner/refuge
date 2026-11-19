import 'package:flutter_test/flutter_test.dart';

import 'step/group_call_screen_share_steps.dart';

void main() {
  testWidgets('A guest cannot share', (tester) async {
    await aGuestJoinedWithScreenshareGranted(tester);
    await theShareButtonIsHidden(tester);
  });

  testWidgets('The organizer allows a guest to share', (tester) async {
    await aGuestJoinedWithScreenshareGranted(tester);
    await theOrganizerHasAllowedGuestsToShare(tester);
    await theGuestStartsSharing(tester);
    await theShareButtonShowsStop(tester);
    await thePresenterLabelSaysYouAreSharing(tester);
  });

  testWidgets('A member without screenshare cannot share', (tester) async {
    await aMemberJoinedWithoutScreenshare(tester);
    await theShareButtonIsHidden(tester);
  });

  testWidgets('Stopping a share returns the grid', (tester) async {
    await aMemberIsSharingOnTheWeb(tester);
    await theMemberStopsSharing(tester);
    await thePresenterLabelIsGone(tester);
    await theGridIsShowing(tester);
  });

  testWidgets('Someone else sharing is the main tile', (tester) async {
    await aRemotePersonIsSharing(tester);
    await thePresenterLabelNamesAlex(tester);
    await theShareTileIsShowing(tester);
  });

  testWidgets('A host can let guests share', (tester) async {
    await aHostJoinedWithScreenshare(tester);
    await theHostSeesLetGuestsShare(tester);
    await theHostAllowsGuestsToShare(tester);
    await theCallRecordsThatGuestsMayShare(tester);
  });
}
