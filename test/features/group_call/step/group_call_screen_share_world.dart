import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_stage.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class _MockCall extends Mock implements Call {}

/// Shared call double for the screen-share Gherkin steps.
class GroupCallScreenShareWorld {
  GroupCallScreenShareWorld({
    this.guest = false,
    this.host = false,
    this.member = false,
    List<CallPermission>? grants,
  }) : capabilities = grants ?? const [CallPermission.screenshare] {
    when(() => call.state).thenReturn(_states);
    when(
      () => call.setScreenShareEnabled(
        enabled: any(named: 'enabled'),
        constraints: any(named: 'constraints'),
      ),
    ).thenAnswer((invocation) async {
      final enabled = invocation.namedArguments[#enabled]! as bool;
      shareRequests.add(enabled);
      _localSharing = enabled;
      _states.publish(_callState());
      return const Result.success(none);
    });
    when(() => call.update(custom: any(named: 'custom'))).thenAnswer((invocation) async {
      final next = invocation.namedArguments[#custom]! as Map<String, Object>;
      guestShareUpdates.add(next[guestScreenShareCustomKey] == true);
      custom
        ..clear()
        ..addAll(next);
      _states.publish(_callState());
      return Result<CallMetadata>.error('metadata unused');
    });
  }

  final call = _MockCall();
  final bool guest;
  final bool host;
  final bool member;
  final List<CallPermission> capabilities;
  final shareRequests = <bool>[];
  final guestShareUpdates = <bool>[];
  final custom = <String, Object>{};
  late final _states = _Hold(_callState());
  bool _localSharing = false;
  String? remoteId;
  String? remoteName;

  void allowGuests() {
    custom[guestScreenShareCustomKey] = true;
    _states.publish(_callState());
  }

  void remoteShares(String name) {
    remoteId = 'guest-2';
    remoteName = name;
    _states.publish(_callState());
  }

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: GroupCallParticipantsArea(
                call: call,
                guest: guest,
                platform: GroupCallSharePlatform.web,
                gridBuilder: (_) => const Text('grid'),
                tileBuilder: (_, _) => const Text('share-bytes'),
              ),
            ),
            GroupCallLiveControls(
              call: call,
              signedInMember: member || (host && !guest),
              sharePlatform: GroupCallSharePlatform.web,
              onLeave: () async {},
              onRemove: (userId) async {},
              onEnd: () async {},
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> tapShare(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('group_call_share_button')));
    await tester.pump();
  }

  Future<void> close() => _states.close();

  CallState _callState() =>
      CallState(
        currentUserId: 'member-1',
        callCid: StreamCallCid(cid: 'default:monthly'),
        preferences: DefaultCallPreferences(),
      ).copyWith(
        ownCapabilities: capabilities,
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
            publishedTracks: {if (_localSharing) SfuTrackType.screenShare: TrackState.local()},
          ),
          if (remoteId != null)
            CallParticipantState(
              userId: remoteId!,
              roles: const [],
              name: remoteName!,
              // ignore: deprecated_member_use
              custom: const {},
              sessionId: 'session-remote',
              trackIdPrefix: 'remote',
              publishedTracks: {SfuTrackType.screenShare: TrackState.remote()},
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

GroupCallScreenShareWorld? shareWorld;
