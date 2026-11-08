import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../data/stream_token_client.dart';
import '../domain/group_call_room.dart';
import '../domain/stream_call_credentials.dart';

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
      final client = StreamVideo(
        widget.credentials.apiKey,
        user: User.regular(userId: widget.credentials.userId, name: _calmName(widget.displayName)),
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

  Future<void> _endForEveryone(Call call) async {
    final confirmed = await _confirm(
      title: 'End the call for everyone?',
      body: 'People still in the room will be disconnected.',
      action: 'End call',
    );
    if (!confirmed || !mounted) return;
    final result = await call.end();
    if (_calmFailure(result) != null) {
      _snack('Only the host can end the call.');
      return;
    }
    await _leave();
  }

  Future<void> _removeSomeone(Call call) async {
    final others = call.state.value.otherParticipants;
    if (others.isEmpty) {
      _snack('No one else is in the call.');
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Remove someone'),
        children: [
          for (final person in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, person.userId),
              child: Text(_calmName(person.name)),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final confirmed = await _confirm(
      title: 'Remove this person?',
      body: 'They leave this call. They can join again with the same call name.',
      action: 'Remove',
    );
    if (!confirmed || !mounted) return;
    final result = await call.kickUser(selected);
    if (_calmFailure(result) != null) {
      _snack('Only the host can remove someone.');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return answer ?? false;
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
            ? Center(
                child: Padding(
                  padding: const .all(24),
                  child: _failure == null
                      ? const Column(
                          mainAxisSize: .min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Joining with your microphone and camera off.'),
                          ],
                        )
                      : Column(
                          mainAxisSize: .min,
                          children: [
                            Text(_failure!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            TextButton(onPressed: _leave, child: const Text('Back')),
                          ],
                        ),
                ),
              )
            : StreamCallContent(
                call: call,
                onLeaveCallTap: _leave,
                onBackPressed: _leave,
                callControlsWidgetBuilder: (context, call) {
                  final state = call.state.value;
                  final host = canModerateGroupCall(
                    createdByMe: state.createdByMe,
                    roles: state.localParticipant?.roles ?? const [],
                  );
                  return StreamCallControls(
                    options: [
                      Semantics(
                        button: true,
                        label: 'Microphone',
                        child: ToggleMicrophoneOption(
                          call: call,
                          localParticipant: state.localParticipant,
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Camera',
                        child: ToggleCameraOption(
                          call: call,
                          localParticipant: state.localParticipant,
                        ),
                      ),
                      if (host)
                        Semantics(
                          button: true,
                          label: 'Remove someone',
                          child: CallControlOption(
                            icon: const Icon(Icons.person_remove_alt_1_rounded),
                            onPressed: () => unawaited(_removeSomeone(call)),
                          ),
                        ),
                      if (host)
                        Semantics(
                          button: true,
                          label: 'End call for everyone',
                          child: CallControlOption(
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed: () => unawaited(_endForEveryone(call)),
                          ),
                        ),
                      Semantics(
                        button: true,
                        label: 'Leave call',
                        child: LeaveCallOption(call: call, onLeaveCallTap: _leave),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

String _calmName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return 'Fellow Member';
  return trimmed;
}

String? _calmFailure<T>(Result<T> result) {
  if (result.isSuccess) return null;
  final raw = result.getErrorOrNull()?.message ?? '';
  final lower = raw.toLowerCase();
  if (raw.trim().isEmpty ||
      raw.length > 160 ||
      lower.contains('secret') ||
      lower.contains('token') ||
      raw.contains('eyJ')) {
    return 'The call could not connect.';
  }
  return raw.trim();
}
