import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/firebase/organizer_remote_config_service.dart';
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
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.builder(
      key: const Key('belong_spaces_directory_list'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: kBelongSpaceSections.length,
      itemBuilder: (context, sectionIndex) {
        final section = kBelongSpaceSections[sectionIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < section.items.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: primary.withValues(alpha: 0.1)),
                      _SpaceRowTile(
                        item: section.items[i],
                        isSelected:
                            selectedSpaceSlug == section.items[i].slug &&
                            section.heading != 'PINNED',
                        onTap: () => _handleTap(context, section.items[i], remoteConfig),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpaceRowTile extends StatelessWidget {
  const _SpaceRowTile({required this.item, required this.isSelected, required this.onTap});

  final BelongSpaceItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Text(item.emoji, style: const TextStyle(fontSize: 18)),
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
          : item.isComingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.slug.startsWith('link_') ? 'Pending' : 'Coming Soon',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: primary),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
