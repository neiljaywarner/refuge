import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  testWidgets(
    'after an external mute the icon follows the call and the next tap unmutes',
    (tester) async {
      final room = _Room();
      addTearDown(room.close);
      await room.pump(tester);

      for (var cycle = 0; cycle < 3; cycle++) {
        expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);

        await tester.tap(find.byKey(const Key('group_call_microphone_button')));
        await tester.pump();

        expect(room.requests[cycle].enabled, isTrue);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
        expect(find.byIcon(Icons.mic_off_rounded), findsNothing);

        room.muteFromOutside();
        await tester.pump();
        expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
      }

      expect(room.requests.map((request) => request.enabled), [
        true,
        true,
        true,
      ]);
    },
  );

  testWidgets('six taps request on off on off on off', (tester) async {
    final room = _Room();
    addTearDown(room.close);
    await room.pump(tester);

    for (var tap = 0; tap < 6; tap++) {
      await tester.tap(find.byKey(const Key('group_call_microphone_button')));
      await tester.pump();
    }

    expect(room.requests.map((request) => request.enabled), [
      true,
      false,
      true,
      false,
      true,
      false,
    ]);
    expect(room.requests.map((request) => request.stopTrackOnMute), [
      null,
      null,
      null,
      null,
      null,
      null,
    ]);
  });
}

class _MockCall extends Mock implements Call {}

class _MicRequest {
  const _MicRequest({required this.enabled, required this.stopTrackOnMute});

  final bool enabled;
  final bool? stopTrackOnMute;
}

class _Room {
  _Room() {
    when(() => call.state).thenReturn(_states);
    when(
      () => call.setMicrophoneEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
        stopTrackOnMute: any(named: 'stopTrackOnMute'),
      ),
    ).thenAnswer((invocation) async {
      final enabled = invocation.namedArguments[#enabled]! as bool;
      final stopTrackOnMute =
          invocation.namedArguments[#stopTrackOnMute] as bool?;
      requests.add(
        _MicRequest(enabled: enabled, stopTrackOnMute: stopTrackOnMute),
      );
      _audio = enabled;
      _states.publish(_callState());
      return const Result.success(none);
    });
  }

  final call = _MockCall();
  final requests = <_MicRequest>[];
  late final _states = _Hold(_callState());
  bool _audio = false;
  final bool _webPlaybackBlocked = false;

  void muteFromOutside() {
    _audio = false;
    _states.publish(_callState());
  }

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GroupCallLiveControls(
          call: call,
          signedInMember: false,
          onLeave: () async {},
          onRemove: (userId) async {},
          onEnd: () async {},
        ),
      ),
    ),
  );

  Future<void> close() => _states.close();

  CallState _callState() =>
      CallState(
        currentUserId: 'member-1',
        callCid: StreamCallCid(cid: 'default:monthly'),
        preferences: DefaultCallPreferences(),
      ).copyWith(
        isWebAudioPlaybackBlocked: _webPlaybackBlocked,
        ownCapabilities: const [CallPermission.sendAudio],
        callParticipants: [
          CallParticipantState(
            userId: 'member-1',
            roles: const [],
            name: 'Fellow Member',
            // The public constructor still requires this deprecated map.
            // ignore: deprecated_member_use
            custom: const {},
            sessionId: 'session-1',
            trackIdPrefix: 'local',
            isLocal: true,
            publishedTracks: {
              SfuTrackType.audio: TrackState.local(muted: !_audio),
            },
          ),
        ],
      );
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
  }) => valueStream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

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
