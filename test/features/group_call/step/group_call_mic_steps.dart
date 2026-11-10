import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_audio_checks.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/stream_group_call_page.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'group_call_mic_world.dart';

Future<void> theCallJoinedWithTheMicrophoneOff(WidgetTester tester) async {
  micWorld = GroupCallMicWorld();
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
  expect(micWorld!.requests, isEmpty);
  expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
}

Future<void> theMicrophoneIsAlreadySending(WidgetTester tester) async {
  micWorld = GroupCallMicWorld()..beginWithMicrophoneOn();
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
  await tester.pump();
}

Future<void> theMemberHasUnmuted(WidgetTester tester) async {
  await theCallJoinedWithTheMicrophoneOff(tester);
  await theMemberUnmutes(tester);
}

Future<void> aGuestJoinedWithoutSendAudio(WidgetTester tester) async {
  micWorld = GroupCallMicWorld(grants: const [CallPermission.sendVideo]);
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
}

Future<void> theBrowserIsBlockingRemoteAudio(WidgetTester tester) async {
  micWorld = GroupCallMicWorld()..blockWebPlayback();
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
  await tester.pump();
}

Future<void> aGuestIsInTheCall(WidgetTester tester) async {
  micWorld = GroupCallMicWorld();
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
}

Future<void> aHostCreatedTheCall(WidgetTester tester) async {
  micWorld = GroupCallMicWorld(signedInMember: true, createdByMe: true);
  addTearDown(() async => micWorld?.close());
  await micWorld!.pump(tester);
}

Future<void> theMemberUnmutes(WidgetTester tester) => micWorld!.tapMic(tester);

Future<void> theMemberTurnsTheCameraOn(WidgetTester tester) =>
    micWorld!.tapCamera(tester);

Future<void> theMemberCompletesThreeMuteAndUnmuteCycles(
  WidgetTester tester,
) async {
  for (var cycle = 0; cycle < 3; cycle++) {
    await micWorld!.tapMic(tester);
    await micWorld!.tapMic(tester);
  }
}

Future<void> theCallMutesTheMicrophoneFromOutside(WidgetTester tester) async {
  micWorld!.muteFromOutside();
  await tester.pump();
}

Future<void> theNextTapUnmutes(WidgetTester tester) async {
  final before = micWorld!.requests.length;
  await micWorld!.tapMic(tester);
  expect(micWorld!.requests.last.enabled, isTrue);
  expect(micWorld!.requests.length, before + 1);
}

Future<void> theNextMicrophoneChangeFails(WidgetTester tester) async {
  micWorld!.failNext();
  await micWorld!.tapMic(tester);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> theMemberTapsToHearTheRoom(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('group_call_hear_room')));
  await tester.pump();
}

Future<void> theMicrophoneIconIsOn(WidgetTester tester) async {
  expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
}

Future<void> theMicrophoneIconIsOff(WidgetTester tester) async {
  expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
  expect(find.byIcon(Icons.mic_rounded), findsNothing);
}

Future<void> theCameraIconIsOn(WidgetTester tester) async {
  expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
}

Future<void> theFirstMicrophoneRequestPublishesAudio(
  WidgetTester tester,
) async {
  expect(micWorld!.requests, hasLength(1));
  expect(micWorld!.requests.single.enabled, isTrue);
  expect(
    firstUnmutePublishesMicrophone(
      microphoneStartsEnabled: false,
      enabling: true,
    ),
    isTrue,
  );
  expect(micWorld!.localAudioTrackPresent, isTrue);
}

Future<void> everyMuteKeptTheTrackAlive(WidgetTester tester) async {
  final mutes = micWorld!.requests.where((request) => !request.enabled);
  expect(mutes.length, greaterThanOrEqualTo(3));
  expect(mutes.every((request) => request.stopTrackOnMute == false), isTrue);
  expect(micWorld!.localAudioTrackPresent, isTrue);
}

Future<void> theCalmMicrophoneSnackbarIsShown(WidgetTester tester) async {
  expect(
    find.text('The microphone stayed as it was. Try again.'),
    findsOneWidget,
  );
  expect(find.textContaining('microphone unavailable'), findsNothing);
  expect(find.textContaining('@'), findsNothing);
}

Future<void> theCallShowsTapToHearTheRoom(WidgetTester tester) async {
  expect(find.text('Tap to hear the room'), findsOneWidget);
}

Future<void> resumeWebAudioPlaybackIsCalled(WidgetTester tester) async {
  expect(micWorld!.resumes, 1);
}

Future<void> aPreviewJoinPlan(WidgetTester tester) async {}

Future<void> theSpeakerStartsOn(WidgetTester tester) async {
  final plan = streamCallConnectPlan(
    credentials: const StreamCallCredentials(
      apiKey: 'public-key',
      token: 'aaa.bbb.ccc',
      userId: 'member-1',
      callId: 'monthly',
      expiresAt: 30,
    ),
    displayName: 'Fellow Member',
  );
  final options = previewCallConnectOptions(
    cameraStartsEnabled: plan.cameraStartsEnabled,
    microphoneStartsEnabled: plan.microphoneStartsEnabled,
    speakerStartsOn: plan.speakerStartsOn,
  );
  expect(plan.speakerStartsOn, isTrue);
  expect(options.speakerDefaultOn, isTrue);
  expect(plan.microphoneStartsEnabled, isFalse);
  expect(options.microphone.isDisabled, isTrue);
}

Future<void> removeAndEndAreHidden(WidgetTester tester) async {
  expect(find.byKey(const Key('group_call_remove_button')), findsNothing);
  expect(find.byKey(const Key('group_call_end_button')), findsNothing);
}

Future<void> removeAndEndAreShown(WidgetTester tester) async {
  expect(find.byKey(const Key('group_call_remove_button')), findsOneWidget);
  expect(find.byKey(const Key('group_call_end_button')), findsOneWidget);
}
