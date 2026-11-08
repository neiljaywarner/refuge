import 'package:flutter/material.dart';

import '../data/stream_token_client.dart';
import '../domain/group_call_room.dart';
import '../domain/stream_call_credentials.dart';

typedef GroupCallStarter = Future<void> Function(
  BuildContext context, {
  required GroupCallRoom room,
  required StreamCallCredentials credentials,
  required String displayName,
  required StreamTokenClient tokenClient,
});

typedef StreamTokenClientFactory = StreamTokenClient? Function();

/// Calm join step. The microphone and camera stay off until the member turns them on.
class GroupCallLobbyPage extends StatefulWidget {
  const GroupCallLobbyPage({
    super.key,
    required this.displayName,
    required this.initialCallId,
    required this.tokenClientFactory,
    required this.onReady,
  });

  final String displayName;
  final String initialCallId;
  final StreamTokenClientFactory tokenClientFactory;
  final GroupCallStarter onReady;

  @override
  State<GroupCallLobbyPage> createState() => _GroupCallLobbyPageState();
}

class _GroupCallLobbyPageState extends State<GroupCallLobbyPage> {
  late final TextEditingController _name = TextEditingController(text: widget.initialCallId);
  StreamTokenClient? _active;
  bool _busy = false;
  bool _handedOff = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    if (!_handedOff) _active?.close();
    super.dispose();
  }

  Future<void> _join() async {
    final room = GroupCallRoom.tryParse(_name.text);
    if (room == null) {
      setState(() {
        _message = 'Use a short name like monthly. Letters, numbers, and single dashes.';
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
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final credentials = await client.mint(callId: room.id);
      if (!mounted) return;
      _handedOff = true;
      await widget.onReady(
        context,
        room: room,
        credentials: credentials,
        displayName: widget.displayName,
        tokenClient: client,
      );
    } on StreamTokenException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'The call could not start. Try again in a moment.');
    } finally {
      if (!_handedOff) client.close();
      if (identical(_active, client)) _active = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Group call')),
      body: SafeArea(
        child: ListView(
          padding: const .all(24),
          children: [
            Text(
              'You join with your microphone and camera off. '
              'Turn them on when you are ready.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'This preview is for a small group, about an hour. '
              'There is no 40-minute cutoff. '
              'The first person in the room can end the call or remove someone. '
              'Leave only steps you out.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('group_call_name_field'),
              controller: _name,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Call name',
                helperText: 'Share the same name, or open the preview link with ?call=name',
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('group_call_confirm_join_button'),
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
