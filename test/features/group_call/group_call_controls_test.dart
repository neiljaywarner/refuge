import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_connection_status.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_member_copy.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_session_controls.dart';

void main() {
  test('call failures and names do not reveal a token, a secret, or an email', () {
    const calm = 'The call could not connect.';
    expect(calmGroupCallFailureText(''), calm);
    expect(calmGroupCallFailureText('x' * 161), calm);
    expect(calmGroupCallFailureText('unit-test-stream-secret'), calm);
    expect(calmGroupCallFailureText('expired token'), calm);
    expect(calmGroupCallFailureText('eyJhbGciOiJIUzI1NiJ9.aaa.bbb'), calm);
    expect(calmGroupCallFailureText('Camera permission is off.'), 'Camera permission is off.');
    expect(calmGroupCallName(''), 'Fellow Member');
    expect(calmGroupCallName('member@belongonthespectrum.com'), 'Fellow Member');
    expect(calmGroupCallName(' Fellow Member '), 'Fellow Member');
  });

  testWidgets('joining says the microphone and camera are off, and Back leaves', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GroupCallConnectionStatus(failure: null, onBack: () {})),
      ),
    );
    expect(find.text('Joining with your microphone and camera off.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    var left = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupCallConnectionStatus(
            failure: 'The call could not connect.',
            onBack: () => left++,
          ),
        ),
      ),
    );
    expect(find.text('The call could not connect.'), findsOneWidget);
    expect(find.textContaining('unit-test-stream-secret'), findsNothing);
    await tester.tap(find.text('Back'));
    expect(left, 1);
  });

  testWidgets('a member can mute, use the camera, and leave, and cannot host', (tester) async {
    var microphone = 0;
    var camera = 0;
    var left = 0;
    await _pumpControls(
      tester,
      host: false,
      onMicrophone: () => microphone++,
      onCamera: () => camera++,
      onLeave: () async => left++,
      onRemove: (userId) async => fail('a member removed $userId'),
      onEnd: () async => fail('a member ended the call'),
    );

    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
    expect(find.byKey(const Key('group_call_remove_button')), findsNothing);
    expect(find.byKey(const Key('group_call_end_button')), findsNothing);

    await tester.tap(find.byKey(const Key('group_call_microphone_button')));
    await tester.tap(find.byKey(const Key('group_call_camera_button')));
    await tester.tap(find.byKey(const Key('group_call_leave_button')));
    await tester.pump();

    expect(microphone, 1);
    expect(camera, 1);
    expect(left, 1);
  });

  testWidgets('microphone and camera icons follow the enabled tracks', (tester) async {
    await _pumpControls(tester, host: false, microphoneEnabled: true, cameraEnabled: true);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
    expect(find.byIcon(Icons.videocam_off_rounded), findsNothing);
  });

  testWidgets('ending the call for everyone asks first', (tester) async {
    var ended = 0;
    await _pumpControls(tester, host: true, onEnd: () async => ended++);

    await tester.tap(find.byKey(const Key('group_call_end_button')));
    await tester.pumpAndSettle();
    expect(find.text('End the call for everyone?'), findsOneWidget);
    expect(find.text('People still in the room will be disconnected.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(ended, 0);

    await tester.tap(find.byKey(const Key('group_call_end_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    expect(ended, 1);
  });

  testWidgets('the host confirms before removing someone, and an empty room stays put', (
    tester,
  ) async {
    String? removed;
    await _pumpControls(
      tester,
      host: true,
      others: const [
        GroupCallOtherMember(userId: 'member1', name: 'member@belongonthespectrum.com'),
      ],
      onRemove: (userId) async => removed = userId,
    );

    await tester.tap(find.byKey(const Key('group_call_remove_button')));
    await tester.pumpAndSettle();
    expect(find.text('Fellow Member'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    await tester.tap(find.text('Fellow Member'));
    await tester.pumpAndSettle();
    expect(
      find.text('They leave this call. They can join again with the same call name.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(removed, isNull);

    await tester.tap(find.byKey(const Key('group_call_remove_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fellow Member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(removed, 'member1');

    await _pumpControls(tester, host: true, onRemove: (userId) async => fail('removed $userId'));
    await tester.tap(find.byKey(const Key('group_call_remove_button')));
    await tester.pump();
    expect(find.text('No one else is in the call.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpControls(
  WidgetTester tester, {
  required bool host,
  bool microphoneEnabled = false,
  bool cameraEnabled = false,
  List<GroupCallOtherMember> others = const [],
  VoidCallback? onMicrophone,
  VoidCallback? onCamera,
  Future<void> Function()? onLeave,
  Future<void> Function(String userId)? onRemove,
  Future<void> Function()? onEnd,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: GroupCallSessionControls(
        microphoneEnabled: microphoneEnabled,
        cameraEnabled: cameraEnabled,
        host: host,
        others: others,
        onMicrophone: onMicrophone ?? () {},
        onCamera: onCamera ?? () {},
        onLeave: onLeave ?? () async {},
        onRemove: onRemove ?? (userId) async {},
        onEnd: onEnd ?? () async {},
      ),
    ),
  ),
);
