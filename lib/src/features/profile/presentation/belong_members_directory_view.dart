import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../branding/presentation/brand_config_provider.dart';
import '../domain/member_profile.dart';
import 'member_profile_sheet.dart';
import 'other_member_profile_dialog.dart';

/// Predefined representative / dummy fellowship members in dev environment
/// demonstrating community profiles, special interests, and ICOC church affiliations.
class DevFellowshipMember {
  const DevFellowshipMember({
    required this.name,
    required this.role,
    required this.bio,
    required this.churchAffiliation,
    required this.isIcocMember,
    required this.comfortBadges,
    this.tagline,
  });

  final String name;
  final String role;
  final String bio;
  final String churchAffiliation;
  final bool isIcocMember;
  final List<String> comfortBadges;
  final String? tagline;

  String get effectiveTagline => tagline ?? role;

  /// Extracts a 1- or 2-letter uppercase monogram initial string for directory avatars.
  ///
  /// Fallback: Returns 'B' for a Belong fellowship member when name is unset.
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return switch (parts) {
      [] => 'B',
      [final single] => single[0].toUpperCase(),
      [final first, ..., final last] => '${first[0]}${last[0]}'.toUpperCase(),
    };
  }
}

/// Curated dev fellowship members for Belong on the Spectrum.
const List<DevFellowshipMember> kDevFellowshipMembers = [
  DevFellowshipMember(
    name: 'Marty (Organizer)',
    role: 'Community Organizer & Founder',
    tagline: 'Championing neurodiversity in faith communities',
    bio: 'Championing neurodiversity in faith communities. Let’s make church quiet, authentic, and welcoming for autistic Christians.',
    churchAffiliation: 'DFW Church (Partner)',
    isIcocMember: true,
    comfortBadges: ['Community Organizer', 'Literal communication appreciated'],
  ),
  DevFellowshipMember(
    name: 'Caleb Stone',
    role: 'Audio & Visual Ministry',
    tagline: 'Soundscapes, calm lighting, and tech seams',
    bio: 'Audio tech & lighting designer. Obsessed with low-sensory sanctuary environments, chiasms, and soundscapes.',
    churchAffiliation: 'DFW Church',
    isIcocMember: true,
    comfortBadges: ['Sensory Sensitive', 'Direct communication'],
  ),
  DevFellowshipMember(
    name: 'Sarah Chen',
    role: 'Bible Teacher & Scholar',
    tagline: 'Deep dive Greek word studies and chiasms',
    bio: 'Hebrew & Greek linguistic enthusiast. Exploring chiasms in Mark and quiet contemplative prayer.',
    churchAffiliation: 'Boston Church',
    isIcocMember: true,
    comfortBadges: ['Special Interest: Biblical Greek', 'No small talk please'],
  ),
  DevFellowshipMember(
    name: 'David Okafor',
    role: 'Fellowship Deacon',
    tagline: 'Patience, gentle hospitality, and prayer',
    bio: 'Serving autistic adults & young families. Passionate about removing sensory barriers from Sunday assemblies.',
    churchAffiliation: 'London Church',
    isIcocMember: true,
    comfortBadges: ['Calm Tech Supporter', 'Clear expectations preferred'],
  ),
];

/// A dedicated member directory view allowing disciples to browse fellow community members,
/// view church affiliations, comfort badges, and taglines.
class BelongMembersDirectoryView extends ConsumerStatefulWidget {
  const BelongMembersDirectoryView({
    super.key,
    this.onBackToSpaces,
  });

  final VoidCallback? onBackToSpaces;

  @override
  ConsumerState<BelongMembersDirectoryView> createState() =>
      _BelongMembersDirectoryViewState();
}

class _BelongMembersDirectoryViewState
    extends ConsumerState<BelongMembersDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = ref.watch(communityBrandConfigProvider);
    final currentProfile = ref.watch(memberProfileProvider);

    final filteredMembers = kDevFellowshipMembers.where((m) {
      final matchesQuery = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.churchAffiliation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.effectiveTagline.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.comfortBadges.any((b) => b.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesFilter = switch (_selectedFilter) {
        'ICOC Affiliated' => m.isIcocMember,
        'Organizers' => m.role.toLowerCase().contains('organizer'),
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Spaces',
          onPressed: widget.onBackToSpaces ??
              () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Directory',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Fellowship disciples & leaders',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                key: const Key('members_directory_search_field'),
                decoration: InputDecoration(
                  hintText: 'Search by name, church, or comfort badge...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  for (final f in ['All', 'ICOC Affiliated', 'Organizers']) ...[
                    ChoiceChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      selected: _selectedFilter == f,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Directory list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Current user's card (if signed in)
                  if (currentProfile.isSignedIn) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Your Community Card',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _SelfMemberCard(profile: currentProfile),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Fellowship Disciples (${filteredMembers.length})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  if (filteredMembers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No members match "$_searchQuery"',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final member in filteredMembers) ...[
                      _FellowshipMemberCard(
                        member: member,
                        onTap: () => OtherMemberProfileDialog.show(
                          context,
                          authorName: member.name,
                          member: member,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfMemberCard extends StatelessWidget {
  const _SelfMemberCard({required this.profile});

  final MemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      color: theme.colorScheme.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? Text(
                          profile.initials,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (profile.effectiveTagline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.effectiveTagline,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Profile & Tagline',
                  onPressed: () => MemberProfileDialog.show(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (profile.comfortBadges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final badge in profile.comfortBadges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FellowshipMemberCard extends StatelessWidget {
  const _FellowshipMemberCard({
    required this.member,
    required this.onTap,
  });

  final DevFellowshipMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      member.initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (member.isIcocMember) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ICOC',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.effectiveTagline,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${member.churchAffiliation} • ${member.role}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                member.bio,
                style: const TextStyle(fontSize: 11.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.comfortBadges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final badge in member.comfortBadges)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}