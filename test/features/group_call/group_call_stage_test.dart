import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_stage.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../helpers/text_scale.dart' show expectMinTapTarget;
import '../../support/test_font_loader.dart';

void main() {
  setUpAll(() async {
    registerFallbackValue(ViewportVisibility.unknown);
    registerFallbackValue(SfuTrackType.screenShare);
    registerFallbackValue(const RtcVideoDimension(width: 0, height: 0));
    await TestFontLoader.loadAppFonts();
  });

  testWidgets('a quiet room stays a grid with no presenter label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupCallStage(presenter: null, grid: Text('grid'))),
    );

    expect(find.text('grid'), findsOneWidget);
    expect(find.byKey(const Key('group_call_screen_share_tile')), findsNothing);
    expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);
  });

  testWidgets('a remote share is the main tile and hides an email', (tester) async {
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

    expect(find.byKey(const Key('group_call_screen_share_tile')), findsOneWidget);
    expect(find.text('share-bytes'), findsOneWidget);
    expect(find.text('Fellow Member is sharing'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('grid'), findsOneWidget);
  });

  testWidgets('the local sharer is labeled You are sharing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GroupCallStage(
          presenter: GroupCallPresenter(userId: 'member-1', name: 'Fellow Member', local: true),
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

  testWidgets('a remote share is promoted and the whole tile opens it', (tester) async {
    final room = _StageRoom();
    addTearDown(room.close);
    await tester.pumpWidget(_area(room));

    expect(find.byKey(const Key('group_call_share_spotlight')), findsNothing);

    room.shareFrom('guest-2', 'Alex');
    await tester.pump();

    expect(find.byKey(const Key('group_call_share_spotlight')), findsOneWidget);
    expect(find.text('Alex is sharing'), findsOneWidget);
    expect(find.text('share-bytes'), findsOneWidget);
    expect(find.byKey(const Key('group_call_back_to_grid')), findsOneWidget);

    await tester.tap(find.byKey(const Key('group_call_back_to_grid')));
    await tester.pump();

    expect(find.byKey(const Key('group_call_share_grid')), findsOneWidget);
    expect(find.byKey(const Key('group_call_share_spotlight')), findsNothing);
    expect(find.text('Alex is sharing'), findsOneWidget);

    final tile = find.byKey(const Key('group_call_screen_share_tile'));
    for (final place in const [Alignment.center, Alignment.topLeft, Alignment.bottomRight]) {
      expect(find.byKey(const Key('group_call_share_spotlight')), findsNothing);
      final rect = tester.getRect(tile);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      final point = switch (place) {
        Alignment.topLeft => rect.topLeft + const Offset(4, 4),
        Alignment.bottomRight => rect.bottomRight - const Offset(4, 4),
        _ => rect.center,
      };
      await tester.tapAt(point);
      await tester.pump();
      expect(find.byKey(const Key('group_call_share_spotlight')), findsOneWidget);

      await tester.tap(find.byKey(const Key('group_call_back_to_grid')));
      await tester.pump();
    }

    room.stopShare();
    await tester.pump();

    expect(find.byKey(const Key('group_call_screen_share_tile')), findsNothing);
    expect(find.byKey(const Key('group_call_presenter_label')), findsNothing);
    expect(find.byKey(const Key('group_call_share_spotlight')), findsNothing);
    expect(find.text('grid'), findsOneWidget);
  });

  testWidgets('a pending screen-share track shows the starting placeholder', (tester) async {
    final room = _StageRoom()..stubRenderer();
    addTearDown(room.close);
    await tester.pumpWidget(_area(room, tile: false));

    room.sharePending('Alex');
    await tester.pump();

    expect(find.byKey(const Key('group_call_share_spotlight')), findsOneWidget);
    expect(find.text(GroupCallScreenShareStarting.label), findsOneWidget);
    expect(find.text('Alex is sharing'), findsOneWidget);
    expect(find.text('share-bytes'), findsNothing);
    expect(find.byType(StreamVideoRenderer), findsOneWidget);

    final handle = tester.ensureSemantics();
    try {
      expect(find.bySemanticsLabel('Alex is sharing'), findsOneWidget);
      expect(find.bySemanticsLabel(GroupCallScreenShareStarting.label), findsNothing);
      expect(
        tester.getSemantics(find.byKey(const Key('group_call_screen_share_tile'))),
        matchesSemantics(
          label: 'Alex is sharing',
          isButton: true,
          hasTapAction: true,
          customActions: const [CustomSemanticsAction(label: 'open shared screen')],
        ),
      );
    } finally {
      handle.dispose();
    }

    room.stopShare();
    await tester.pump();

    expect(find.text(GroupCallScreenShareStarting.label), findsNothing);
    expect(find.text('grid'), findsOneWidget);
    expect(find.byKey(const Key('group_call_share_spotlight')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('the share tile stays on screen at large text', (tester) async {
    const surface = Size(360, 640);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final scale in const [1.0, 1.3, 2.0, 3.0]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: GroupCallStage(
              key: ValueKey(scale),
              presenter: const GroupCallPresenter(
                userId: 'member-1',
                name: 'Fellow Member',
                local: false,
              ),
              grid: const Text('grid'),
              shareTile: const ColoredBox(color: Color(0xFF333333)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'text scale $scale');

      expect(find.text('Fellow Member is sharing'), findsOneWidget);
      expect(find.byKey(const Key('group_call_share_spotlight')), findsOneWidget);
      expectMinTapTarget(
        tester,
        find.byKey(const Key('group_call_screen_share_tile')),
        surface: surface,
      );
      expectMinTapTarget(
        tester,
        find.byKey(const Key('group_call_back_to_grid')),
        surface: surface,
      );

      await tester.tap(find.byKey(const Key('group_call_back_to_grid')));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'grid at text scale $scale');
      expect(find.byKey(const Key('group_call_share_grid')), findsOneWidget);
      expectMinTapTarget(
        tester,
        find.byKey(const Key('group_call_screen_share_tile')),
        surface: surface,
      );
      expect(find.text('Fellow Member is sharing'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: GroupCallStage(
              key: ValueKey('pending-$scale'),
              trackPending: true,
              presenter: const GroupCallPresenter(
                userId: 'member-1',
                name: 'Fellow Member',
                local: false,
              ),
              grid: const Text('grid'),
              shareTile: const GroupCallScreenShareStarting(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('group_call_back_to_grid')));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'pending grid at text scale $scale');
      expect(find.byKey(const Key('group_call_share_grid')), findsOneWidget);
      expectMessageFits(tester, GroupCallScreenShareStarting.label);
      final message = tester.getRect(find.text(GroupCallScreenShareStarting.label));
      expect(message.top, greaterThanOrEqualTo(-0.5));
      expect(message.bottom, lessThanOrEqualTo(surface.height + 0.5));
      final tile = tester.getRect(find.byKey(const Key('group_call_screen_share_tile')));
      expect(tile.width, greaterThanOrEqualTo(48));
      expect(tile.height, greaterThanOrEqualTo(48));
    }
  });

  for (final surface in const [Size(360, 640), Size(412, 915), Size(1280, 800)]) {
    for (final scale in const [1.0, 2.0, 3.0]) {
      final name =
          'screen_share_${surface.width.toInt()}x${surface.height.toInt()}_x${scale.toStringAsFixed(1)}';
      testWidgets(name, (tester) async {
        tester.view.physicalSize = surface;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: const Scaffold(
              backgroundColor: Color(0xFF101014),
              body: GroupCallStage(
                presenter: GroupCallPresenter(
                  userId: 'member-1',
                  name: 'Fellow Member',
                  local: false,
                ),
                grid: ColoredBox(
                  color: Color(0xFF2A2A2E),
                  child: Center(
                    child: Text('Grid', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/$name.png'));
      });
    }
  }
}

/// The starting line is fully painted. A 48dp slot clips it at large text
/// without throwing, because [Text] clips instead of overflowing.
void expectMessageFits(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textWidthBasis: paragraph.textWidthBasis,
    textHeightBehavior: paragraph.textHeightBehavior,
  )..layout(maxWidth: paragraph.size.width);
  expect(
    painter.height,
    lessThanOrEqualTo(paragraph.size.height + 1),
    reason: 'clipped: painted ${painter.height} box ${paragraph.size.height} for "$text"',
  );
  painter.dispose();
}

Widget _area(_StageRoom room, {bool tile = true}) {
  return MaterialApp(
    home: GroupCallParticipantsArea(
      call: room.call,
      guest: true,
      platform: GroupCallSharePlatform.ios,
      gridBuilder: (_) => const Text('grid'),
      tileBuilder: tile ? (_, _) => const Text('share-bytes') : null,
    ),
  );
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
  var _received = true;

  void shareFrom(String userId, String name) {
    _sharerId = userId;
    _sharerName = name;
    _received = true;
    _states.publish(_callState());
  }

  void sharePending(String name) {
    _sharerId = 'guest-2';
    _sharerName = name;
    _received = false;
    _states.publish(_callState());
  }

  void stopShare() {
    _sharerId = null;
    _sharerName = null;
    _states.publish(_callState());
  }

  /// The live renderer asks the call to subscribe when it is on screen.
  void stubRenderer() {
    when(
      () => call.updateViewportVisibility(
        sessionId: any(named: 'sessionId'),
        userId: any(named: 'userId'),
        visibility: any(named: 'visibility'),
        trackType: any(named: 'trackType'),
      ),
    ).thenAnswer((_) async => const Result.success(none));
    when(
      () => call.updateSubscription(
        userId: any(named: 'userId'),
        sessionId: any(named: 'sessionId'),
        trackIdPrefix: any(named: 'trackIdPrefix'),
        trackType: any(named: 'trackType'),
        videoDimension: any(named: 'videoDimension'),
      ),
    ).thenAnswer((_) async => const Result.success(none));
    when(
      () => call.removeSubscription(
        userId: any(named: 'userId'),
        sessionId: any(named: 'sessionId'),
        trackIdPrefix: any(named: 'trackIdPrefix'),
        trackType: any(named: 'trackType'),
      ),
    ).thenAnswer((_) async => const Result.success(none));
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
              publishedTracks: {
                SfuTrackType.screenShare: TrackState.remote(
                  received: _received,
                  subscribed: _received,
                ),
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
