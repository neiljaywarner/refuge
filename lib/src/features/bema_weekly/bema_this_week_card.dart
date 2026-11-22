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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = isContrast
        ? Colors.yellow
        : (dark ? Theme.of(context).colorScheme.primary : const Color(0xFF1B4332));
    final ink = isContrast || dark ? Colors.white : const Color(0xFF14211C);
    return Container(
      key: const Key('bema_this_week_card'),
      margin: const .fromLTRB(12, 6, 12, 4),
      padding: const .fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isContrast
            ? Colors.black
            : (dark ? const Color(0xFF2A2A2A) : primaryColor.withValues(alpha: 0.08)),
        borderRadius: .circular(16),
        border: Border.all(color: accent.withValues(alpha: isContrast ? 1 : 0.45), width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final heading = Column(
            crossAxisAlignment: .start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THIS WEEK · BEMA ${study.episodeNumber}',
                style: TextStyle(
                  color: accent,
                  fontSize: wide ? 14 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                study.title,
                style: TextStyle(
                  color: ink,
                  fontSize: wide ? 28 : 22,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${study.subtitle} · ${study.gatheringLabel}',
                key: const Key('bema_weekly_gathering'),
                style: TextStyle(
                  color: ink,
                  fontSize: wide ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          );
          final join = FilledButton(
            key: const Key('bema_weekly_join_call'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: Size.fromHeight(wide ? 48 : 44),
              backgroundColor: isContrast ? Colors.yellow : primaryColor,
              foregroundColor: isContrast ? Colors.black : Colors.white,
            ),
            onPressed: onJoinCall,
            child: const Text(
              'Join the weekly call',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          );
          final links = BemaWeeklySourceLinks(
            study: study,
            idPrefix: 'bema_card',
            onOpenDiscussion: onOpenDiscussion,
            foregroundColor: ink,
          );
          if (!wide) {
            return Column(
              crossAxisAlignment: .stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                heading,
                const SizedBox(height: 8),
                links,
                const SizedBox(height: 8),
                join,
              ],
            );
          }
          return Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: .start,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: join),
                ],
              ),
              const SizedBox(height: 12),
              links,
            ],
          );
        },
      ),
    );
  }
}
