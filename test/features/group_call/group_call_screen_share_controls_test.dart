import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_screen_share_session.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_session_controls.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  testWidgets('the share button stays hidden when sharing is not allowed', (tester) async {
    await tester.pumpWidget(
      _session(canShare: false, sharing: false, onShare: () => fail('shared')),
    );
    expect(find.byKey(const Key('group_call_share_button')), findsNothing);
    expect(find.byIcon(Icons.screen_share_rounded), findsNothing);
  });

  testWidgets('an active share can still be stopped after eligibility is removed', (tester) async {
    var shares = 0;
    await tester.pumpWidget(_session(canShare: false, sharing: true, onShare: () => shares++));

    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Stop sharing'), findsOneWidget);
    await tester.tap(find.byKey(const Key('group_call_share_button')));
    expect(shares, 1);
  });

  testWidgets('the share button asks to start, then to stop', (tester) async {
    var shares = 0;
    var sharing = false;
    Future<void> pump() =>
        tester.pumpWidget(_session(canShare: true, sharing: sharing, onShare: () => shares++));

    await pump();
    expect(find.byIcon(Icons.screen_share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsNothing);
    expect(find.bySemanticsLabel('Share screen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group_call_share_button')));
    expect(shares, 1);
    sharing = true;
    await pump();
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Stop sharing'), findsOneWidget);
  });

  testWidgets('a guest does not see share or the allow switch', (tester) async {
    final room = _Room(guest: true, grants: const [CallPermission.screenshare]);
    addTearDown(room.close);
    await room.pump(tester);

    expect(find.byKey(const Key('group_call_share_button')), findsNothing);
    expect(find.byKey(const Key('group_call_guest_share_switch')), findsNothing);
  });

  testWidgets('a guest can share after the organizer allows it', (tester) async {
    final room = _Room(
      guest: true,
      grants: const [CallPermission.screenshare],
      guestShareAllowed: true,
    );
    addTearDown(room.close);
    await room.pump(tester);

    expect(find.byKey(const Key('group_call_share_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    expect(room.shareRequests, [true]);
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
  });

  testWidgets('a member without the screenshare grant does not see share', (tester) async {
    final room = _Room(grants: const [CallPermission.sendAudio]);
    addTearDown(room.close);
    await room.pump(tester);
    expect(find.byKey(const Key('group_call_share_button')), findsNothing);
  });

  testWidgets('a member share calls setScreenShareEnabled and a failure stays calm', (
    tester,
  ) async {
    final room = _Room(member: true, grants: const [CallPermission.screenshare]);
    addTearDown(room.close);
    await room.pump(tester);

    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    expect(room.shareRequests, [true]);
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);

    room.failNextShare();
    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(room.shareRequests, [true, false]);
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
    expect(find.text('Screen sharing stayed as it was. Try again.'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('the host can allow guests to share', (tester) async {
    final room = _Room(host: true, grants: const [CallPermission.screenshare]);
    addTearDown(room.close);
    await room.pump(tester);

    expect(find.text('Let guests share'), findsOneWidget);
    expect(room.guestShareUpdates, isEmpty);

    await tester.tap(find.byKey(const Key('group_call_guest_share_switch')));
    await tester.pump();

    expect(room.guestShareUpdates, [true]);
    expect(room.custom[guestScreenShareCustomKey], isTrue);
    expect(find.text('Guests still cannot share. Try again.'), findsNothing);
  });

  testWidgets('a failed guest-share update does not commit and stays calm', (tester) async {
    final room = _Room(
      host: true,
      grants: const [CallPermission.screenshare],
      failGuestUpdate: true,
    );
    addTearDown(room.close);
    await room.pump(tester);

    await tester.tap(find.byKey(const Key('group_call_guest_share_switch')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(room.guestShareUpdates, isEmpty);
    expect(room.custom.containsKey(guestScreenShareCustomKey), isFalse);
    expect(find.text('Guests still cannot share. Try again.'), findsOneWidget);
    expect(find.textContaining('metadata'), findsNothing);
  });

  testWidgets('a guest who is sharing can stop after the host disallows it', (tester) async {
    final room = _Room(
      guest: true,
      grants: const [CallPermission.screenshare],
      guestShareAllowed: true,
    );
    addTearDown(room.close);
    await room.pump(tester);

    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);

    room.disallowGuests();
    await tester.pump();

    expect(find.byIcon(Icons.stop_screen_share_rounded), findsOneWidget);
    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    expect(room.shareRequests, [true, false]);
  });

  testWidgets('Android share does not start if the host disallows it during consent', (
    tester,
  ) async {
    final events = <String>[];
    final room = _Room(
      guest: true,
      grants: const [CallPermission.screenshare],
      guestShareAllowed: true,
      platform: GroupCallSharePlatform.android,
    );
    room.androidShare = GroupCallAndroidShareHooks(
      requestConsent: (call) async {
        events.add('consent');
        room.disallowGuests();
        return true;
      },
      startNotification: (call) async {
        events.add('start');
        return true;
      },
      stopNotification: (callCid) async => events.add('stop'),
    );
    addTearDown(room.close);
    await room.pump(tester);

    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(room.shareRequests, isEmpty);
    expect(events, ['consent']);
    expect(find.text('Screen sharing stayed as it was. Try again.'), findsOneWidget);
  });
}

Widget _session({required bool canShare, required bool sharing, required VoidCallback onShare}) =>
    MaterialApp(
      home: Scaffold(
        body: GroupCallSessionControls(
          microphoneEnabled: false,
          cameraEnabled: false,
          host: false,
          canShare: canShare,
          sharing: sharing,
          onShare: onShare,
          onMicrophone: () {},
          onCamera: () {},
          onLeave: () async {},
          onRemove: (userId) async {},
          onEnd: () async {},
        ),
      ),
    );

class _MockCall extends Mock implements Call {}

class _UnusedCallMetadata extends Fake implements CallMetadata {}

class _Room {
  _Room({
    this.guest = false,
    this.host = false,
    this.member = false,
    this.guestShareAllowed = false,
    this.failGuestUpdate = false,
    this.platform = GroupCallSharePlatform.web,
    required this.grants,
  }) {
    when(() => call.state).thenReturn(_states);
    when(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((invocation) async {
      final enabled = invocation.namedArguments[#enabled]! as bool;
      shareRequests.add(enabled);
      if (_failNext) {
        _failNext = false;
        return Result<None>.error('screen share unavailable');
      }
      _sharing = enabled;
      _states.publish(_callState());
      return const Result.success(none);
    });
    when(() => call.update(custom: any(named: 'custom'))).thenAnswer((invocation) async {
      if (failGuestUpdate) {
        return Result<CallMetadata>.error('metadata unused');
      }
      final next = invocation.namedArguments[#custom]! as Map<String, Object>;
      guestShareUpdates.add(next[guestScreenShareCustomKey] == true);
      custom
        ..clear()
        ..addAll(next);
      _states.publish(_callState());
      return Result.success(_UnusedCallMetadata());
    });
  }

  final call = _MockCall();
  final bool guest;
  final bool host;
  final bool member;
  final bool guestShareAllowed;
  final bool failGuestUpdate;
  final GroupCallSharePlatform platform;
  GroupCallAndroidShareHooks? androidShare;
  final List<CallPermission> grants;
  final shareRequests = <bool>[];
  final guestShareUpdates = <bool>[];
  final custom = <String, Object>{};
  late final _states = _Hold(_callState());
  bool _sharing = false;
  bool _failNext = false;

  void failNextShare() => _failNext = true;

  void disallowGuests() {
    custom[guestScreenShareCustomKey] = false;
    _states.publish(_callState());
  }

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GroupCallLiveControls(
          call: call,
          signedInMember: member || (host && !guest),
          sharePlatform: platform,
          androidShare: androidShare,
          onLeave: () async {},
          onRemove: (userId) async {},
          onEnd: () async {},
        ),
      ),
    ),
  );

  Future<void> close() => _states.close();

  CallState _callState() {
    if (guestShareAllowed && !custom.containsKey(guestScreenShareCustomKey)) {
      custom[guestScreenShareCustomKey] = true;
    }
    return CallState(
      currentUserId: 'member-1',
      callCid: StreamCallCid(cid: 'default:monthly'),
      preferences: DefaultCallPreferences(),
    ).copyWith(
      ownCapabilities: grants,
      custom: Map<String, Object>.from(custom),
      createdByUser: CallUser(
        id: host ? 'member-1' : 'someone-else',
        name: 'Fellow Member',
        roles: const [],
        image: '',
      ),
      callParticipants: [
        CallParticipantState(
          userId: 'member-1',
          roles: const [],
          name: 'Fellow Member',
          // ignore: deprecated_member_use
          custom: const {},
          sessionId: 'session-1',
          trackIdPrefix: 'local',
          isLocal: true,
          publishedTracks: {if (_sharing) SfuTrackType.screenShare: TrackState.local()},
        ),
      ],
    );
  }
}

class _Hold implements StateEmitter<CallState> {
  _Hold(this.value);

  final _updates = StreamController<CallState>.broadcast(sync: true);

  @override
  CallState value;

  void publish(CallState next) {
    value = next;
    if (!_updates.isClosed) _updates.add(next);
  }

  @override
  Stream<CallState> get valueStream => _updates.stream;

  @override
  bool get hasValue => true;

  @override
  CallState? get valueOrNull => value;

  @override
  StreamSubscription<CallState> listen(
    void Function(CallState value)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => valueStream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Future<E> waitFor<E extends CallState>({required Duration timeLimit}) =>
      firstWhere((it) => it is E, timeLimit: timeLimit).then((it) => it as E);

  @override
  Future<CallState> firstWhere(
    bool Function(CallState element) test, {
    CallState Function()? orElse,
    required Duration timeLimit,
  }) => valueStream.firstWhere(test, orElse: orElse).timeout(timeLimit);

  @override
  Stream<CallState> asStream() => valueStream;

  Future<void> close() => _updates.close();
}
