import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../domain/group_call_909_log.dart';
import '../domain/group_call_audio_checks.dart';
import '../domain/group_call_room.dart';
import '../domain/group_call_screen_share.dart';
import '../domain/group_call_screen_share_log.dart';
import 'group_call_screen_share_session.dart';
import 'group_call_session_controls.dart';
import 'group_call_stage.dart';

/// True when the camera is sending and the person has not asked for it.
///
/// Stream's default call type turns the camera on. A preview join must undo
/// that until the camera button is tapped.
bool previewCameraShouldForceOff({required bool sendingVideo, required bool userAskedForCamera}) =>
    sendingVideo && !userAskedForCamera;

/// True when the microphone is sending and the person has not asked for it.
bool previewMicrophoneShouldForceOff({
  required bool sendingAudio,
  required bool userAskedForMicrophone,
}) => sendingAudio && !userAskedForMicrophone;

/// Which unrequested tracks can still be turned off.
///
/// Each track has its own cap. A camera that has already been corrected
/// five times does not block a microphone that is still sending.
({bool fixCamera, bool fixMicrophone}) previewTrackFixes({
  required bool forceCamera,
  required bool forceMicrophone,
  required int cameraCorrections,
  required int microphoneCorrections,
}) => (
  fixCamera: forceCamera && cameraCorrections < 5,
  fixMicrophone: forceMicrophone && microphoneCorrections < 5,
);

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
    this.canShare = false,
    this.sharing = false,
    this.onShare,
    this.showGuestShare = false,
    this.guestShareAllowed = false,
    this.onGuestShare,
    required this.host,
    required this.others,
    required this.onLeave,
    required this.onRemove,
    required this.onEnd,
    this.webPlaybackBlocked,
    this.onResumeWebAudio,
  });

  /// Fires when the local microphone or camera changes under the controls.
  final Listenable tracks;
  final bool Function() microphoneEnabled;
  final bool Function() cameraEnabled;
  final void Function(bool enabled) onSetMicrophone;
  final void Function(bool enabled) onSetCamera;
  final bool canShare;
  final bool sharing;
  final VoidCallback? onShare;
  final bool showGuestShare;
  final bool guestShareAllowed;
  final ValueChanged<bool>? onGuestShare;
  final bool host;
  final List<GroupCallOtherMember> others;
  final Future<void> Function() onLeave;
  final Future<void> Function(String userId) onRemove;
  final Future<void> Function() onEnd;
  final bool Function()? webPlaybackBlocked;
  final Future<void> Function()? onResumeWebAudio;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: tracks,
    builder: (context, _) {
      final session = GroupCallSessionControls(
        microphoneEnabled: microphoneEnabled(),
        cameraEnabled: cameraEnabled(),
        host: host,
        others: others,
        onMicrophone: () => onSetMicrophone(!microphoneEnabled()),
        onCamera: () => onSetCamera(!cameraEnabled()),
        canShare: canShare,
        sharing: sharing,
        onShare: onShare,
        showGuestShare: showGuestShare,
        guestShareAllowed: guestShareAllowed,
        onGuestShare: onGuestShare,
        onLeave: onLeave,
        onRemove: onRemove,
        onEnd: onEnd,
      );
      if (webPlaybackBlocked?.call() != true) return session;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: const Key('group_call_hear_room'),
            onPressed: () => unawaited(onResumeWebAudio!.call()),
            child: const Text('Tap to hear the room'),
          ),
          session,
        ],
      );
    },
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
    this.onResumeWebAudio = resumeGroupCallWebAudio,
    this.webMicrophone = kIsWeb,
    this.sharePlatform,
    this.androidShare,
  });

  final Call call;
  final bool signedInMember;
  final Future<void> Function() onLeave;
  final Future<void> Function(String userId) onRemove;
  final Future<void> Function() onEnd;

  /// Runs from the "Tap to hear the room" button. Web only needs it.
  final Future<void> Function() onResumeWebAudio;

  /// Web mutes by stopping the capture. Android keeps the track.
  final bool webMicrophone;

  /// Overrides the device when a test needs web or Android.
  final GroupCallSharePlatform? sharePlatform;

  /// Android consent and foreground service. Null uses Stream's service.
  final GroupCallAndroidShareHooks? androidShare;

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
  bool? _webBlocked;
  bool _localTrackPresent = false;
  String? _localLine;
  String? _outputLine;
  String? _capabilityLine;
  final GroupCall909Throttle _remotes = GroupCall909Throttle();

  @override
  void initState() {
    super.initState();
    _logCallState(widget.call.state.value);
    _subscription = widget.call.state.valueStream.listen((next) {
      _logCallState(next);
      if (mounted) {
        _ticks.tick();
        setState(() {});
      }
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
    final fixes = previewTrackFixes(
      forceCamera: forceCamera,
      forceMicrophone: forceMicrophone,
      cameraCorrections: _cameraCorrections,
      microphoneCorrections: _microphoneCorrections,
    );
    if (!forceCamera && !forceMicrophone) {
      if (!local.isVideoEnabled) _cameraCorrections = 0;
      if (!local.isAudioEnabled) _microphoneCorrections = 0;
      return;
    }
    if (!fixes.fixCamera && !fixes.fixMicrophone) return;
    _holding = true;
    try {
      if (fixes.fixCamera) {
        _cameraCorrections += 1;
        await widget.call.setCameraEnabled(enabled: false);
      }
      if (fixes.fixMicrophone) {
        // TODO(#909): an external unmute is still forced back off.
        _microphoneCorrections += 1;
        await setGroupCallMicrophone(widget.call, enabled: false, web: widget.webMicrophone);
      }
    } finally {
      _holding = false;
    }
  }

  Future<void> _applyMicrophone(bool enabled) async {
    final askedBefore = _userWantsMicrophone;
    _userWantsMicrophone = enabled;
    final before = widget.call.state.value.localParticipant;
    logGroupCall909('mic request enabled=$enabled ${groupCall909LocalAudio(before)}');
    final result = await setGroupCallMicrophone(
      widget.call,
      enabled: enabled,
      web: widget.webMicrophone,
    );
    if (!mounted) return;
    final after = widget.call.state.value.localParticipant;
    logGroupCall909(
      'mic result enabled=$enabled accepted=${result.isSuccess} ${groupCall909LocalAudio(after)}',
    );
    final publish = groupCall909PublishChange(
      beforePresent: before?.audioTrack != null,
      afterPresent: after?.audioTrack != null,
      afterEnabled: after?.isAudioEnabled ?? false,
    );
    if (publish != null) logGroupCall909(publish);
    if (!result.isSuccess &&
        enabled &&
        !capabilitiesIncludeSendAudio(widget.call.state.value.ownCapabilities)) {
      logGroupCall909('mic result missing send-audio');
    }
    if (result.isFailure) {
      _userWantsMicrophone = askedBefore;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('The microphone stayed as it was. Try again.')));
    }
  }

  void _logCallState(CallState next) {
    final blocked = next.isWebAudioPlaybackBlocked;
    if (_webBlocked != blocked) {
      _webBlocked = blocked;
      logGroupCall909('webAudioPlaybackBlocked=$blocked');
    }

    final present = next.localParticipant?.audioTrack != null;
    final publish = groupCall909PublishChange(
      beforePresent: _localTrackPresent,
      afterPresent: present,
      afterEnabled: next.localParticipant?.isAudioEnabled ?? false,
    );
    _localTrackPresent = present;
    if (publish != null) logGroupCall909(publish);
    final localLine = groupCall909LocalAudio(next.localParticipant);
    if (localLine != _localLine) {
      _localLine = localLine;
      logGroupCall909(localLine);
    }

    final output = groupCall909Output(
      deviceId: next.audioOutputDevice?.id,
      deviceLabel: next.audioOutputDevice?.label,
      external: next.audioOutputDevice?.isExternal ?? false,
    );
    if (output != _outputLine) {
      _outputLine = output;
      logGroupCall909(output);
    }

    final capabilities = groupCall909Capabilities(next.ownCapabilities);
    if (capabilities != _capabilityLine) {
      _capabilityLine = capabilities;
      logGroupCall909(capabilities);
    }

    final remotes = groupCall909Remotes(next.otherParticipants);
    if (_remotes.allow(remotes, DateTime.now())) logGroupCall909(remotes);
  }

  GroupCallShareView _shareView(CallState state) {
    final local = state.localParticipant;
    final host = canModerateGroupCall(
      signedInMember: widget.signedInMember,
      createdByMe: state.createdByMe,
      roles: local?.roles ?? const [],
    );
    return groupCallShareViewFromCall(
      capabilities: state.ownCapabilities,
      guest: !widget.signedInMember,
      custom: state.custom,
      platform: widget.sharePlatform ?? currentGroupCallSharePlatform(),
      participants: state.callParticipants,
      host: host,
    );
  }

  /// Starts or stops this person's share.
  ///
  /// https://getstream.io/video/docs/flutter/guides/screensharing/
  /// `call.setScreenShareEnabled(enabled: true)` after
  /// `call.hasPermission(CallPermission.screenshare)`. The button is already
  /// hidden when that grant is missing.
  Future<void> _toggleShare() async {
    final view = _shareView(widget.call.state.value);
    final sharing = view.localSharing;
    final turningOn = !sharing;
    final platform = widget.sharePlatform ?? currentGroupCallSharePlatform();
    logGroupCallScreenShare(
      groupCallScreenShareRequest(
        enabled: turningOn,
        platform: platform,
        granted: view.canShare,
        guest: !widget.signedInMember,
      ),
    );
    final result = await setGroupCallScreenShare(
      widget.call,
      enabled: turningOn,
      platform: platform,
      android: platform == GroupCallSharePlatform.android
          ? widget.androidShare ?? streamAndroidShareHooks()
          : null,
      stillAllowed: turningOn ? () => _shareView(widget.call.state.value).canShare : null,
    );
    logGroupCallScreenShare(
      groupCallScreenShareResult(enabled: turningOn, accepted: result.isSuccess),
    );
    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Screen sharing stayed as it was. Try again.')));
    }
  }

  /// Writes [guestScreenShareCustomKey] on the call so every guest can see it.
  Future<void> _allowGuests(bool allowed) async {
    final custom = Map<String, Object>.from(widget.call.state.value.custom);
    custom[guestScreenShareCustomKey] = allowed;
    final result = await widget.call.update(custom: custom);
    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Guests still cannot share. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.call.state.value;
    final local = state.localParticipant;
    final share = _shareView(state);
    final host = canModerateGroupCall(
      signedInMember: widget.signedInMember,
      createdByMe: state.createdByMe,
      roles: local?.roles ?? const [],
    );
    final controls = GroupCallReactiveControls(
      tracks: _ticks,
      microphoneEnabled: () => widget.call.state.value.localParticipant?.isAudioEnabled ?? false,
      cameraEnabled: () => widget.call.state.value.localParticipant?.isVideoEnabled ?? false,
      onSetMicrophone: (enabled) => unawaited(_applyMicrophone(enabled)),
      onSetCamera: (enabled) {
        _userWantsCamera = enabled;
        unawaited(widget.call.setCameraEnabled(enabled: enabled));
      },
      canShare: share.canShare,
      sharing: share.localSharing,
      onShare: () => unawaited(_toggleShare()),
      showGuestShare: host,
      guestShareAllowed: organizerAllowsGuestScreenShare(state.custom),
      onGuestShare: (allowed) => unawaited(_allowGuests(allowed)),
      host: host,
      others: [
        for (final person in state.otherParticipants)
          GroupCallOtherMember(userId: person.userId, name: person.name),
      ],
      onLeave: widget.onLeave,
      onRemove: widget.onRemove,
      onEnd: widget.onEnd,
      webPlaybackBlocked: () =>
          webListenerNeedsATap(playbackBlocked: widget.call.state.value.isWebAudioPlaybackBlocked),
      onResumeWebAudio: widget.onResumeWebAudio,
    );
    return controls;
  }
}

class _Tick extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// Turns the preview microphone on or off.
///
/// Android keeps the capture while muted (`stopTrackOnMute: false`). The
/// default (`true`) was releasing the track, so the next unmute had to open
/// the microphone again. Web does the opposite: a muted tab was still
/// sending silence and leaving the browser microphone indicator on, so a
/// web mute stops the track. The following unmute passes `enabled: true`,
/// which is what publishes the track again.
///
/// https://getstream.io/video/docs/flutter/
/// https://getstream.io/video/docs/flutter/guides/camera-and-microphone/microphone-and-audio/
bool? groupCallStopTrackOnMute({required bool enabled, required bool web}) => enabled ? null : web;

Future<Result<None>> setGroupCallMicrophone(
  Call call, {
  required bool enabled,
  bool web = kIsWeb,
}) => call.setMicrophoneEnabled(
  enabled: enabled,
  stopTrackOnMute: groupCallStopTrackOnMute(enabled: enabled, web: web),
);

/// Unblocks a browser's remote audio element from the hear-room tap.
///
/// https://getstream.io/video/docs/flutter/guides/call-and-participant-state/
Future<void> resumeGroupCallWebAudio() => RtcMediaDeviceNotifier.instance.resumeWebAudioPlayback();
