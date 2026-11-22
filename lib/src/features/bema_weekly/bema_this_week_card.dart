import 'package:flutter/material.dart';

import 'bema_weekly_source_links.dart';
import 'bema_weekly_study.dart';

/// Prominent weekly gathering card. Content comes from [BemaWeeklyStudy].
class BemaThisWeekCard extends StatelessWidget {
  const BemaThisWeekCard({
    super.key,
    required this.study,
    required this.primaryColor,
    required this.isContrast,
    required this.onJoinCall,
    required this.onOpenDiscussion,
  });

  final BemaWeeklyStudy study;
  final Color primaryColor;
  final bool isContrast;
  final VoidCallback onJoinCall;
  final VoidCallback onOpenDiscussion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isContrast ? Colors.yellow : primaryColor;
    final onCard = isContrast ? Colors.white : theme.textTheme.bodyMedium?.color;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final titleSize = textScale > 1.3 ? 18.0 : 22.0;

    return Container(
      key: const Key('bema_this_week_card'),
      margin: const .fromLTRB(12, 8, 12, 4),
      padding: const .fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isContrast ? Colors.black : primaryColor.withValues(alpha: 0.08),
        borderRadius: .circular(16),
        border: Border.all(color: accent.withValues(alpha: isContrast ? 1 : 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'THIS WEEK',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BEMA ${study.episodeNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            study.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onCard,
              fontSize: titleSize,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            study.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${study.publishedLabel} · ${study.durationLabel} · Follows ${study.followsEpisodeNumber}, ${study.followsTitle}',
            style: theme.textTheme.bodySmall?.copyWith(color: onCard, height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            study.gatheringLabel,
            key: const Key('bema_weekly_gathering'),
            style: theme.textTheme.titleSmall?.copyWith(color: onCard, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          BemaWeeklySourceLinks(study: study, idPrefix: 'bema_card'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LinkChip(label: 'Listen', onPressed: () => openBemaLink(study.listenUrl)),
              _LinkChip(
                label: 'Discussion video',
                onPressed: () => openBemaLink(study.discussionVideoUrl),
              ),
              if (study.presentationUrl != null)
                _LinkChip(
                  label: 'Presentation',
                  onPressed: () => openBemaLink(study.presentationUrl!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Show notes for this episode are on the episode page. Room ${study.callRoom}.',
            style: theme.textTheme.bodySmall?.copyWith(color: onCard, height: 1.3),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('bema_weekly_join_call'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: isContrast ? Colors.yellow : primaryColor,
                foregroundColor: isContrast ? Colors.black : Colors.white,
              ),
              onPressed: onJoinCall,
              child: const Text('Join the weekly call'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('bema_weekly_open_discussion'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: accent,
                side: BorderSide(color: accent),
              ),
              onPressed: onOpenDiscussion,
              child: const Text('Open this week’s questions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(label: Text(label), onPressed: onPressed);
}
