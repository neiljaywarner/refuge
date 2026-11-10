import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../domain/group_call_room.dart';
import 'group_call_session_controls.dart';

/// True when the camera is sending and the person has not asked for it.
///
/// Stream's default call type turns the camera on. A preview join must undo
/// that until the camera button is tapped.
bool previewCameraShouldForceOff({
  required bool sendingVideo,
  required bool userAskedForCamera,
}) => sendingVideo && !userAskedForCamera;

/// True when the microphone is sending and the person has not asked for it.
bool previewMicrophoneShouldForceOff({
  required bool sendingAudio,
  required bool userAskedForMicrophone,
}) => sendingAudio && !userAskedForMicrophone;

/// Microphone and camera controls that follow the live track, not the first snapshot.
///
/// [microphoneEnabled] and [cameraEnabled] are read again on every build and
/// on every tap. A closure that captured the join-time value would keep
/// showing the off icon and would keep asking the SDK to turn the camera on.
class GroupCallReactiveControls extends StatelessWidget {
  const GroupCallReactiveControls({
    super.key,
    required this.tracks,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.onSetMicrophone,
    required this.onSetCamera,
    required this.host,
    required this.others,
    required this.onLeave,
    required this.onRemove,
    required this.onEnd,
  });

  /// Fires when the local microphone or camera changes under the controls.
  final Listenable tracks;
  final bool Function() microphoneEnabled;
  final bool Function() cameraEnabled;
  final void Function(bool enabled) onSetMicrophone;
  final void Function(bool enabled) onSetCamera;
  final bool host;
  final List<GroupCallOtherMember> others;
  final Future<void> Function() onLeave;
  final Future<void> Function(String userId) onRemove;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: tracks,
    builder: (context, _) => GroupCallSessionControls(
      microphoneEnabled: microphoneEnabled(),
      cameraEnabled: cameraEnabled(),
      host: host,
      others: others,
      onMicrophone: () => onSetMicrophone(!microphoneEnabled()),
      onCamera: () => onSetCamera(!cameraEnabled()),
      onLeave: onLeave,
      onRemove: onRemove,
      onEnd: onEnd,
    ),
  );
}

/// In-call controls bound to a live [Call].
///
/// The call screen's control builder does not rebuild when a track mutes, so
/// this widget listens to [Call.state] itself. If the call type turns the
/// camera or microphone on after a camera-off join, this turns that track off
/// until the person asks for it.
class GroupCallLiveControls extends StatefulWidget {
  const GroupCallLiveControls({
    super.key,
    required this.call,
    required this.signedInMember,
    required this.onLeave,
    required this.onRemove,
    required this.onEnd,
  });

  final Call call;
  final bool signedInMember;
  final Future<void> Function() onLeave;
  final Future<void> Function(String userId) onRemove;
  final Future<void> Function() onEnd;

  @override
  State<GroupCallLiveControls> createState() => _GroupCallLiveControlsState();
}

class _GroupCallLiveControlsState extends State<GroupCallLiveControls> {
  final _Tick _ticks = _Tick();
  StreamSubscription<CallState>? _subscription;
  bool _userWantsCamera = false;
  bool _userWantsMicrophone = false;
  bool _holding = false;
  int _cameraCorrections = 0;
  int _microphoneCorrections = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.call.state.valueStream.listen((_) {
      if (mounted) _ticks.tick();
      unawaited(_quietUnrequestedTracks());
    });
    unawaited(_quietUnrequestedTracks());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ticks.dispose();
    super.dispose();
  }

  Future<void> _quietUnrequestedTracks() async {
    if (_holding) return;
    final local = widget.call.state.value.localParticipant;
    if (local == null) return;
    final forceCamera = previewCameraShouldForceOff(
      sendingVideo: local.isVideoEnabled,
      userAskedForCamera: _userWantsCamera,
    );
    final forceMicrophone = previewMicrophoneShouldForceOff(
      sendingAudio: local.isAudioEnabled,
      userAskedForMicrophone: _userWantsMicrophone,
    );
    if (forceCamera && _cameraCorrections >= 5) return;
    if (forceMicrophone && _microphoneCorrections >= 5) return;
    if (!forceCamera && !forceMicrophone) {
      if (!local.isVideoEnabled) _cameraCorrections = 0;
      if (!local.isAudioEnabled) _microphoneCorrections = 0;
      return;
    }
    _holding = true;
    try {
      if (forceCamera) {
        _cameraCorrections += 1;
        await widget.call.setCameraEnabled(enabled: false);
      }
      if (forceMicrophone) {
        // TODO(#909): an external unmute is still forced back off.
        _microphoneCorrections += 1;
        await setGroupCallMicrophone(widget.call, enabled: false);
      }
    } finally {
      _holding = false;
    }
  }

  Future<void> _applyMicrophone(bool enabled) async {
    final askedBefore = _userWantsMicrophone;
    _userWantsMicrophone = enabled;
    final result = await setGroupCallMicrophone(widget.call, enabled: enabled);
    if (!mounted) return;
    if (result.isFailure) {
      _userWantsMicrophone = askedBefore;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The microphone stayed as it was. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.call.state.value;
    final local = state.localParticipant;
    return GroupCallReactiveControls(
      tracks: _ticks,
      microphoneEnabled: () =>
          widget.call.state.value.localParticipant?.isAudioEnabled ?? false,
      cameraEnabled: () =>
          widget.call.state.value.localParticipant?.isVideoEnabled ?? false,
      onSetMicrophone: (enabled) => unawaited(_applyMicrophone(enabled)),
      onSetCamera: (enabled) {
        _userWantsCamera = enabled;
        unawaited(widget.call.setCameraEnabled(enabled: enabled));
      },
      host: canModerateGroupCall(
        signedInMember: widget.signedInMember,
        createdByMe: state.createdByMe,
        roles: local?.roles ?? const [],
      ),
      others: [
        for (final person in state.otherParticipants)
          GroupCallOtherMember(userId: person.userId, name: person.name),
      ],
      onLeave: widget.onLeave,
      onRemove: widget.onRemove,
      onEnd: widget.onEnd,
    );
  }
}

class _Tick extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// Turns the preview microphone on or off without dropping the Android track.
///
/// Stream stops and releases the capture when stopTrackOnMute is left at its
/// default (`true`). The next unmute then opens the microphone again, which
/// matches audio the other person heard only after the first unmute. `false`
/// keeps the track and sends silence. The microphone-in-use indicator stays
/// on while muted.
///
/// https://getstream.io/video/docs/flutter/
/// https://getstream.io/video/docs/flutter/guides/camera-and-microphone/microphone-and-audio/
Future<Result<None>> setGroupCallMicrophone(
  Call call, {
  required bool enabled,
}) => call.setMicrophoneEnabled(
  enabled: enabled,
  stopTrackOnMute: enabled ? null : false,
);
