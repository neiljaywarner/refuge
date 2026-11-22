import 'package:flutter/material.dart';

import '../../group_call/data/stream_video_preview_config.dart';

/// One experimental feature this build can actually turn on.
class ExperimentalPreviewEntry {
  const ExperimentalPreviewEntry({
    required this.title,
    required this.where,
    required this.lookFor,
  });

  final String title;
  final String where;
  final String lookFor;
}

/// Features controlled by the same compile flag as the in-app preview switch.
///
/// Video calls and screen share appear only when this binary was built with
/// `STREAM_VIDEO_PREVIEW`. A production build gets an empty list.
List<ExperimentalPreviewEntry> experimentalPreviewEntries({
  required bool videoCalls,
}) {
  if (!videoCalls) return const [];
  return const [
    ExperimentalPreviewEntry(
      title: 'Video calls',
      where: 'On the home screen, after you sign in.',
      lookFor: 'Join call.',
    ),
    ExperimentalPreviewEntry(
      title: 'Screen share',
      where: 'Inside a video call.',
      lookFor: 'Share screen, then Back to grid.',
    ),
  ];
}

/// Explains which preview features just turned on, where to find them,
/// and how to send feedback or turn them off.
class ExperimentalPreviewDialog extends StatelessWidget {
  const ExperimentalPreviewDialog({super.key, required this.entries});

  final List<ExperimentalPreviewEntry> entries;

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => ExperimentalPreviewDialog(
      entries: experimentalPreviewEntries(
        videoCalls: streamVideoPreviewEnabled,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const inset = 16.0;
    return Dialog(
      insetPadding: const .all(inset),
      child: SizedBox(
        height: size.height - inset * 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const .fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experimental features are on',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      const Text(
                        'This build does not include an extra preview feature yet.',
                      )
                    else
                      for (final entry in entries) ...[
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('Where: ${entry.where}'),
                        Text('Look for: ${entry.lookFor}'),
                        const SizedBox(height: 12),
                      ],
                    const Text(
                      'To send feedback, open Vote & Feedback on the home screen.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To turn these off, use the same switch in your profile.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const .fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                key: const Key('experimental_preview_ok'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Got it',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
