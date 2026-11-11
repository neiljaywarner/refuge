import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_909_log.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  test('[#909] logs stay on for a preview release and off for production', () {
    expect(groupCall909LogsEnabled(debugMode: false, preview: true), isTrue);
    expect(groupCall909LogsEnabled(debugMode: true, preview: false), isTrue);
    expect(groupCall909LogsEnabled(debugMode: false, preview: false), isFalse);
  });

  test('[#909] lines stay grepable and drop emails, tokens, and device names', () {
    final line = groupCall909Line(
      '${groupCall909Output(deviceId: 'bt-1', deviceLabel: "member@belongonthespectrum.com buds", external: true, speakerRequested: true)} '
      'eyJhbGciOiJIUzI1NiJ9.aaa.bbb',
    );

    expect(line, startsWith('[#909] '));
    expect(line.contains('@'), isFalse);
    expect(line.contains('eyJ'), isFalse);
    expect(line.contains('.aaa'), isFalse);
    expect(line.contains('.bbb'), isFalse);
    expect(line.contains('buds'), isFalse);
    expect(line, contains('audioOutput=external'));
    expect(line, contains('speakerRequested=true'));
    expect(line, contains('speakerphone=false'));
  });

  test('local audio logs a track-present flag and not a track id', () {
    final local = CallParticipantState(
      userId: 'member-1',
      roles: const [],
      name: 'Fellow Member',
      // ignore: deprecated_member_use
      custom: const {},
      sessionId: 'session-1',
      trackIdPrefix: 'track-secret',
      isLocal: true,
      publishedTracks: {SfuTrackType.audio: TrackState.local(muted: true)},
    );

    final line = groupCall909LocalAudio(local);

    expect(line, 'localAudio enabled=false muted=true trackPresent=true');
    expect(line.contains('track-secret'), isFalse);
    expect(
      groupCall909PublishChange(beforePresent: false, afterPresent: true, afterEnabled: true),
      'publish localAudio enabled=true',
    );
    expect(
      groupCall909PublishChange(beforePresent: true, afterPresent: false, afterEnabled: false),
      'unpublish localAudio',
    );
  });

  test('capabilities and remotes omit names', () {
    expect(
      groupCall909Capabilities(const [CallPermission.sendVideo, CallPermission.sendAudio]),
      'ownCapabilities=send-audio,send-video',
    );

    final remote = CallParticipantState(
      userId: 'other-1',
      roles: const [],
      name: 'member@belongonthespectrum.com',
      // ignore: deprecated_member_use
      custom: const {},
      sessionId: 'session-2',
      trackIdPrefix: 'remote-track',
      isSpeaking: true,
      audioLevel: 0.125,
      publishedTracks: {SfuTrackType.audio: TrackState.remote(muted: false)},
    );
    final line = groupCall909Remotes([remote]);

    expect(line, 'remotes audioTracks=1 speaking=1 audioLevel=0.13');
    expect(line.contains('@'), isFalse);
    expect(line.contains('remote-track'), isFalse);

    final muted = CallParticipantState(
      userId: 'other-2',
      roles: const [],
      name: 'Fellow Member',
      // ignore: deprecated_member_use
      custom: const {},
      sessionId: 'session-3',
      trackIdPrefix: 'muted-track',
      isSpeaking: false,
      audioLevel: 0.20,
      publishedTracks: {SfuTrackType.audio: TrackState.remote(muted: true)},
    );
    expect(groupCall909Remotes([muted]), 'remotes audioTracks=1 speaking=0 audioLevel=0');
    expect(
      groupCall909Remotes([remote, muted]),
      'remotes audioTracks=2 speaking=1 audioLevel=0.13',
    );
  });

  test('a repeated remote line waits two seconds', () {
    final throttle = GroupCall909Throttle();
    final start = DateTime.utc(2026, 11, 10);

    expect(throttle.allow('remotes audioTracks=1', start), isTrue);
    expect(throttle.allow('remotes audioTracks=1', start.add(const Duration(seconds: 1))), isFalse);
    expect(throttle.allow('remotes audioTracks=0', start.add(const Duration(seconds: 1))), isTrue);
    expect(
      throttle.allow('remotes audioTracks=0', start.add(const Duration(seconds: 3)), force: true),
      isTrue,
    );
  });
}
