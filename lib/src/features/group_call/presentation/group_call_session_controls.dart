import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'group_call_member_copy.dart';

/// Someone else in the preview room. [name] may still be an email; the
/// remove dialog shows [calmGroupCallName] instead.
class const GroupCallOtherMember({required this.userId, required this.name}) {
  final String userId;
  final String name;
}

/// Mute, camera, leave, and the host actions for a preview group call.
///
/// Everyone can turn the microphone or camera on, or leave. Leave only steps
/// this member out. Remove and end-for-everyone are built only when [host]
/// is true: the person who created the room, or a Stream host or admin.
class GroupCallSessionControls extends StatelessWidget {
  const GroupCallSessionControls({
    super.key,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.host,
    required this.onMicrophone,
    required this.onCamera,
    required this.onLeave,
    required this.onRemove,
    required this.onEnd,
    this.others = const [],
  });

  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool host;
  final List<GroupCallOtherMember> others;
  final VoidCallback onMicrophone;
  final VoidCallback onCamera;
  final Future<void> Function() onLeave;
  final Future<void> Function(String userId) onRemove;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) => StreamCallControls(
    options: [
      Semantics(
        button: true,
        label: 'Microphone',
        child: CallControlOption(
          key: const Key('group_call_microphone_button'),
          icon: Icon(microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
          onPressed: onMicrophone,
        ),
      ),
      Semantics(
        button: true,
        label: 'Camera',
        child: CallControlOption(
          key: const Key('group_call_camera_button'),
          icon: Icon(cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded),
          onPressed: onCamera,
        ),
      ),
      if (host)
        Semantics(
          button: true,
          label: 'Remove someone',
          child: CallControlOption(
            key: const Key('group_call_remove_button'),
            icon: const Icon(Icons.person_remove_alt_1_rounded),
            onPressed: () => unawaited(_removeSomeone(context)),
          ),
        ),
      if (host)
        Semantics(
          button: true,
          label: 'End call for everyone',
          child: CallControlOption(
            key: const Key('group_call_end_button'),
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: () => unawaited(_endForEveryone(context)),
          ),
        ),
      Semantics(
        button: true,
        label: 'Leave call',
        child: CallControlOption(
          key: const Key('group_call_leave_button'),
          icon: const Icon(Icons.call_end_rounded),
          iconColor: Colors.white,
          backgroundColor: Colors.red,
          onPressed: () => unawaited(onLeave()),
        ),
      ),
    ],
  );

  Future<void> _endForEveryone(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'End the call for everyone?',
      body: 'People still in the room will be disconnected.',
      action: 'End call',
    );
    if (!confirmed || !context.mounted) return;
    await onEnd();
  }

  Future<void> _removeSomeone(BuildContext context) async {
    if (others.isEmpty) {
      _snack(context, 'No one else is in the call.');
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
              child: Text(calmGroupCallName(person.name)),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    final confirmed = await _confirm(
      context,
      title: 'Remove this person?',
      body: 'They leave this call. They can join again with the same call name.',
      action: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    await onRemove(selected);
  }

  Future<bool> _confirm(
    BuildContext context, {
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

  void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
