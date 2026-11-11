import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_audio_checks.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/stream_group_call_page.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

void main() {
  test('a muted join publishes the microphone only on the first enable', () {
    expect(
      firstUnmutePublishesMicrophone(
        microphoneStartsEnabled: false,
        enabling: true,
      ),
      isTrue,
    );
    expect(
      firstUnmutePublishesMicrophone(
        microphoneStartsEnabled: false,
        enabling: false,
      ),
      isFalse,
    );
    expect(
      firstUnmutePublishesMicrophone(
        microphoneStartsEnabled: true,
        enabling: true,
      ),
      isFalse,
    );

    final plan = streamCallConnectPlan(
      credentials: StreamCallCredentials(
        apiKey: 'public-key',
        token: 'aaa.bbb.ccc',
        userId: 'g${'a' * 32}',
        callId: 'monthly',
        expiresAt: 30,
        role: 'guest',
        displayName: 'Alex',
      ),
      displayName: 'Fellow Member',
    );
    final options = previewCallConnectOptions(
      cameraStartsEnabled: plan.cameraStartsEnabled,
      microphoneStartsEnabled: plan.microphoneStartsEnabled,
      speakerStartsOn: plan.speakerStartsOn,
    );

    expect(plan.microphoneStartsEnabled, isFalse);
    expect(options.microphone.isDisabled, isTrue);
    expect(
      firstUnmutePublishesMicrophone(
        microphoneStartsEnabled: plan.microphoneStartsEnabled,
        enabling: true,
      ),
      isTrue,
    );
  });

  test('the guest role is heard only when send-audio is granted', () {
    expect(CallPermission.sendAudio.alias, 'send-audio');
    expect(
      capabilitiesIncludeSendAudio(const [CallPermission.sendAudio]),
      isTrue,
    );
    expect(
      capabilitiesIncludeSendAudio(const [CallPermission.sendVideo]),
      isFalse,
    );
    expect(capabilitiesIncludeSendAudio(const []), isFalse);
  });

  test('the preview join asks for the loudspeaker', () {
    final options = previewCallConnectOptions(
      cameraStartsEnabled: false,
      microphoneStartsEnabled: false,
      speakerStartsOn: true,
    );

    expect(options.speakerDefaultOn, isTrue);
    expect(options.camera.isDisabled, isTrue);
    expect(options.microphone.isDisabled, isTrue);
    expect(
      previewCallConnectOptions(
        cameraStartsEnabled: false,
        microphoneStartsEnabled: false,
        speakerStartsOn: false,
      ).speakerDefaultOn,
      isFalse,
    );
  });

  test('web playback stays blocked until a tap', () {
    expect(webListenerNeedsATap(playbackBlocked: true), isTrue);
    expect(webListenerNeedsATap(playbackBlocked: false), isFalse);
  });
}
