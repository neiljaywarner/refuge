import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../data/stream_token_client.dart';
import '../domain/group_call_909_log.dart';
import '../domain/group_call_audio_checks.dart';
import '../domain/group_call_session_lifecycle.dart';
import '../domain/stream_call_credentials.dart';
import 'group_call_connection_status.dart';
import 'group_call_member_copy.dart';
import 'group_call_reactive_controls.dart';

/// Active preview call. Starts muted and camera-off.
class StreamGroupCallPage extends StatefulWidget {
  const StreamGroupCallPage({
    super.key,
    required this.credentials,
    required this.displayName,
    required this.tokenClient,
    @visibleForTesting this.openConnection,
    @visibleForTesting this.initialCall,
  });

  final StreamCallCredentials credentials;
  final String displayName;
  final GroupCallTokenSource tokenClient;

  /// When set, tests receive the connect plan and the page does not open Stream.
  @visibleForTesting
  final StreamCallOpener? openConnection;

  /// When set, tests supply an active call directly without network connection.
  @visibleForTesting
  final Call? initialCall;

  @override
  State<StreamGroupCallPage> createState() => _StreamGroupCallPageState();
}

class _StreamGroupCallPageState extends State<StreamGroupCallPage> {
  final GroupCallSessionLifecycle _life = GroupCallSessionLifecycle();
  Call? _call;
  String? _failure;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCall != null) {
      _call = widget.initialCall;
      return;
    }
    unawaited(_connect());
  }

  @override
  void dispose() {
    _alive = false;
    if (widget.initialCall == null) {
      unawaited(_shutdown());
    }
    super.dispose();
  }

  Future<void> _connect() {
    // Guests and members both use the server user id and server user token.
    // User.guest is the no-backend path: Stream mints a different token and
    // may replace the id, so a guest seat would no longer match the function.
    final plan = streamCallConnectPlan(
      credentials: widget.credentials,
      displayName: widget.displayName,
    );
    logGroupCall909(
      'join microphoneOff=${!plan.microphoneStartsEnabled} speakerRequested=${plan.speakerStartsOn}',
    );
    final opener = widget.openConnection;
    if (opener != null) {
      return _life.connect(
        join: () async {
          await opener(plan);
          return true;
        },
        leave: () async {},
        onReady: () {},
        onFailure: () async {
          if (!_life.shutDown) await _life.releaseOnce(_releaseResources);
          _showFailure('The call could not connect.');
        },
      );
    }
    Call? call;
    var failure = 'The call could not connect.';
    return _life.connect(
      join: () async {
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
        call = client.makeCall(callType: StreamCallType.defaultType(), id: plan.callId);
        // getOrCreate applies the call type's camera-on default in the
        // background, after join has asked for the camera to stay off. Join
        // creates the room itself. The disabled options are merged after that
        // default, and [GroupCallLiveControls] turns a late camera back off.
        final joined = await call!.join(
          connectOptions: previewCallConnectOptions(
            cameraStartsEnabled: plan.cameraStartsEnabled,
            microphoneStartsEnabled: plan.microphoneStartsEnabled,
            speakerStartsOn: plan.speakerStartsOn,
          ),
        );
        final joinedFailure = _calmFailure(joined);
        if (joinedFailure != null) {
          failure = joinedFailure;
          return false;
        }
        return true;
      },
      leave: () async {
        final leaving = call;
        call = null;
        try {
          await leaving?.leave();
        } catch (_) {}
      },
      onReady: () {
        _call = call;
        if (_alive && mounted) setState(() {});
      },
      onFailure: () async {
        if (!_life.shutDown) await _life.releaseOnce(_releaseResources);
        _showFailure(failure);
      },
    );
  }

  void _showFailure(String message) {
    if (!_alive) return;
    setState(() => _failure = message);
  }

  Future<void> _releaseResources() async {
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

  Future<void> _shutdown() => _life.shutdown(
    leave: () async {
      final call = _call;
      _call = null;
      try {
        await call?.leave();
      } catch (_) {}
    },
    release: _releaseResources,
  );

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
      child: call == null
          ? Scaffold(
              appBar: AppBar(title: Text('Call ${widget.credentials.callId}')),
              body: GroupCallConnectionStatus(
                failure: _failure,
                onBack: () => unawaited(_leave()),
              ),
            )
          : StreamCallContent(
              call: call,
              onLeaveCallTap: _leave,
              onBackPressed: _leave,
              callAppBarWidgetBuilder: (context, call) => CallAppBar(
                call: call,
                onBackPressed: _leave,
                onLeaveCallTap: _leave,
                title: Text('Call ${widget.credentials.callId}'),
              ),
              callControlsWidgetBuilder: (context, call) => GroupCallLiveControls(
                call: call,
                signedInMember: !widget.credentials.isGuest,
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
              ),
            ),
    );
  }
}

String? _calmFailure<T>(Result<T> result) =>
    result.isSuccess ? null : calmGroupCallFailureText(result.getErrorOrNull()?.message ?? '');

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
  required this.cameraStartsEnabled,
  required this.microphoneStartsEnabled,
  required this.speakerStartsOn,
}) {
  final String apiKey;
  final User user;
  final String userToken;
  final String callId;

  /// False. The camera stays off until the person taps it.
  final bool cameraStartsEnabled;

  /// False. The microphone stays off until the person taps it.
  /// A disabled microphone does not publish a track. The first unmute does.
  final bool microphoneStartsEnabled;

  /// True. The loudspeaker stays requested. Omitting it merges speaker off.
  final bool speakerStartsOn;
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
  cameraStartsEnabled: false,
  microphoneStartsEnabled: false,
  speakerStartsOn: true,
);
