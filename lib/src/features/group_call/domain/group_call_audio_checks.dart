import 'package:stream_video_flutter/stream_video_flutter.dart';

/// A muted join does not create a microphone track.
///
/// Stream returns success for a disabled microphone and skips publish. The
/// first enable is what creates the track and sends it. Video can already
/// be moving while that audio track does not exist yet.
///
/// https://getstream.io/video/docs/flutter/
/// https://getstream.io/video/docs/flutter/guides/camera-and-microphone/microphone-and-audio/
bool firstUnmutePublishesMicrophone({
  required bool microphoneStartsEnabled,
  required bool enabling,
}) => !microphoneStartsEnabled && enabling;

/// Hearing a guest requires `send-audio` on the `call_member` role.
///
/// The live call reports that grant as [CallPermission.sendAudio] in
/// `CallState.ownCapabilities`. A working camera does not prove it. The
/// dashboard for the `default` call type is the source of the grant.
///
/// https://getstream.io/video/docs/flutter/guides/permissions-and-moderation/
bool capabilitiesIncludeSendAudio(List<CallPermission> capabilities) =>
    capabilities.contains(CallPermission.sendAudio);

/// Connect options replace `speakerDefaultOn` even when the caller omits it.
///
/// The options default is false, so a partial connect request turns the
/// loudspeaker flag off after the call type has turned it on. A phone group
/// call asks for the speaker. Android may still be on the earpiece until
/// the output device itself is the speaker.
///
/// https://getstream.io/video/docs/flutter/
CallConnectOptions previewCallConnectOptions({
  required bool cameraStartsEnabled,
  required bool microphoneStartsEnabled,
  required bool speakerStartsOn,
}) => CallConnectOptions(
  camera: cameraStartsEnabled ? TrackOption.enabled() : TrackOption.disabled(),
  microphone: microphoneStartsEnabled
      ? TrackOption.enabled()
      : TrackOption.disabled(),
  speakerDefaultOn: speakerStartsOn,
);

/// A browser can block the remote audio element after its autoplay rule.
///
/// The picture can still move. Playback starts when a tap calls
/// `resumeWebAudioPlayback`. Android does not use this flag.
///
/// https://getstream.io/video/docs/flutter/guides/call-and-participant-state/
bool webListenerNeedsATap({required bool playbackBlocked}) => playbackBlocked;
