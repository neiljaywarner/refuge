import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../branding/presentation/brand_config_provider.dart';
import '../domain/member_profile.dart';
import 'member_profile_sheet.dart';

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

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
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
    name: 'Hannah M.',
    role: 'Creative Arts & Botany',
    tagline: 'Sensory-friendly contemplative prayer & botanical art',
    bio: 'Autistic artist exploring sensory-friendly contemplative prayer and botanical illustrations.',
    churchAffiliation: 'Austin Christian Church',
    isIcocMember: true,
    comfortBadges: ['Visual Artist', 'Sensory-sensitive'],
  ),
  DevFellowshipMember(
    name: 'Alex K.',
    role: 'Peer Chat Facilitator',
    tagline: 'Retro computing & unhurried theological reflection',
    bio: 'Actually Autistic Chat host and software tinkerer. Passionate about retro computing and unhurried theological reflection.',
    churchAffiliation: 'Boston Church of Christ',
    isIcocMember: true,
    comfortBadges: ['Chat Facilitator', 'Special Interest: Computing'],
  ),
  DevFellowshipMember(
    name: 'Jordan P.',
    role: 'Friend & Ally of Fellowship',
    tagline: 'Neurodivergent seeker finding calm, grace-filled Christian fellowship',
    bio: 'Neurodivergent seeker finding calm, grace-filled Christian fellowship and honest community.',
    churchAffiliation: 'I am not a member of an ICOC church',
    isIcocMember: false,
    comfortBadges: ['Ally & Visitor', 'Low-stimulus preferred'],
  ),
];

/// Members Section & Directory view for **Belong on the Spectrum** (#93)
/// allowing members to store profile info, review their ICOC fellowship status,
/// and browse fellow community members.
class BelongMembersDirectoryView extends HookConsumerWidget {
  const BelongMembersDirectoryView({
    super.key,
    this.onBackToSpaces,
  });

  final VoidCallback? onBackToSpaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Sub-header navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              if (onBackToSpaces != null)
                IconButton(
                  key: const Key('members_directory_back_button'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: onBackToSpaces,
                  tooltip: 'Back to Spaces Directory',
                ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members Section & Directory',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Store profile info & connect with verified fellowship members',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('members_edit_profile_button'),
                onPressed: () => MemberProfileDialog.show(context),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  profile.isSignedIn ? 'Edit Profile' : 'Sign In',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Body content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // User's own profile card
              Card(
                elevation: 0,
                color: primary.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primary.withValues(alpha: 0.25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            child: Text(
                              profile.initials,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                        profile.displayName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (profile.isSignedIn)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.email.isNotEmpty
                                      ? profile.email
                                      : 'Guest Member (Alpha Session)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.bio,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 8),

                      // Church Affiliation Badge
                      if (brand.enableFellowshipAffiliationField)
                        Container(
                          key: const Key('user_profile_affiliation_badge'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: profile.isIcocMember
                                ? primary.withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: profile.isIcocMember
                                  ? primary.withValues(alpha: 0.3)
                                  : Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                profile.isIcocMember
                                    ? Icons.church_rounded
                                    : Icons.spa_rounded,
                                size: 14,
                                color: profile.isIcocMember
                                    ? primary
                                    : Colors.amber[900],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                profile.icocChurchAffiliation != null &&
                                        profile.icocChurchAffiliation!.isNotEmpty
                                    ? profile.icocChurchAffiliation!
                                    : 'Affiliation not set (Tap Edit Profile)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: profile.isIcocMember
                                      ? primary
                                      : Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: profile.comfortBadges.map((badge) {
                          return Chip(
                            label: Text(badge, style: const TextStyle(fontSize: 10.5)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.group_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Community Members & Organizers',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Browse fellow autistic Christians, allies, and church leaders in our fellowship.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),

              // Dev member list
              for (final member in kDevFellowshipMembers)
                Card(
                  key: Key('dev_member_card_${member.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              child: Text(
                                member.initials,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    member.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: member.isIcocMember
                                    ? primary.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                member.isIcocMember ? 'ICOC Member' : 'Fellowship Guest',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: member.isIcocMember ? primary : Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.bio,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              member.isIcocMember
                                  ? Icons.church_rounded
                                  : Icons.spa_rounded,
                              size: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.churchAffiliation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                fontStyle: member.isIcocMember
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: member.comfortBadges.map((badge) {
                            return Chip(
                              label: Text(badge, style: const TextStyle(fontSize: 9.5)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
