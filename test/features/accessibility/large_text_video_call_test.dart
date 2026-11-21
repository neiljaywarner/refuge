import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_screen_share.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_guest_join_page.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_lobby.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_stage.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' hide Finder;

import '../../helpers/text_scale.dart';

/// Large-text coverage for the call lobby, guest join form, in-call controls,
/// and participant area (#935).
///
/// A device walk uses `tool/run_large_text_device_checks.sh` on the host.
/// These tests never call system settings.
const List<double> _callTextScales = <double>[2.0, 3.0];

void main() {
  testWidgets('call lobby keeps its actions readable at text scales 2.0 and 3.0', (tester) async {
    for (final scale in _callTextScales) {
      final session = await pumpWithTextScale(
        tester,
        GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          pageLocation: Uri.parse('https://example.com/call'),
          tokenClientFactory: () => null,
          onReady: (
            context, {
            required room,
            required credentials,
            required displayName,
            required tokenClient,
          }) async {},
        ),
        scale: scale,
      );

      final title = find.text('Group call');
      expect(title, findsOneWidget);
      final intro = find.textContaining('microphone and camera off');
      expect(intro, findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(intro)).scale(10), closeTo(10 * scale, 0.01));
      expectOnPhone(tester, title);
      expectNoMidWordWrap(tester, title);
      expectTextFitsItsBox(tester, title);

      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_name_field')),
        session,
      );
      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_confirm_join_button')),
        session,
      );
      expect(find.text('Join call'), findsOneWidget);
      expectMinTapTarget(tester, find.byKey(const Key('group_call_confirm_join_button')));

      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_invite_button')),
        session,
      );
      expect(find.text('Create guest link'), findsOneWidget);
      expectMinTapTarget(tester, find.byKey(const Key('group_call_invite_button')));

      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_revoke_my_links_button')),
        session,
      );
      expectVisibleCopy(tester);
      session.check();
    }
  });

  testWidgets('guest join keeps the name form readable at text scales 2.0 and 3.0', (tester) async {
    for (final scale in _callTextScales) {
      final session = await pumpWithTextScale(
        tester,
        GroupCallGuestJoinPage(
          inviteToken: 'c' * 43,
          callId: 'monthly',
          tokenClientFactory: () => null,
          onReady: (
            context, {
            required room,
            required credentials,
            required displayName,
            required tokenClient,
          }) async {},
        ),
        scale: scale,
      );

      expect(find.byKey(const Key('group_call_guest_join_page')), findsOneWidget);
      final intro = find.textContaining('You are joining');
      expect(intro, findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(intro)).scale(10), closeTo(10 * scale, 0.01));
      final title = find.text('Join as a guest');
      expect(title, findsOneWidget);
      expectOnPhone(tester, title);
      expectNoMidWordWrap(tester, title);
      expectTextFitsItsBox(tester, title);

      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_guest_name_field')),
        session,
      );
      expect(find.text('Your name'), findsOneWidget);

      await expectScrolledFullyOnScreen(
        tester,
        find.byKey(const Key('group_call_guest_join_button')),
        session,
      );
      expect(find.text('Join call'), findsOneWidget);
      expectMinTapTarget(tester, find.byKey(const Key('group_call_guest_join_button')));
      expectVisibleCopy(tester);
      session.check();
    }
  });

  testWidgets('in-call controls stay hittable at text scales 2.0 and 3.0', (tester) async {
    for (final scale in _callTextScales) {
      await _expectControls(tester, scale: scale, host: false, canShare: false);
      await _expectControls(tester, scale: scale, host: true, canShare: true);
    }
  });

  testWidgets('participant area shows the first person at text scales 2.0 and 3.0', (tester) async {
    for (final scale in _callTextScales) {
      final room = _QuietRoom();
      addTearDown(room.close);
      final session = await pumpWithTextScale(
        tester,
        Scaffold(
          body: GroupCallParticipantsArea(
            call: room.call,
            guest: true,
            platform: GroupCallSharePlatform.ios,
            gridBuilder: (_) => const _ParticipantGrid(),
          ),
        ),
        scale: scale,
      );

      final first = find.byKey(const Key('group_call_participant_0'));
      expect(first, findsOneWidget);
      expectOnPhone(tester, first);
      expect(find.text('Guest 1'), findsOneWidget);
      expectNoMidWordWrap(tester, find.text('Guest 1'));
      expectTextFitsItsBox(tester, find.text('Guest 1'));
      session.check();

      final sharing = await pumpWithTextScale(
        tester,
        const Scaffold(
          body: GroupCallStage(
            presenter: GroupCallPresenter(userId: 'member-1', name: 'Fellow Member', local: false),
            grid: _ParticipantGrid(),
          ),
        ),
        scale: scale,
      );
      final label = find.byKey(const Key('group_call_presenter_label'));
      expect(label, findsOneWidget);
      expect(find.text('Fellow Member is sharing'), findsOneWidget);
      expectOnPhone(tester, label);
      expectNoMidWordWrap(tester, find.text('Fellow Member is sharing'));
      expectTextFitsItsBox(tester, find.text('Fellow Member is sharing'));
      expectOnPhone(tester, find.byKey(const Key('group_call_participant_0')));
      sharing.check();
    }
  });
}

