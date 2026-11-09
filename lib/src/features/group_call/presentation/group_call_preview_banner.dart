import 'package:flutter/material.dart';

import 'group_call_flow.dart';

/// Preview entry on the home screen. Hidden unless the build and preview flag allow it.
class GroupCallPreviewBanner extends StatelessWidget {
  const GroupCallPreviewBanner({
    super.key,
    required this.initialCallId,
    required this.displayName,
    this.shareOrigin,
  });

  final String initialCallId;
  final String displayName;
  final Uri? shareOrigin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('group_call_preview_banner'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Preview group call. You start muted, with your camera off.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const Key('group_call_join_button'),
              onPressed: () => openGroupCallLobby(
                context: context,
                displayName: displayName,
                initialCallId: initialCallId,
                shareOrigin: shareOrigin,
              ),
              child: const Text('Join call'),
            ),
          ],
        ),
      ),
    );
  }
}
