import 'package:flutter/material.dart';

/// Shown until the preview room is connected, and when joining fails.
///
/// The joining line states that the microphone and camera are still off.
/// [failure] is already the calm sentence; this widget does not render a raw
/// token or secret.
class GroupCallConnectionStatus extends StatelessWidget {
  const GroupCallConnectionStatus({super.key, required this.failure, required this.onBack});

  final String? failure;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const .all(24),
      child: failure == null
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
                Text(failure!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: onBack, child: const Text('Back')),
              ],
            ),
    ),
  );
}