Future<void> _expectControls(
  WidgetTester tester, {
  required double scale,
  required bool host,
  required bool canShare,
}) async {
  final ticks = ChangeNotifier();
  addTearDown(ticks.dispose);
  var left = 0;
  final session = await pumpWithTextScale(
    tester,
    Scaffold(
      body: GroupCallReactiveControls(
        tracks: ticks,
        microphoneEnabled: () => false,
        cameraEnabled: () => false,
        onSetMicrophone: (_) {},
        onSetCamera: (_) {},
        canShare: canShare,
        onShare: canShare ? () {} : null,
        showGuestShare: host,
        guestShareAllowed: false,
        onGuestShare: host ? (_) {} : null,
        host: host,
        others: const [],
        onLeave: () async => left++,
        onRemove: (_) async {},
        onEnd: () async {},
      ),
    ),
    scale: scale,
  );

  await _expectControl(
    tester,
    session,
    key: const Key('group_call_microphone_button'),
    label: 'Microphone',
  );
  await _expectControl(
    tester,
    session,
    key: const Key('group_call_camera_button'),
    label: 'Camera',
  );
  if (canShare) {
    await _expectControl(
      tester,
      session,
      key: const Key('group_call_share_button'),
      label: 'Share screen',
    );
  }
  await _expectControl(
    tester,
    session,
    key: const Key('group_call_leave_button'),
    label: 'Leave call',
    onTap: () => expect(left, 1),
  );

  if (host) {
    expect(find.text('Let guests share'), findsOneWidget);
    expectNoMidWordWrap(tester, find.text('Let guests share'));
    expectTextFitsItsBox(tester, find.text('Let guests share'));
    await expectScrolledFullyOnScreen(
      tester,
      find.byKey(const Key('group_call_guest_share_switch')),
      session,
    );
  }
  expectVisibleCopy(tester);
  session.check();
}

Future<void> _expectControl(
  WidgetTester tester,
  TextScaleSession session, {
  required Key key,
  required String label,
  VoidCallback? onTap,
}) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  expect(find.bySemanticsLabel(label), findsWidgets);
  await expectScrolledFullyOnScreen(tester, finder, session);
  expectMinTapTarget(tester, finder);
  await tester.tap(finder);
  await tester.pump();
  onTap?.call();
  session.check();
}

Future<void> expectScrolledFullyOnScreen(
  WidgetTester tester,
  Finder finder,
  TextScaleSession session,
) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 400, scrollable: find.byType(Scrollable).first);
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  session.check();
  expectOnPhone(tester, finder);
}

void expectOnPhone(WidgetTester tester, Finder finder) {
  expect(finder, findsWidgets);
  final rect = tester.getRect(finder.first);
  expect(rect.left, greaterThanOrEqualTo(-0.5), reason: 'left ${rect.left}');
  expect(rect.top, greaterThanOrEqualTo(-0.5), reason: 'top ${rect.top}');
  expect(
    rect.right,
    lessThanOrEqualTo(largeTextPhoneSurface.width + 0.5),
    reason: 'right ${rect.right}',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(largeTextPhoneSurface.height + 0.5),
    reason: 'bottom ${rect.bottom}',
  );
  expect(rect.width, greaterThan(0));
  expect(rect.height, greaterThan(0));
}

