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
    return Container(
      key: const Key('bema_this_week_card'),
      margin: const .fromLTRB(12, 6, 12, 4),
      padding: const .fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isContrast ? Colors.black : primaryColor.withValues(alpha: 0.08),
        borderRadius: .circular(16),
        border: Border.all(color: accent.withValues(alpha: isContrast ? 1 : 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'THIS WEEK · BEMA ${study.episodeNumber}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            study.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: onCard,
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${study.subtitle} · ${study.gatheringLabel}',
            key: const Key('bema_weekly_gathering'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          BemaWeeklySourceLinks(study: study, idPrefix: 'bema_card', includeApple: false),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (study.applePodcastsUrl != null)
                _LinkChip(
                  key: const Key('bema_card_apple_podcasts'),
                  label: 'Apple Podcasts',
                  onPressed: () => openBemaLink(study.applePodcastsUrl!),
                ),
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
              _LinkChip(label: 'Questions', onPressed: onOpenDiscussion),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('bema_weekly_join_call'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isContrast ? Colors.yellow : primaryColor,
                foregroundColor: isContrast ? Colors.black : Colors.white,
              ),
              onPressed: onJoinCall,
              child: const Text('Join the weekly call'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ActionChip(visualDensity: VisualDensity.compact, label: Text(label), onPressed: onPressed);
}
