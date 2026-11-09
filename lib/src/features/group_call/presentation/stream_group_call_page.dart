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
    @visibleForTesting this.openConnection,
  });

  final StreamCallCredentials credentials;
  final String displayName;
  final GroupCallTokenSource tokenClient;

  /// When set, tests receive the connect plan and the page does not open Stream.
  @visibleForTesting
  final StreamCallOpener? openConnection;

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
    // Guests and members both use the server user id and server user token.
    // User.guest is the no-backend path: Stream mints a different token and
    // may replace the id, so a guest seat would no longer match the function.
    final plan = streamCallConnectPlan(
      credentials: widget.credentials,
      displayName: widget.displayName,
    );
    final opener = widget.openConnection;
    if (opener != null) {
      try {
        await opener(plan);
      } catch (_) {
        _showFailure('The call could not connect.');
      }
      return;
    }
    try {
      if (StreamVideo.isInitialized()) {
        await StreamVideo.reset(disconnect: true);
      }
      // [plan.userToken] is a Stream user token from mintStreamCallToken.
      // The API secret never arrives here. Stream calls [tokenLoader] when it
      // wants another user token. A member sends the Firebase ID token again.
      // A guest sends the invite token again and keeps the same seat.
      //
      // The function creates the call as the inviting member before a guest
      // token is issued, so this getOrCreate does not make the guest the owner.
      final client = StreamVideo(
        plan.apiKey,
        user: plan.user,
        userToken: plan.userToken,
        tokenLoader: (_) async {
          final fresh = await widget.tokenClient.mint(callId: plan.callId);
          return fresh.token;
        },
        options: StreamVideoOptions(
          muteAudioWhenInBackground: true,
          muteVideoWhenInBackground: true,
        ),
      );
      final call = client.makeCall(
        callType: StreamCallType.defaultType(),
        id: plan.callId,
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
      await widget.tokenClient.release();
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            ? GroupCallConnectionStatus(
                failure: _failure,
                onBack: () => unawaited(_leave()),
              )
            : StreamCallContent(
                call: call,
                onLeaveCallTap: _leave,
                onBackPressed: _leave,
                callControlsWidgetBuilder: (context, call) {
                  final state = call.state.value;
                  final local = state.localParticipant;
                  // Host controls require a signed-in member who created the
                  // room or has a Stream host or admin role. A guest never
                  // sees them, even if Stream says they created the room.
                  return GroupCallSessionControls(
                    microphoneEnabled: local?.isAudioEnabled ?? false,
                    cameraEnabled: local?.isVideoEnabled ?? false,
                    host: canModerateGroupCall(
                      signedInMember: !widget.credentials.isGuest,
                      createdByMe: state.createdByMe,
                      roles: local?.roles ?? const [],
                    ),
                    others: [
                      for (final person in state.otherParticipants)
                        GroupCallOtherMember(
                          userId: person.userId,
                          name: person.name,
                        ),
                    ],
                    onMicrophone: () {
                      call.setMicrophoneEnabled(
                        enabled: !(local?.isAudioEnabled ?? false),
                      );
                    },
                    onCamera: () {
                      call.setCameraEnabled(
                        enabled: !(local?.isVideoEnabled ?? false),
                      );
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

String? _calmFailure<T>(Result<T> result) => result.isSuccess
    ? null
    : calmGroupCallFailureText(result.getErrorOrNull()?.message ?? '');

/// Opens a preview call with a server-issued api key, user id, and user token.
typedef StreamCallOpener = Future<void> Function(StreamCallConnectPlan plan);

/// What the preview call passes to Stream.
///
/// [user] is always [User.regular]. Its type is authenticated, including for
/// a guest. [userToken] is the token the function minted for [user.id].
class const StreamCallConnectPlan({
  required this.apiKey,
  required this.user,
  required this.userToken,
  required this.callId,
}) {
  final String apiKey;
  final User user;
  final String userToken;
  final String callId;
}

/// Builds the Stream user for a guest or a member.
///
/// Both use [User.regular] so the server user id and [StreamCallCredentials.token]
/// are the ones Stream keeps. [User.guest] would ask Stream for an anonymous
/// token and could replace the id.
StreamCallConnectPlan streamCallConnectPlan({
  required StreamCallCredentials credentials,
  required String displayName,
}) => StreamCallConnectPlan(
  apiKey: credentials.apiKey,
  user: User.regular(
    userId: credentials.userId,
    name: calmGroupCallName(
      credentials.isGuest && credentials.displayName.isNotEmpty
          ? credentials.displayName
          : displayName,
    ),
  ),
  userToken: credentials.token,
  callId: credentials.callId,
);
