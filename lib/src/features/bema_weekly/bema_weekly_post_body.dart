import 'package:flutter/material.dart';

import 'bema_weekly_source_links.dart';
import 'bema_weekly_study.dart';

/// Readable Weekly Study post: a short intro, labeled links, then numbered questions.
///
/// The stored [weeklyDiscussionBody] stays in sync for search and the comment
/// sheet. This widget is what the feed paints, so a cloud row that still has
/// the older URL dump does not show that dump.
class BemaWeeklyPostBody extends StatelessWidget {
  const BemaWeeklyPostBody({
    super.key,
    required this.study,
    required this.postId,
    required this.isContrast,
  });

  final BemaWeeklyStudy study;
  final String postId;
  final bool isContrast;

  @override
  Widget build(BuildContext context) {
    final ink = isContrast ? Colors.white : const Color(0xFF14211C);
    final intro = TextStyle(color: ink, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600);
    return Semantics(
      container: true,
      label: weeklyDiscussionBody(study),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'This week is BEMA ${study.episodeNumber}, ${study.title}.',
            style: intro.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('${study.subtitle}. We gather ${study.gatheringLabel}.', style: intro),
          const SizedBox(height: 4),
          Text(
            'It follows episode ${study.followsEpisodeNumber}, ${study.followsTitle}.',
            style: intro.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          BemaWeeklySourceLinks(study: study, idPrefix: 'bema_post_$postId', foregroundColor: ink),
          const SizedBox(height: 12),
          Text('Discussion questions', style: intro.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (var i = 0; i < study.questions.length; i++) ...[
            Text(
              '${i + 1}. ${study.questions[i]}',
              style: intro.copyWith(fontWeight: FontWeight.w500),
            ),
            if (i != study.questions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
