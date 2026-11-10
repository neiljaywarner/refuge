import 'package:flutter_test/flutter_test.dart';

import 'step/group_call_mic_steps.dart';

void main() {
  testWidgets('A muted join publishes audio on the first unmute', (
    tester,
  ) async {
    await theCallJoinedWithTheMicrophoneOff(tester);
    await theMemberUnmutes(tester);
    await theMicrophoneIconIsOn(tester);
    await theFirstMicrophoneRequestPublishesAudio(tester);
  });

  testWidgets('Three mute and unmute cycles keep the track alive', (
    tester,
  ) async {
    await theMicrophoneIsAlreadySending(tester);
    await theMemberCompletesThreeMuteAndUnmuteCycles(tester);
    await everyMuteKeptTheTrackAlive(tester);
  });

  testWidgets('An external mute updates the icon', (tester) async {
    await theMemberHasUnmuted(tester);
    await theCallMutesTheMicrophoneFromOutside(tester);
    await theMicrophoneIconIsOff(tester);
    await theNextTapUnmutes(tester);
  });

  testWidgets('A failed microphone change leaves the icon', (tester) async {
    await theMemberHasUnmuted(tester);
    await theNextMicrophoneChangeFails(tester);
    await theMicrophoneIconIsOn(tester);
    await theCalmMicrophoneSnackbarIsShown(tester);
  });

  testWidgets('A guest without send-audio sees the snackbar', (tester) async {
    await aGuestJoinedWithoutSendAudio(tester);
    await theMemberUnmutes(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await theMicrophoneIconIsOff(tester);
    await theCalmMicrophoneSnackbarIsShown(tester);
  });

  testWidgets('Web autoplay offers a tap to hear the room', (tester) async {
    await theBrowserIsBlockingRemoteAudio(tester);
    await theCallShowsTapToHearTheRoom(tester);
    await theMemberTapsToHearTheRoom(tester);
    await resumeWebAudioPlaybackIsCalled(tester);
  });

  testWidgets('The speaker is on by default', (tester) async {
    await aPreviewJoinPlan(tester);
    await theSpeakerStartsOn(tester);
  });

  testWidgets('The camera still toggles beside the microphone', (tester) async {
    await theCallJoinedWithTheMicrophoneOff(tester);
    await theMemberTurnsTheCameraOn(tester);
    await theMemberUnmutes(tester);
    await theCameraIconIsOn(tester);
    await theMicrophoneIconIsOn(tester);
  });

  testWidgets('A guest does not see host controls', (tester) async {
    await aGuestIsInTheCall(tester);
    await removeAndEndAreHidden(tester);
  });

  testWidgets('A host sees host controls', (tester) async {
    await aHostCreatedTheCall(tester);
    await removeAndEndAreShown(tester);
  });
}
