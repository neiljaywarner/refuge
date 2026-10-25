import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Predefined calm-tech fellowship spaces in Refuge (kept for backward compatibility
/// with existing unit and BDD tests, plus Belong Circle.so spaces).
const Map<String, String> kFellowshipSpaces = {
  'general_chat': '📌 #general-chat',
  'start_here': '👋 #start-here',
  'prayer': '🙏 #prayer-sanctuary',
  'study': '📖 #weekly-study',
  'announcements': '📢 #announcements',
  'special_interests': '🧩 #special-interests-memes',
  'general': '🌿 #main-hall',
  'saved_for_later': '🔖 #saved-for-later',
};

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
  });

  final String slug;
  final String title;
  final String emoji;
  final String subtitle;
  final bool isComingSoon;
  final String? externalUrl;
  final int? trackedIssueNumber;
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
        subtitle: 'Pending — Install via PWA now; Google Play Store coming soon',
        isComingSoon: true,
        trackedIssueNumber: 30,
      ),
      BelongSpaceItem(
        slug: 'link_ios_app',
        title: 'Download the iOS App',
        emoji: '🍎',
        subtitle: 'Pending — Add to iPhone Home Screen now; App Store coming soon',
        isComingSoon: true,
        trackedIssueNumber: 31,
      ),
    ],
  ),
];

/// Riverpod StateProvider tracking the currently active fellowship space key.
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

  // Fallback to kFellowshipSpaces legacy mapping
  if (kFellowshipSpaces.containsKey(slug)) {
    final raw = kFellowshipSpaces[slug]!;
    final parts = raw.split(' ');
    final emoji = parts.isNotEmpty ? parts.first : '💬';
    final name = switch (slug) {
      'prayer' => 'Prayer Sanctuary',
      'study' => 'Weekly Study',
      'special_interests' => 'Special Interests & Memes',
      'general' => 'Main Hall',
      'general_chat' => 'General Chat',
      'start_here' => 'Start Here & Introduce Yourself',
      'announcements' => 'Announcements',
      'saved_for_later' => 'Saved for Later',
      _ =>
        parts.length > 1
            ? parts.sublist(1).join(' ').replaceAll('#', '').replaceAll('-', ' ').trim()
            : slug,
    };
    return BelongSpaceInfo(slug: slug, title: name, emoji: emoji);
  }

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
