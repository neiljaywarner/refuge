import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/firebase/organizer_remote_config_service.dart';
import '../../about/presentation/about_refuge_dialog.dart';

/// Gentle top announcement banner configured dynamically by community
/// organizers via Firebase Remote Config (#20).
///
/// Autistic design principles:
/// - Muted, low-stimulation background color
/// - Clear scripture anchor
/// - One-tap access to About Belong and community guidelines
class CommunityAnchorBanner extends HookConsumerWidget {
  const CommunityAnchorBanner({super.key, required this.primaryColor, required this.isContrast});

  final Color primaryColor;
  final bool isContrast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
    final flavor = ref.watch(appFlavorProvider);
    if (!remoteConfig.bannerEnabled) {
      return const SizedBox.shrink();
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale > 1.15;

    return Container(
      key: const Key('organizer_message_banner'),
      margin: const .fromLTRB(12, 6, 12, 2),
      padding: const .symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isContrast ? Colors.black : primaryColor.withValues(alpha: 0.08),
        borderRadius: .circular(10),
        border: Border.all(
          color: isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showDomainInline = !largeText && constraints.maxWidth >= 460;
          final titleLines = largeText ? 2 : 1;
          final aboutButton = _BannerAboutButton(
            primaryColor: primaryColor,
            isContrast: isContrast,
          );
          final title = Text(
            remoteConfig.welcomeTitle,
            maxLines: titleLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isContrast ? Colors.yellow : primaryColor,
            ),
          );
          final message = Text(
            remoteConfig.welcomeMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              color: isContrast ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
            ),
          );
          // At large text the About button used to keep the welcome lines on
          // one truncated row. Stacking gives those two lines the width to wrap.
          if (largeText) {
            // The mark and About button stay off the text row so the welcome
            // title and message can each use two full-width lines.
            return Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    _BannerMark(primaryColor: primaryColor, isContrast: isContrast),
                    const Spacer(),
                    aboutButton,
                  ],
                ),
                const Gap(4),
                title,
                const Gap(2),
                message,
              ],
            );
          }
          return Row(
            children: [
              _BannerMark(primaryColor: primaryColor, isContrast: isContrast),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: title),
                        if (showDomainInline) ...[
                          const Gap(4),
                          // A second Flexible would take half this row. The
                          // domain keeps only the width it needs, up to a cap.
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.32),
                            child: Text(
                              '• ${flavor.shortDomainLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isContrast
                                    ? Colors.white70
                                    : Theme.of(context).textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(1),
                    message,
                  ],
                ),
              ),
              const Gap(6),
              // Flexible would split this row with the message and cut the
              // welcome text in half. The button keeps its own width, capped.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
                child: aboutButton,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BannerMark extends StatelessWidget {
  const _BannerMark({required this.primaryColor, required this.isContrast});

  final Color primaryColor;
  final bool isContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isContrast
            ? Colors.yellow.withValues(alpha: 0.2)
            : primaryColor.withValues(alpha: 0.15),
      ),
      child: const Text('♾️', style: TextStyle(fontSize: 14)),
    );
  }
}

class _BannerAboutButton extends StatelessWidget {
  const _BannerAboutButton({required this.primaryColor, required this.isContrast});

  final Color primaryColor;
  final bool isContrast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'banner_learn_more_button',
      label: 'Learn more about Belong community principles',
      button: true,
      child: TextButton(
        onPressed: () =>
            showAboutRefugeDialog(context, primaryColor: primaryColor, isContrast: isContrast),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text(
          'About',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isContrast ? Colors.yellow : primaryColor,
          ),
        ),
      ),
    );
  }
}
