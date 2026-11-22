import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../install/domain/phone_install_links.dart';

/// Represents a single space or external/pending link in the Circle.so-style
/// Belong on the Spectrum navigation hierarchy.
@immutable
class BelongSpaceItem {
  const BelongSpaceItem({
    required this.slug,
    required this.title,
    required this.emoji,
    required this.subtitle,
    this.isComingSoon = false,
    this.externalUrl,
    this.trackedIssueNumber,
    this.phoneInstallFocus,
  });

  final String slug;
  final String title;
  final String emoji;
  final String subtitle;
  final bool isComingSoon;
  final String? externalUrl;
  final int? trackedIssueNumber;

  /// Opens the in-app phone guide instead of a Coming Soon card.
  final PhoneInstallFocus? phoneInstallFocus;

  /// A fellowship space with its own post feed. The space switcher lists these.
  ///
  /// Coming-soon cards, external links, install guides, and the members
  /// directory stay in the Spaces directory. They are not switcher rows.
  bool get isPostableSpace =>
      !isComingSoon &&
      externalUrl == null &&
      phoneInstallFocus == null &&
      slug != 'members_directory';

  /// Emoji and title for the switcher. No channel hash.
  String get spaceSwitcherLabel => '$emoji $title';
}

/// Represents a collapsible/grouped section in the Circle.so-style Spaces view.
@immutable
class BelongSpaceSection {
  const BelongSpaceSection({required this.heading, required this.items});

  final String heading;
  final List<BelongSpaceItem> items;
}

/// Official Circle.so-style navigation hierarchy for **Belong on the Spectrum**
/// (`https://www.belongonthespectrum.com/`).
const List<BelongSpaceSection> kBelongSpaceSections = [
  BelongSpaceSection(
    heading: 'PINNED',
    items: [
      BelongSpaceItem(
        slug: 'prayer',
        title: 'Prayer Sanctuary',
        emoji: '🙏',
        subtitle: 'Quiet fellowship, prayer requests & peaceful encouragement (Home)',
      ),
      BelongSpaceItem(
        slug: 'general_chat',
        title: 'General Chat',
        emoji: '📌',
        subtitle: 'Pinned everyday fellowship & encouragement',
      ),
    ],
  ),
  BelongSpaceSection(
    heading: 'WELCOME',
    items: [
      BelongSpaceItem(
        slug: 'start_here',
        title: 'Start Here & Introduce Yourself',
        emoji: '👋',
        subtitle: 'Say hello at your own pace and share your special interests',
      ),
      BelongSpaceItem(
        slug: 'announcements',
        title: 'Announcements',
        emoji: '📢',
        subtitle: 'Calm community updates from Belong organizers',
      ),
      BelongSpaceItem(
        slug: 'study',
        title: 'Weekly Study',
        emoji: '📖',
        subtitle: 'Thematic questions and scripture meditations',
      ),
    ],
  ),
  BelongSpaceSection(
    heading: 'COMMUNITY',
    items: [
      BelongSpaceItem(
        slug: 'saved_for_later',
        title: 'Saved for Later',
        emoji: '🔖',
        subtitle: 'Private bookmarks — unhurried reflections saved for quiet reading',
      ),
      BelongSpaceItem(
        slug: 'members_directory',
        title: 'Members Section & Directory',
        emoji: '👥',
        subtitle: 'Community profiles, church affiliations & fellowship connections',
      ),
      BelongSpaceItem(
        slug: 'memes',
        title: 'Memes',
        emoji: '😂',
        subtitle: 'Autism, faith & wholesome neurodivergent humor',
      ),
      BelongSpaceItem(
        slug: 'resources_videos',
        title: 'Online Resources / Videos',
        emoji: '🎥',
        subtitle: 'Helpful videos, podcasts & articles (zero autoplay)',
      ),
      BelongSpaceItem(
        slug: 'actually_autistic_chat',
        title: 'Actually Autistic Chat',
        emoji: '♾️',
        subtitle: 'Peer fellowship by and for autistic members',
      ),
      BelongSpaceItem(
        slug: 'friends_chat',
        title: 'Friends Chat',
        emoji: '🧑‍🤝‍🧑',
        subtitle: 'Welcoming space for friends and allies',
      ),
      BelongSpaceItem(
        slug: 'family_chat',
        title: 'Family Chat',
        emoji: '🏡',
        subtitle: 'Support and encouragement for parents, spouses & families',
      ),
    ],
  ),
  BelongSpaceSection(
    heading: 'ACTUALLY AUTISTIC',
    items: [
      BelongSpaceItem(
        slug: 'actually_autistic_events',
        title: 'Actually Autistic Events',
        emoji: '🗓️',
        subtitle: 'Upcoming sensory-friendly meetups & gatherings',
        isComingSoon: true,
        trackedIssueNumber: 28,
      ),
    ],
  ),
  BelongSpaceSection(
    heading: 'LINKS',
    items: [
      BelongSpaceItem(
        slug: 'link_community_guidelines',
        title: 'Community Guidelines',
        emoji: '📜',
        subtitle: 'Pending — Our shared kindness & sensory comfort commitments',
        isComingSoon: true,
        trackedIssueNumber: 29,
      ),
      BelongSpaceItem(
        slug: 'link_dfw_church',
        title: 'DFW Church',
        emoji: '⛪',
        subtitle: 'Visit dfwchurch.org',
        externalUrl: 'https://dfwchurch.org',
      ),
      BelongSpaceItem(
        slug: 'link_android_app',
        title: 'Download the Android App',
        emoji: '🤖',
        subtitle: 'Android open beta. The Play Store link comes later.',
        phoneInstallFocus: PhoneInstallFocus.android,
        trackedIssueNumber: 30,
      ),
      BelongSpaceItem(
        slug: 'link_ios_app',
        title: 'Download the iOS App',
        emoji: '🍎',
        subtitle: 'App Store and TestFlight are pending. Website steps are inside.',
        phoneInstallFocus: PhoneInstallFocus.ios,
        trackedIssueNumber: 31,
      ),
    ],
  ),
];