void expectVisibleCopy(WidgetTester tester) {
  final texts = find.byType(Text).evaluate().where((element) {
    final object = element.renderObject;
    return object is RenderParagraph && object.attached && object.hasSize && object.size.width > 0;
  });
  expect(texts, isNotEmpty);
  for (final element in texts) {
    final finder = find.byWidget(element.widget);
    expectNoMidWordWrap(tester, finder);
    expectTextFitsItsBox(tester, finder);
  }
}

bool _isWordChar(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A);
}

RenderParagraph _renderedParagraph(WidgetTester tester, Finder finder) {
  final element = tester.element(finder);
  if (element.renderObject is RenderParagraph) {
    return element.renderObject! as RenderParagraph;
  }
  RenderParagraph? found;
  void walk(Element child) {
    if (found != null) return;
    if (child.renderObject is RenderParagraph) {
      found = child.renderObject! as RenderParagraph;
      return;
    }
    child.visitChildren(walk);
  }

  element.visitChildren(walk);
  return found!;
}

TextPainter _painterForRenderedText(WidgetTester tester, Finder finder) {
  final paragraph = _renderedParagraph(tester, finder);
  final constraint = paragraph.constraints.maxWidth;
  final maxWidth = !paragraph.softWrap
      ? double.infinity
      : (constraint.isFinite ? constraint : paragraph.size.width);
  return TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    ellipsis: paragraph.overflow == TextOverflow.ellipsis ? '\u2026' : null,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textWidthBasis: paragraph.textWidthBasis,
    textHeightBehavior: paragraph.textHeightBehavior,
  )..layout(maxWidth: maxWidth);
}

void expectNoMidWordWrap(WidgetTester tester, Finder finder) {
  final painter = _painterForRenderedText(tester, finder);
  final plain = painter.text?.toPlainText() ?? '';
  final lineCount = painter.computeLineMetrics().length;
  var offset = 0;
  for (var i = 0; i < lineCount && offset < plain.length; i++) {
    final range = painter.getLineBoundary(TextPosition(offset: offset));
    if (range.end <= offset) break;
    final end = range.end;
    final wraps = i < lineCount - 1 && end < plain.length;
    if (wraps) {
      expect(
        _isWordChar(plain[end - 1]) && _isWordChar(plain[end]),
        isFalse,
        reason: 'line broke mid-word at $end in $plain',
      );
    }
    offset = end;
  }
  painter.dispose();
}

void expectTextFitsItsBox(WidgetTester tester, Finder finder) {
  final paragraph = _renderedParagraph(tester, finder);
  final painter = _painterForRenderedText(tester, finder);
  expect(
    painter.height,
    lessThanOrEqualTo(paragraph.size.height + 1),
    reason: 'clipped vertically: painted ${painter.height} box ${paragraph.size.height}',
  );
  if (!paragraph.softWrap) {
    expect(
      painter.width,
      lessThanOrEqualTo(paragraph.size.width + 1),
      reason: 'clipped horizontally: painted ${painter.width} box ${paragraph.size.width}',
    );
  }
  painter.dispose();
}

class _ParticipantGrid extends StatelessWidget {
  const _ParticipantGrid();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('group_call_participant_grid'),
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            key: Key('group_call_participant_$i'),
            padding: const .all(8),
            child: Text('Guest ${i + 1}'),
          ),
      ],
    );
  }
}

class _MockCall extends Mock implements Call {}

class _QuietRoom {
  _QuietRoom() {
    when(() => call.state).thenReturn(_states);
  }

  final call = _MockCall();
  late final _states = _Hold(_callState());

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
        ],
      );
}

class _Hold implements StateEmitter<CallState> {
  _Hold(this.value);

  final _updates = StreamController<CallState>.broadcast(sync: true);

  @override
  CallState value;

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
