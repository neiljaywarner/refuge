import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_reactive_controls.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/stream_group_call_page.dart';

/// How a preview join starts, and how mute decides whether the capture stays.
///
/// Screen sharing is not in this tree. The in-call Start and Stop that exist
/// here are the microphone and the camera, and both start off.
void main() {
  test('a preview join starts with the camera and microphone off', () {
    final plan = streamCallConnectPlan(
      credentials: const StreamCallCredentials(
        apiKey: 'public-key',
        token: 'aaa.bbb.ccc',
        userId: 'member-1',
        callId: 'monthly',
        expiresAt: 30,
        displayName: 'David M.',
      ),
      displayName: 'David M.',
    );

    expect(plan.cameraStartsEnabled, isFalse);
    expect(plan.microphoneStartsEnabled, isFalse);
    expect(plan.speakerStartsOn, isTrue);
    expect(plan.user.name, 'David M.');
  });

  test('a guest plan uses the cleaned guest name', () {
    final plan = streamCallConnectPlan(
      credentials: const StreamCallCredentials(
        apiKey: 'public-key',
        token: 'aaa.bbb.ccc',
        userId: 'guest-1',
        callId: 'monthly',
        expiresAt: 30,
        role: 'guest',
        displayName: 'member@belongonthespectrum.com',
      ),
      displayName: 'Fellow Member',
    );

    expect(plan.user.name, 'Fellow Member');
  });

  test('mute keeps the Android track and stops the web track', () {
    expect(groupCallStopTrackOnMute(enabled: true, web: false), isNull);
    expect(groupCallStopTrackOnMute(enabled: true, web: true), isNull);
    expect(groupCallStopTrackOnMute(enabled: false, web: false), isFalse);
    expect(groupCallStopTrackOnMute(enabled: false, web: true), isTrue);
  });
}
