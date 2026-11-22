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

/// Equal-width link buttons for one week's episode.
///
/// Show notes and Transcript share a row. Apple Podcasts, Listen, the
/// discussion video, and Questions use that same row width so the card
/// does not end in a ragged chip line.
class BemaWeeklySourceLinks extends StatelessWidget {
  const BemaWeeklySourceLinks({
    super.key,
    required this.study,
    required this.idPrefix,
    this.includeApple = true,
    this.onOpenDiscussion,
    this.foregroundColor = const Color(0xFF14211C),
  });

  final BemaWeeklyStudy study;
  final String idPrefix;

  /// The feed card and the discussion post both offer Apple Podcasts.
  final bool includeApple;

  /// When set, the last control opens this week's discussion post.
  final VoidCallback? onOpenDiscussion;

  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final links = <_LabeledLink>[
      _LabeledLink('Show notes', '${idPrefix}_show_notes', () => openBemaLink(study.showNotesUrl)),
      _LabeledLink('Transcript', '${idPrefix}_transcript', () => openBemaLink(study.transcriptUrl)),
      if (includeApple && (study.applePodcastsUrl?.isNotEmpty ?? false))
        _LabeledLink(
          'Apple Podcasts',
          '${idPrefix}_apple_podcasts',
          () => openBemaLink(study.applePodcastsUrl!),
        ),
      _LabeledLink('Listen', '${idPrefix}_listen', () => openBemaLink(study.listenUrl)),
      _LabeledLink(
        'Discussion video',
        '${idPrefix}_discussion_video',
        () => openBemaLink(study.discussionVideoUrl),
      ),
      if (study.presentationUrl != null && study.presentationUrl!.isNotEmpty)
        _LabeledLink(
          'Presentation',
          '${idPrefix}_presentation',
          () => openBemaLink(study.presentationUrl!),
        ),
      if (onOpenDiscussion != null)
        _LabeledLink('Questions', '${idPrefix}_questions', onOpenDiscussion!),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // The home column passes a bounded width. A loose max still has to
        // produce equal rectangles, not shrink-wrapped pills.
        final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
        final stacked = maxWidth < 300;
        final rows = <Widget>[];
        if (stacked) {
          for (var i = 0; i < links.length; i++) {
            if (i > 0) rows.add(const SizedBox(height: 8));
            rows.add(_button(links[i], maxWidth));
          }
        } else {
          final half = (maxWidth - 8) / 2;
          for (var i = 0; i < links.length; i += 2) {
            if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
            if (i + 1 >= links.length) {
              rows.add(_button(links[i], maxWidth));
            } else {
              rows.add(
                Row(
                  children: [
                    _button(links[i], half),
                    const SizedBox(width: 8),
                    _button(links[i + 1], half),
                  ],
                ),
              );
            }
          }
        }
        return Column(crossAxisAlignment: .stretch, mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }

  Widget _button(_LabeledLink link, double width) => SizedBox(
    width: width,
    height: 48,
    child: OutlinedButton(
      key: Key(link.keyName),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        minimumSize: Size(width, 48),
        maximumSize: Size(width, 48),
        fixedSize: Size(width, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const .symmetric(horizontal: 8),
        shape: const RoundedRectangleBorder(borderRadius: .all(.circular(10))),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.15),
      ),
      onPressed: link.onPressed,
      child: Text(link.label, textAlign: .center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _LabeledLink {
  const _LabeledLink(this.label, this.keyName, this.onPressed);

  final String label;
  final String keyName;
  final VoidCallback onPressed;
}