/// Postable spaces in directory order. The space switcher reads this list.
final List<BelongSpaceItem> kPostableBelongSpaces = [
  for (final section in kBelongSpaceSections)
    for (final item in section.items)
      if (item.isPostableSpace) item,
];

/// Riverpod StateProvider tracking the currently active fellowship space key.
///
/// First-launch default stays General Chat. Remembering the last space, and
/// a Prayer Sanctuary first launch, are a later change.
final activeSpaceKeyProvider = StateProvider<String>((ref) => 'general_chat');

/// Human-friendly display metadata for a fellowship space (#618).
@immutable
class BelongSpaceInfo {
  const BelongSpaceInfo({required this.slug, required this.title, required this.emoji});

  final String slug;
  final String title;
  final String emoji;
}

/// Resolves human-friendly space title and emoji from any space slug or legacy key (#618).
BelongSpaceInfo getBelongSpaceInfo(String slug) {
  for (final section in kBelongSpaceSections) {
    for (final item in section.items) {
      if (item.slug == slug) {
        return BelongSpaceInfo(slug: item.slug, title: item.title, emoji: item.emoji);
      }
    }
  }

  // Stored posts may still use a key from before this list. Resolve a title
  // without rewriting the key, so Main Hall (`general`) and Special Interests
  // stay distinct from General Chat and Memes.
  final legacy = _legacyFellowshipSpace(slug);
  if (legacy != null) return legacy;

  // Fallback for custom or unknown slugs
  final cleanName = slug
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
  return BelongSpaceInfo(
    slug: slug,
    title: cleanName.isNotEmpty ? cleanName : 'Community Feed',
    emoji: '💬',
  );
}

/// Titles for stored space keys that are not rows in [kBelongSpaceSections].
///
/// Weekly Study is a real postable space (`study`) in that list. Main Hall
/// (`general`) is not a second switcher row: General Chat (`general_chat`) is
/// the canonical space. A stored `general` post still displays as Main Hall
/// and stays in its own feed. Special Interests posts stay on
/// `special_interests`; Memes is the canonical space for new posts.
BelongSpaceInfo? _legacyFellowshipSpace(String slug) => switch (slug) {
  'general' => const BelongSpaceInfo(slug: 'general', title: 'Main Hall', emoji: '🌿'),
  'special_interests' => const BelongSpaceInfo(
    slug: 'special_interests',
    title: 'Special Interests & Memes',
    emoji: '🧩',
  ),
  _ => null,
};
