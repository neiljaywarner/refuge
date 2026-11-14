import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  test('screenshare is the Stream capability name', () {
    expect(CallPermission.screenshare.alias, 'screenshare');
    expect(capabilitiesIncludeScreenshare(const [CallPermission.screenshare]), isTrue);
    expect(capabilitiesIncludeScreenshare(const [CallPermission.sendVideo]), isFalse);
  });

  test('a member can share on web and Android when Stream grants it', () {
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: false,
        organizerAllowsGuests: false,
        platform: GroupCallSharePlatform.web,
      ),
      isTrue,
    );
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: false,
        organizerAllowsGuests: false,
        platform: GroupCallSharePlatform.android,
      ),
      isTrue,
    );
  });

  test('a missing screenshare grant hides sharing on every platform', () {
    for (final platform in GroupCallSharePlatform.values) {
      expect(
        groupCallCanShare(
          screenshareGranted: false,
          guest: false,
          organizerAllowsGuests: true,
          platform: platform,
        ),
        isFalse,
        reason: platform.name,
      );
    }
  });

  test('a guest cannot share until the organizer allows it', () {
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: true,
        organizerAllowsGuests: false,
        platform: GroupCallSharePlatform.web,
      ),
      isFalse,
    );
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: true,
        organizerAllowsGuests: true,
        platform: GroupCallSharePlatform.android,
      ),
      isTrue,
    );
    expect(
      groupCallCanShare(
        screenshareGranted: false,
        guest: true,
        organizerAllowsGuests: true,
        platform: GroupCallSharePlatform.web,
      ),
      isFalse,
    );
  });

  test('iOS and desktop can watch a share but cannot publish one yet', () {
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: false,
        organizerAllowsGuests: true,
        platform: GroupCallSharePlatform.ios,
      ),
      isFalse,
    );
    expect(
      groupCallCanShare(
        screenshareGranted: true,
        guest: false,
        organizerAllowsGuests: true,
        platform: GroupCallSharePlatform.other,
      ),
      isFalse,
    );
    expect(groupCallPlatformCanPublish(GroupCallSharePlatform.web), isTrue);
    expect(groupCallPlatformCanPublish(GroupCallSharePlatform.ios), isFalse);
  });

  test('nobody is presenting until a screen-share track is on', () {
    final view = groupCallShareView(
      screenshareGranted: true,
      guest: false,
      organizerAllowsGuests: false,
      platform: GroupCallSharePlatform.web,
      participants: const [
        GroupCallShareParticipant(
          userId: 'member-1',
          name: 'Fellow Member',
          local: true,
          screenShareEnabled: false,
        ),
      ],
    );

    expect(view.canShare, isTrue);
    expect(view.someoneSharing, isFalse);
    expect(view.presenter, isNull);
    expect(view.localSharing, isFalse);
  });

  test('the local sharer is the presenter, ahead of a remote sharer', () {
    final view = groupCallShareView(
      screenshareGranted: true,
      guest: false,
      organizerAllowsGuests: false,
      platform: GroupCallSharePlatform.android,
      participants: const [
        GroupCallShareParticipant(
          userId: 'guest-1',
          name: 'Alex',
          local: false,
          screenShareEnabled: true,
        ),
        GroupCallShareParticipant(
          userId: 'member-1',
          name: 'Fellow Member',
          local: true,
          screenShareEnabled: true,
        ),
      ],
    );

    expect(view.someoneSharing, isTrue);
    expect(view.localSharing, isTrue);
    expect(view.presenter?.userId, 'member-1');
    expect(view.presenter?.name, 'Fellow Member');
    expect(view.presenter?.local, isTrue);
  });

  test('a remote sharer is named when the local person is not sharing', () {
    final view = groupCallShareView(
      screenshareGranted: false,
      guest: true,
      organizerAllowsGuests: false,
      platform: GroupCallSharePlatform.ios,
      participants: const [
        GroupCallShareParticipant(
          userId: 'member-1',
          name: 'member@belongonthespectrum.com',
          local: false,
          screenShareEnabled: true,
        ),
      ],
    );

    expect(view.canShare, isFalse);
    expect(view.someoneSharing, isTrue);
    expect(view.localSharing, isFalse);
    expect(view.presenter?.userId, 'member-1');
    expect(view.presenter?.name, 'member@belongonthespectrum.com');
    expect(view.presenter?.local, isFalse);
  });

  test('a live screen-share track counts and a muted one does not', () {
    final sharing = _participant(userId: 'member-1', local: true, screenShare: TrackState.local());
    final muted = _participant(
      userId: 'guest-1',
      local: false,
      screenShare: TrackState.remote(muted: true),
    );
    final absent = _participant(userId: 'guest-2', local: false);

    expect(sharing.isScreenShareEnabled, isTrue);
    expect(sharing.screenShareTrack, isNotNull);
    expect(groupCallShareParticipant(sharing).screenShareEnabled, isTrue);
    expect(groupCallShareParticipant(muted).screenShareEnabled, isFalse);
    expect(groupCallShareParticipant(absent).screenShareEnabled, isFalse);

    final view = groupCallShareViewFromCall(
      capabilities: const [CallPermission.screenshare],
      guest: false,
      custom: const {},
      platform: GroupCallSharePlatform.web,
      participants: [sharing, muted, absent],
    );
    expect(view.presenter?.userId, 'member-1');
    expect(view.localSharing, isTrue);
  });

  test('a second session with the same user id is the one on the share tile', () {
    final idle = _participant(userId: 'guest-2', local: false);
    final sharing = CallParticipantState(
      userId: 'guest-2',
      roles: const [],
      name: 'Alex',
      // ignore: deprecated_member_use
      custom: const {},
      sessionId: 'session-guest-2-b',
      trackIdPrefix: 'guest-2-b',
      publishedTracks: {SfuTrackType.screenShare: TrackState.remote()},
    );
    final presenter = groupCallPresenter([
      groupCallShareParticipant(idle),
      groupCallShareParticipant(sharing),
    ]);

    final match = groupCallPresenterParticipant(
      presenter: presenter!,
      participants: [idle, sharing],
    );

    expect(presenter.userId, 'guest-2');
    expect(match?.sessionId, 'session-guest-2-b');
    expect(match?.isScreenShareEnabled, isTrue);
  });

  test('guest screen share stays off unless the call custom flag is true', () {
    expect(organizerAllowsGuestScreenShare(const {}), isFalse);
    expect(organizerAllowsGuestScreenShare(const {guestScreenShareCustomKey: false}), isFalse);
    expect(organizerAllowsGuestScreenShare(const {guestScreenShareCustomKey: 'true'}), isFalse);
    expect(organizerAllowsGuestScreenShare(const {guestScreenShareCustomKey: true}), isTrue);
  });
}

CallParticipantState _participant({
  required String userId,
  required bool local,
  TrackState? screenShare,
}) => CallParticipantState(
  userId: userId,
  roles: const [],
  name: 'Fellow Member',
  // The public constructor still requires this deprecated map.
  // ignore: deprecated_member_use
  custom: const {},
  sessionId: 'session-$userId',
  trackIdPrefix: userId,
  isLocal: local,
  publishedTracks: {SfuTrackType.screenShare: ?screenShare},
);
