import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../data/stream_token_client.dart';
import '../domain/group_call_room.dart';
import '../domain/stream_call_credentials.dart';
import 'group_call_connection_status.dart';
import 'group_call_member_copy.dart';
import 'group_call_session_controls.dart';

/// Active preview call. Starts muted and camera-off.
class StreamGroupCallPage extends StatefulWidget {
  const StreamGroupCallPage({
    super.key,
    required this.credentials,
    required this.displayName,
    required this.tokenClient,
  });

  final StreamCallCredentials credentials;
  final String displayName;
  final StreamTokenClient tokenClient;

  @override
  State<StreamGroupCallPage> createState() => _StreamGroupCallPageState();
}

class _StreamGroupCallPageState extends State<StreamGroupCallPage> {
  Call? _call;
  String? _failure;
  bool _shutDown = false;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  @override
  void dispose() {
    _alive = false;
    unawaited(_shutdown());
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      if (StreamVideo.isInitialized()) {
        await StreamVideo.reset(disconnect: true);
      }
      // [credentials.token] is a Stream user token from mintStreamCallToken.
      // The API secret never arrives here. Stream calls [tokenLoader] when it
      // wants another user token; that request sends the Firebase ID token
      // again, and the function mints a new user token.
      final client = StreamVideo(
        widget.credentials.apiKey,
        user: User.regular(
          userId: widget.credentials.userId,
          name: calmGroupCallName(widget.displayName),
        ),
        userToken: widget.credentials.token,
        tokenLoader: (_) async {
          final fresh = await widget.tokenClient.mint(callId: widget.credentials.callId);
          return fresh.token;
        },
        options: StreamVideoOptions(
          muteAudioWhenInBackground: true,
          muteVideoWhenInBackground: true,
        ),
      );
      final call = client.makeCall(
        callType: StreamCallType.defaultType(),
        id: widget.credentials.callId,
      );
      final created = await call.getOrCreate(video: true);
      final createdFailure = _calmFailure(created);
      if (createdFailure != null) {
        try {
          await call.leave();
        } catch (_) {}
        await _shutdown();
        _showFailure(createdFailure);
        return;
      }
      // Both tracks stay off until the member taps microphone or camera.
      final joined = await call.join(
        connectOptions: CallConnectOptions(
          camera: TrackOption.disabled(),
          microphone: TrackOption.disabled(),
        ),
      );
      final joinedFailure = _calmFailure(joined);
      if (joinedFailure != null) {
        try {
          await call.leave();
        } catch (_) {}
        await _shutdown();
        _showFailure(joinedFailure);
        return;
      }
      if (!_alive) {
        await _shutdown();
        return;
      }
      setState(() => _call = call);
    } catch (_) {
      await _shutdown();
      _showFailure('The call could not connect.');
    }
  }

  void _showFailure(String message) {
    if (!_alive) return;
    setState(() => _failure = message);
  }

  Future<void> _shutdown() async {
    if (_shutDown) return;
    _shutDown = true;
    final call = _call;
    _call = null;
    try {
      await call?.leave();
    } catch (_) {}
    try {
      if (StreamVideo.isInitialized()) {
        await StreamVideo.reset(disconnect: true);
      }
    } catch (_) {}
    widget.tokenClient.close();
  }

  Future<void> _leave() async {
    await _shutdown();
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Call ${widget.credentials.callId}')),
        body: call == null
            ? GroupCallConnectionStatus(failure: _failure, onBack: () => unawaited(_leave()))
            : StreamCallContent(
                call: call,
                onLeaveCallTap: _leave,
                onBackPressed: _leave,
                callControlsWidgetBuilder: (context, call) {
                  final state = call.state.value;
                  final local = state.localParticipant;
                  // Host controls belong to the room creator or a Stream
                  // host/admin. Everyone else gets microphone, camera, and leave.
                  return GroupCallSessionControls(
                    microphoneEnabled: local?.isAudioEnabled ?? false,
                    cameraEnabled: local?.isVideoEnabled ?? false,
                    host: canModerateGroupCall(
                      createdByMe: state.createdByMe,
                      roles: local?.roles ?? const [],
                    ),
                    others: [
                      for (final person in state.otherParticipants)
                        GroupCallOtherMember(userId: person.userId, name: person.name),
                    ],
                    onMicrophone: () {
                      call.setMicrophoneEnabled(enabled: !(local?.isAudioEnabled ?? false));
                    },
                    onCamera: () {
                      call.setCameraEnabled(enabled: !(local?.isVideoEnabled ?? false));
                    },
                    onLeave: _leave,
                    onRemove: (userId) async {
                      final result = await call.kickUser(userId);
                      if (_calmFailure(result) != null) {
                        _snack('Only the host can remove someone.');
                      }
                    },
                    onEnd: () async {
                      final result = await call.end();
                      if (_calmFailure(result) != null) {
                        _snack('Only the host can end the call.');
                        return;
                      }
                      await _leave();
                    },
                  );
                },
              ),
      ),
    );
  }
}

String? _calmFailure<T>(Result<T> result) =>
    result.isSuccess ? null : calmGroupCallFailureText(result.getErrorOrNull()?.message ?? '');
