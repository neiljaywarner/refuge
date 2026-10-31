import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/firebase/organizer_remote_config_service.dart';
import '../../install/presentation/phone_install_guide_view.dart';
import '../../notifications/data/notification_permissions_service.dart';
import '../../notifications/presentation/calm_notification_preferences_sheet.dart';
import '../domain/fellowship_space.dart';

/// Circle.so-style structured Spaces directory & navigation drawer view for
/// **Belong on the Spectrum** (`Pinned`, `Welcome`, `Community`,
/// `Actually Autistic`, and `Links`).
class BelongSpacesDirectoryView extends HookConsumerWidget {
  const BelongSpacesDirectoryView({
    super.key,
    required this.selectedSpaceSlug,
    required this.onSelectSpaceItem,
  });

  final String selectedSpaceSlug;
  final ValueChanged<BelongSpaceItem> onSelectSpaceItem;

  Future<void> _handleTap(
    BuildContext context,
    BelongSpaceItem item,
    OrganizerRemoteConfig remoteConfig,
  ) async {
    if (item.phoneInstallFocus != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhoneInstallGuideView(focus: item.phoneInstallFocus!),
        ),
      );
      return;
    }
    if (item.slug == 'link_dfw_church' || item.externalUrl != null) {
      final urlString = item.slug == 'link_dfw_church'
          ? remoteConfig.dfwChurchUrl
          : item.externalUrl!;
      final uri = Uri.tryParse(urlString);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {
          // Safe fallback in headless widget test environments.
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${item.title} ($urlString)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    onSelectSpaceItem(item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(organizerRemoteConfigProvider);
    final notificationPrefs = ref.watch(calmNotificationPreferencesProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final isMutedInSettings = notificationPrefs.isSystemPermissionDenied;

    return ListView(
      key: const Key('belong_spaces_directory_list'),
      padding: const .symmetric(horizontal: 12, vertical: 8),
      children: [
        for (final section in kBelongSpaceSections)
          Padding(
            padding: const .only(bottom: 12),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    section.heading,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                      color: primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  margin: .zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: .circular(12),
                    side: BorderSide(color: primary.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < section.items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: primary.withValues(alpha: 0.1),
                          ),
                        _SpaceRowTile(
                          item: section.items[i],
                          isSelected:
                              selectedSpaceSlug == section.items[i].slug &&
                              section.heading != 'PINNED',
                          onTap: () => _handleTap(
                            context,
                            section.items[i],
                            remoteConfig,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (isMutedInSettings)
          Padding(
            padding: const .only(top: 4, bottom: 24),
            child: Card(
              key: const Key('notifications_muted_spaces_tile'),
              elevation: 0,
              color: primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: .circular(12),
                side: BorderSide(color: primary.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                dense: true,
                leading: const Text('🔕', style: TextStyle(fontSize: 18)),
                title: const Text(
                  'Notifications muted in system settings',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tap to adjust calm digest schedules or re-enable later',
                  style: TextStyle(fontSize: 11.5),
                ),
                trailing: const Icon(Icons.tune_rounded, size: 18),
                onTap: () => CalmNotificationPreferencesSheet.show(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpaceRowTile extends StatelessWidget {
  const _SpaceRowTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BelongSpaceItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: ExcludeSemantics(
        child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11.5)),
      trailing: item.externalUrl != null
          ? Icon(Icons.open_in_new_rounded, size: 16, color: primary)
          : item.phoneInstallFocus != null
          ? Icon(Icons.menu_book_outlined, size: 18, color: primary)
          : item.isComingSoon
          ? Container(
              padding: const .symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: .circular(999),
              ),
              child: Text(
                item.slug.startsWith('link_') ? 'Pending' : 'Coming Soon',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
