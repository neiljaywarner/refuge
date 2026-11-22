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

/// Stream's control button uses comfortable density and lands at 44dp.
/// Large-text checks require a 48dp target, so the key sits on this box.
Widget _callControl({
  required Key key,
  required String label,
  required Widget icon,
  required VoidCallback onPressed,
  Color? iconColor,
  Color? backgroundColor,
}) => Semantics(
  button: true,
  label: label,
  child: ConstrainedBox(
    key: key,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: CallControlOption(
      icon: icon,
      iconColor: iconColor,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
    ),
  ),
);

/// Mute, camera, leave, and the host actions for a preview group call.
///
/// Everyone can turn the microphone or camera on, or leave. Leave only steps
/// this person out. Remove and end-for-everyone are built only when [host]
/// is true: a signed-in member who created the room, or a Stream host or admin.
/// Guests do not get [host].
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
    this.canShare = false,
    this.sharing = false,
    this.onShare,
    this.showGuestShare = false,
    this.guestShareAllowed = false,
    this.onGuestShare,
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

  /// False hides the share button unless this person is already sharing.
  /// A guest stays false until the organizer allows it and Stream grants
  /// `screenshare`. Stopping stays available after that allow is removed.
  final bool canShare;

  /// True while this person's screen-share track is on.
  final bool sharing;
  final VoidCallback? onShare;

  /// Host-only switch. Guests do not get it.
  final bool showGuestShare;
  final bool guestShareAllowed;
  final ValueChanged<bool>? onGuestShare;

  @override
  Widget build(BuildContext context) {
    final bar = StreamCallControls(
      options: [
        _callControl(
          key: const Key('group_call_microphone_button'),
          label: 'Microphone',
          icon: Icon(microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
          onPressed: onMicrophone,
        ),
        _callControl(
          key: const Key('group_call_camera_button'),
          label: 'Camera',
          icon: Icon(cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded),
          onPressed: onCamera,
        ),
        if (canShare || sharing)
          _callControl(
            key: const Key('group_call_share_button'),
            label: sharing ? 'Stop sharing' : 'Share screen',
            icon: Icon(sharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded),
            onPressed: onShare ?? () {},
          ),
        if (host)
          _callControl(
            key: const Key('group_call_remove_button'),
            label: 'Remove someone',
            icon: const Icon(Icons.person_remove_alt_1_rounded),
            onPressed: () => unawaited(_removeSomeone(context)),
          ),
        if (host)
          _callControl(
            key: const Key('group_call_end_button'),
            label: 'End call for everyone',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: () => unawaited(_endForEveryone(context)),
          ),
        _callControl(
          key: const Key('group_call_leave_button'),
          label: 'Leave call',
          icon: const Icon(Icons.call_end_rounded),
          iconColor: Colors.white,
          backgroundColor: Colors.red,
          onPressed: () => unawaited(onLeave()),
        ),
      ],
    );
    if (!showGuestShare) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const .fromLTRB(16, 4, 16, 0),
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Let guests share'),
                Switch(
                  key: const Key('group_call_guest_share_switch'),
                  value: guestShareAllowed,
                  onChanged: onGuestShare,
                ),
              ],
            ),
          ),
        ),
        bar,
      ],
    );
  }

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
      body:
          'They leave this call. A member can join again with the call name. '
          'A guest needs a link that still works.',
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
