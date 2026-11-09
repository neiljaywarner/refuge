import 'dart:async';

import 'package:flutter/material.dart';

import '../data/stream_guest_token_client.dart';
import '../data/stream_token_client.dart';
import '../domain/group_call_room.dart';
import '../domain/guest_display_name.dart';
import 'group_call_lobby.dart';

typedef StreamGuestTokenClientFactory = StreamGuestTokenClient? Function();

/// Builds the guest client for a link. Tests pass a fake.
typedef GuestJoinClientBuilder = StreamGuestTokenClient? Function({
  required String inviteToken,
  String? callId,
});

/// Name step for someone who is not signed in and opened an invite link.
class GroupCallGuestJoinPage extends StatefulWidget {
  const GroupCallGuestJoinPage({
    super.key,
    required this.inviteToken,
    required this.callId,
    required this.tokenClientFactory,
    required this.onReady,
  });

  final String inviteToken;
  final String? callId;
  final StreamGuestTokenClientFactory tokenClientFactory;
  final GroupCallStarter onReady;

  @override
  State<GroupCallGuestJoinPage> createState() => _GroupCallGuestJoinPageState();
}

class _GroupCallGuestJoinPageState extends State<GroupCallGuestJoinPage> {
  final TextEditingController _name = TextEditingController();
  StreamGuestTokenClient? _active;
  Future<void>? _joinTask;
  Future<void>? _unusedRelease;
  bool _busy = false;
  bool _handedOff = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    final client = _active;
    if (!_handedOff && client != null) {
      unawaited(_releaseAfter(_joinTask, client));
    }
    super.dispose();
  }

  /// Waits for an in-flight join, then gives the seat back.
  ///
  /// Closing first would drop the HTTP client before [release] can run.
  /// The seat would stay until the token expires.
  Future<void> _releaseAfter(
    Future<void>? task,
    StreamGuestTokenClient client,
  ) async {
    if (task != null) {
      try {
        await task;
      } catch (_) {}
    }
    if (_handedOff) return;
    await _releaseUnused(client);
  }

  Future<void> _releaseUnused(StreamGuestTokenClient client) {
    final existing = _unusedRelease;
    if (existing != null) return existing;
    final pending = _releaseOnce(client);
    _unusedRelease = pending;
    return pending;
  }

  Future<void> _releaseOnce(StreamGuestTokenClient client) async {
    try {
      await client.release();
    } catch (_) {}
    client.close();
  }

  Future<void> _join() async {
    final clean = sanitizeGuestDisplayName(_name.text);
    if (clean == null) {
      setState(() {
        _message = 'Use a short name. Leave out email addresses and web links.';
      });
      return;
    }
    final client = widget.tokenClientFactory();
    if (client == null) {
      setState(() {
        _message =
            'This preview build has no token address yet. '
            'An operator sets STREAM_TOKEN_ENDPOINT when building the preview.';
      });
      return;
    }
    _active = client;
    _handedOff = false;
    _unusedRelease = null;
    final task = _finishJoin(client, clean);
    _joinTask = task;
    await task;
  }

  Future<void> _finishJoin(StreamGuestTokenClient client, String clean) async {
    try {
      setState(() {
        _busy = true;
        _message = null;
      });
      final credentials = await client.join(displayName: clean);
      if (!credentials.isGuest || !mounted) return;
      final room = GroupCallRoom.tryParse(credentials.callId);
      if (room == null) {
        setState(
          () => _message = 'The call could not start. Try again in a moment.',
        );
        return;
      }
      _handedOff = true;
      await widget.onReady(
        context,
        room: room,
        credentials: credentials,
        displayName: credentials.displayName,
        tokenClient: client,
      );
    } on StreamTokenException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message = 'The call could not start. Try again in a moment.',
      );
    } finally {
      if (!_handedOff) await _releaseUnused(client);
      if (identical(_active, client)) _active = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = widget.callId;
    return Scaffold(
      key: const Key('group_call_guest_join_page'),
      appBar: AppBar(title: const Text('Join as a guest')),
      body: SafeArea(
        child: ListView(
          padding: const .all(24),
          children: [
            Text(
              room == null
                  ? 'You are joining this call.'
                  : 'You are joining $room.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Type your name. You do not need an account. '
              'You start with your microphone and camera off. '
              'You can turn them on, or leave. '
              'You cannot end the call for everyone or remove other people.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'This link works for about 24 hours, or until the host revokes it. '
              'At most 10 guests can be in the call at once.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('group_call_guest_name_field'),
              controller: _name,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Your name',
                helperText: 'A short name. Not an email address or a web link.',
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('group_call_guest_join_button'),
              onPressed: _busy ? null : _join,
              child: Text(_busy ? 'Joining…' : 'Join call'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
