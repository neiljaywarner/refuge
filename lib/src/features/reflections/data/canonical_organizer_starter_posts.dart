import '../domain/post.dart';

/// Normalizes space keys the same way reflection cloud queries do.
String normalizeReflectionSpaceKey(String key) {
  final clean = key.trim().toLowerCase();
  if (clean.isEmpty) return 'general_chat';
  return clean;
}

/// Five warm organizer anchors (`isDemo: false`) used when a prod space has no posts.
final List<Post> kCanonicalOrganizerReflections = [
  Post(
    id: 'canonical-organizer-welcome',
    authorName: 'Belong Organizer (DFW)',
    spaceKey: 'start_here',
    toneTag: '[Welcome]',
    specialInterestTag: 'Neurodivergent Fellowship',
    content: 'Welcome to Belong on the Spectrum! Feel free to introduce yourself here at your own pace, share a favorite hobby or special interest, or simply read quietly.',
    timestamp: DateTime.utc(2026, 10, 24, 12, 0),
    reactions: {'pray': 9, 'peace': 14, 'encouraged': 18},
    isDemo: false,
  ),
  Post(
    id: 'canonical-general-fellowship',
    authorName: 'Hannah W. (Dallas)',
    spaceKey: 'general_chat',
    toneTag: '[Fellowship]',
    content: 'So grateful for a calm community space without flashing popups or algorithmic timelines. Wishing everyone a peaceful, restful week!',
    timestamp: DateTime.utc(2026, 10, 24, 13, 30),
    reactions: {'pray': 6, 'peace': 12, 'encouraged': 10},
    isDemo: false,
  ),
  Post(
    id: 'canonical-study-quiet-waters',
    authorName: 'Pastor Thomas (Melbourne)',
    spaceKey: 'study',
    toneTag: '[Question]',
    content: 'In Psalm 23, David reflects on "quiet waters." How does that specific imagery ground your mental peace during hectic workdays?',
    timestamp: DateTime.utc(2026, 10, 24, 15, 0),
    reactions: {'pray': 8, 'peace': 11, 'relatable': 7},
    isDemo: false,
  ),
  Post(
    id: 'canonical-prayer-sensory-rest',
    authorName: 'Elena R. (Colorado)',
    spaceKey: 'prayer',
    toneTag: '[Comfort Only]',
    content: 'Heavy sensory fatigue after errands today with fluorescent glare. Just needed to share in a safe room. No advice needed, just glad this quiet space exists.',
    timestamp: DateTime.utc(2026, 10, 24, 16, 45),
    reactions: {'pray': 15, 'peace': 19},
    isDemo: false,
  ),
  Post(
    id: 'canonical-memes-church-acoustics',
    authorName: 'Nathan K. (Texas)',
    spaceKey: 'memes',
    toneTag: '[Autism & Faith Meme]',
    specialInterestTag: 'Church Acoustics',
    imageUrl:
        'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600&auto=format&fit=crop&q=80',
    content: 'When the pastor says "make a joyful noise unto the Lord" and my autistic brain starts calculating the sanctuary\'s 432Hz reverberation decay. Praise God for loop earplugs in worship! 😄🎧',
    timestamp: DateTime.utc(2026, 10, 24, 17, 15),
    reactions: {'pray': 5, 'peace': 9, 'relatable': 24},
    isDemo: false,
  ),
];

/// Read-only starter rows for [spaceKey] when local and cloud feeds are empty (#664).
List<Post> organizerStarterPostsForSpace(String spaceKey) {
  final wanted = normalizeReflectionSpaceKey(spaceKey);
  return kCanonicalOrganizerReflections
      .where((post) => normalizeReflectionSpaceKey(post.spaceKey) == wanted)
      .toList(growable: false);
}
