import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/firebase/organizer_remote_config_service.dart';
import '../../about/presentation/about_refuge_dialog.dart';

/// Live **"Message from the Organizer"** & Community Header Banner powered by
/// [organizerRemoteConfigProvider] (`Firebase Remote Config`, Issue #18 & #20).
///
/// Allows non-technical organizers at **Belong on the Spectrum** to update the
/// headline and message anytime from the Firebase Console without code changes.
class CommunityAnchorBanner extends HookConsumerWidget {
  final Color primaryColor;
  final bool isContrast;

  const CommunityAnchorBanner({
    super.key,
    required this.primaryColor,
    required this.isContrast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
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
          color: isContrast
              ? Colors.yellow
              : primaryColor.withValues(alpha: 0.25),
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
          const SizedBox(width: 8),
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isContrast ? Colors.yellow : primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• belongonthespectrum.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  remoteConfig.welcomeMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isContrast
                        ? Colors.white70
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => showAboutRefugeDialog(
              context,
              primaryColor: primaryColor,
              isContrast: isContrast,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isContrast ? Colors.yellow : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
