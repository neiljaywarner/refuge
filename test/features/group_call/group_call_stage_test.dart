import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_stage.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  testWidgets('a quiet room stays a grid with no presenter label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GroupCallStage(presenter: null, grid: Text('grid')),
      ),
    );

    expect(find.text('grid'), findsOneWidget);
    expect(find.byKey(const Key('group_call_screen_share_tile')), findsNothing);
    expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);
  });

  testWidgets('a remote share is the main tile and hides an email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GroupCallStage(
          presenter: GroupCallPresenter(
            userId: 'member-1',
            name: 'member@belongonthespectrum.com',
            local: false,
          ),
          grid: Text('grid'),
          shareTile: Text('share-bytes'),
        ),
      ),
    );

    expect(
      find.byKey(const Key('group_call_screen_share_tile')),
      findsOneWidget,
    );
    expect(find.text('share-bytes'), findsOneWidget);
    expect(find.text('Fellow Member is sharing'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('grid'), findsOneWidget);
  });

  testWidgets('the local sharer is labeled You are sharing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GroupCallStage(
          presenter: GroupCallPresenter(
            userId: 'member-1',
            name: 'Fellow Member',
            local: true,
          ),
          grid: Text('grid'),
        ),
      ),
    );

    expect(find.text('You are sharing'), findsOneWidget);
  });

  testWidgets('stopping a share returns the room to the grid', (tester) async {
    final room = _StageRoom();
    addTearDown(room.close);
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallParticipantsArea(
          call: room.call,
          guest: true,
          platform: GroupCallSharePlatform.ios,
          gridBuilder: (_) => const Text('grid'),
          tileBuilder: (_, _) => const Text('share-bytes'),
        ),
      ),
    );

    expect(find.text('grid'), findsOneWidget);
    expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);

    room.shareFrom('guest-2', 'Alex');
    await tester.pump();

    expect(find.text('Alex is sharing'), findsOneWidget);
    expect(find.text('share-bytes'), findsOneWidget);
    expect(find.text('grid'), findsOneWidget);

    room.stopShare();
    await tester.pump();

    expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);
    expect(find.text('share-bytes'), findsNothing);
    expect(find.text('grid'), findsOneWidget);
  });
}

class _MockCall extends Mock implements Call {}

class _StageRoom {
  _StageRoom() {
    when(() => call.state).thenReturn(_states);
  }

  final call = _MockCall();
  late final _states = _Hold(_callState());
  String? _sharerId;
  String? _sharerName;

  void shareFrom(String userId, String name) {
    _sharerId = userId;
    _sharerName = name;
    _states.publish(_callState());
  }

  void stopShare() {
    _sharerId = null;
    _sharerName = null;
    _states.publish(_callState());
  }

  Future<void> close() => _states.close();

  CallState _callState() =>
      CallState(
        currentUserId: 'member-1',
        callCid: StreamCallCid(cid: 'default:monthly'),
        preferences: DefaultCallPreferences(),
      ).copyWith(
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
          ),
          if (_sharerId != null)
            CallParticipantState(
              userId: _sharerId!,
              roles: const [],
              name: _sharerName!,
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
