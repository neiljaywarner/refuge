import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bema_weekly_study.dart';

/// Opens a verified episode link. A missing plugin or blocked browser stays put.
Future<void> openBemaLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {}
}

/// Show notes, transcript, and Apple Podcasts for one week's episode.
///
/// Used on the This Week card and on that week's discussion post.
class BemaWeeklySourceLinks extends StatelessWidget {
  const BemaWeeklySourceLinks({
    super.key,
    required this.study,
    required this.idPrefix,
    this.includeApple = true,
  });

  final BemaWeeklyStudy study;
  final String idPrefix;

  /// The feed card puts Apple Podcasts on the same row as Listen.
  final bool includeApple;

  @override
  Widget build(BuildContext context) {
    final notes = _sourceButton(
      keyName: '${idPrefix}_show_notes',
      label: 'Show notes',
      url: study.showNotesUrl,
    );
    final transcript = _sourceButton(
      keyName: '${idPrefix}_transcript',
      label: 'Transcript',
      url: study.transcriptUrl,
    );
    final apple = includeApple ? study.applePodcastsUrl : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340;
        final pair = stacked
            ? Column(
                crossAxisAlignment: .stretch,
                children: [notes, const SizedBox(height: 8), transcript],
              )
            : Row(
                children: [
                  Expanded(child: notes),
                  const SizedBox(width: 8),
                  Expanded(child: transcript),
                ],
              );
        return Column(
          crossAxisAlignment: .stretch,
          children: [
            pair,
            if (apple != null && apple.isNotEmpty) ...[
              const SizedBox(height: 8),
              _sourceButton(
                keyName: '${idPrefix}_apple_podcasts',
                label: 'Apple Podcasts',
                url: apple,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sourceButton({required String keyName, required String label, required String url}) =>
      OutlinedButton(
        key: Key(keyName),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(48, 40),
          padding: const .symmetric(horizontal: 8, vertical: 8),
        ),
        onPressed: () => openBemaLink(url),
        child: Text(label),
      );
}
