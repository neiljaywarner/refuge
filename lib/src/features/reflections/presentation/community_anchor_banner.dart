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

    return Container(
      key: const Key('organizer_message_banner'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isContrast ? Colors.black : primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isContrast ? Colors.yellow : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isContrast
                  ? Colors.yellow.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.15),
            ),
            child: const Text('♾️', style: TextStyle(fontSize: 14)),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        remoteConfig.welcomeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isContrast ? Colors.yellow : primaryColor,
                        ),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '• ${flavor.shortDomainLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isContrast
                            ? Colors.white70
                            : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const Gap(1),
                Text(
                  remoteConfig.welcomeMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: isContrast ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const Gap(6),
          Semantics(
            identifier: 'banner_learn_more_button',
            label: 'Learn more about Belong community principles',
            button: true,
            child: TextButton(
              onPressed: () => showAboutRefugeDialog(
                context,
                primaryColor: primaryColor,
                isContrast: isContrast,
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isContrast ? Colors.yellow : primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
