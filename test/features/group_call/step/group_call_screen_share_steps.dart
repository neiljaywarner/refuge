import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'group_call_screen_share_world.dart';

Future<void> aGuestJoinedWithScreenshareGranted(WidgetTester tester) async {
  shareWorld = GroupCallScreenShareWorld(guest: true, grants: const [CallPermission.screenshare]);
  addTearDown(() async => shareWorld?.close());
  await shareWorld!.pump(tester);
}

Future<void> theOrganizerHasAllowedGuestsToShare(WidgetTester tester) async {
  shareWorld!.allowGuests();
  await tester.pump();
}

Future<void> theGuestStartsSharing(WidgetTester tester) => shareWorld!.tapShare(tester);

Future<void> aMemberJoinedWithoutScreenshare(WidgetTester tester) async {
  shareWorld = GroupCallScreenShareWorld(member: true, grants: const [CallPermission.sendAudio]);
  addTearDown(() async => shareWorld?.close());
  await shareWorld!.pump(tester);
}

Future<void> aMemberIsSharingOnTheWeb(WidgetTester tester) async {
  shareWorld = GroupCallScreenShareWorld(member: true, grants: const [CallPermission.screenshare]);
  addTearDown(() async => shareWorld?.close());
  await shareWorld!.pump(tester);
  await shareWorld!.tapShare(tester);
}

Future<void> theMemberStopsSharing(WidgetTester tester) => shareWorld!.tapShare(tester);

Future<void> aRemotePersonIsSharing(WidgetTester tester) async {
  shareWorld = GroupCallScreenShareWorld(guest: true);
  addTearDown(() async => shareWorld?.close());
  shareWorld!.remoteShares('Alex');
  await shareWorld!.pump(tester);
  await tester.pump();
}

Future<void> aHostJoinedWithScreenshare(WidgetTester tester) async {
  shareWorld = GroupCallScreenShareWorld(host: true, grants: const [CallPermission.screenshare]);
  addTearDown(() async => shareWorld?.close());
  await shareWorld!.pump(tester);
}

Future<void> theHostAllowsGuestsToShare(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('group_call_guest_share_switch')));
  await tester.pump();
}

Future<void> theShareButtonIsHidden(WidgetTester tester) async {
  expect(find.byKey(const Key('group_call_share_button')), findsNothing);
}

Future<void> theShareButtonShowsStop(WidgetTester tester) async {
  expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
  expect(shareWorld!.shareRequests, contains(true));
}

Future<void> thePresenterLabelSaysYouAreSharing(WidgetTester tester) async {
  expect(find.text('You are sharing'), findsOneWidget);
}

Future<void> thePresenterLabelIsGone(WidgetTester tester) async {
  expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);
}

Future<void> theGridIsShowing(WidgetTester tester) async {
  expect(find.text('grid'), findsOneWidget);
  expect(find.text('share-bytes'), findsNothing);
}

Future<void> thePresenterLabelNamesAlex(WidgetTester tester) async {
  expect(find.text('Alex is sharing'), findsOneWidget);
  expect(find.textContaining('@'), findsNothing);
}

Future<void> theShareTileIsShowing(WidgetTester tester) async {
  expect(find.byKey(const Key('group_call_screen_share_tile')), findsOneWidget);
  expect(find.text('share-bytes'), findsOneWidget);
}

Future<void> theHostSeesLetGuestsShare(WidgetTester tester) async {
  expect(find.text('Let guests share'), findsOneWidget);
}

Future<void> theCallRecordsThatGuestsMayShare(WidgetTester tester) async {
  expect(shareWorld!.guestShareUpdates, [true]);
  expect(shareWorld!.custom[guestScreenShareCustomKey], isTrue);
}
