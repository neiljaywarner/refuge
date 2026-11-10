import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class _MockCall extends Mock implements Call {}

class MicRequest {
  const MicRequest({required this.enabled, required this.stopTrackOnMute});

  final bool enabled;
  final bool? stopTrackOnMute;
}

/// Shared call double for the group-call Gherkin steps.
class GroupCallMicWorld {
  GroupCallMicWorld({
    this.signedInMember = false,
    this.createdByMe = false,
    List<CallPermission>? grants,
  }) : capabilities = grants ?? const [CallPermission.sendAudio] {
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
        MicRequest(enabled: enabled, stopTrackOnMute: stopTrackOnMute),
      );
      final canSend = capabilities.contains(CallPermission.sendAudio);
      if (_failNext || (enabled && !canSend)) {
        _failNext = false;
        return Result<None>.error('microphone unavailable');
      }
      audio = enabled;
      _states.publish(_callState());
      return const Result.success(none);
    });
    when(
      () => call.setCameraEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((invocation) async {
      camera = invocation.namedArguments[#enabled]! as bool;
      _states.publish(_callState());
      return const Result.success(none);
    });
  }

  final call = _MockCall();
  final requests = <MicRequest>[];
  final bool signedInMember;
  final bool createdByMe;
  final List<CallPermission> capabilities;
  late final _states = _Hold(_callState());
  bool audio = false;
  bool camera = false;
  bool webPlaybackBlocked = false;
  bool _failNext = false;
  int resumes = 0;

  bool get localAudioTrackPresent =>
      _states.value.localParticipant?.audioTrack != null;

  void failNext() => _failNext = true;

  void blockWebPlayback() {
    webPlaybackBlocked = true;
    _states.publish(_callState());
  }

  void beginWithMicrophoneOn() {
    audio = true;
    _states.publish(_callState());
  }

  void muteFromOutside() {
    audio = false;
    _states.publish(_callState());
  }

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GroupCallLiveControls(
          call: call,
          signedInMember: signedInMember,
          onLeave: () async {},
          onRemove: (userId) async {},
          onEnd: () async {},
          onResumeWebAudio: () async => resumes++,
        ),
      ),
    ),
  );

  Future<void> tapMic(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('group_call_microphone_button')));
    await tester.pump();
  }

  Future<void> tapCamera(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('group_call_camera_button')));
    await tester.pump();
  }

  Future<void> close() => _states.close();

  CallState _callState() =>
      CallState(
        currentUserId: 'member-1',
        callCid: StreamCallCid(cid: 'default:monthly'),
        preferences: DefaultCallPreferences(),
      ).copyWith(
        isWebAudioPlaybackBlocked: webPlaybackBlocked,
        ownCapabilities: capabilities,
        createdByUser: CallUser(
          id: createdByMe ? 'member-1' : 'someone-else',
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
            publishedTracks: {
              SfuTrackType.audio: TrackState.local(muted: !audio),
              SfuTrackType.video: TrackState.local(muted: !camera),
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

GroupCallMicWorld? micWorld;
