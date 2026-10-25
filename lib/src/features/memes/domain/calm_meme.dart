/// Domain model representing a curated calm-tech meme or relatable insight.
class CalmMeme {
  final String title;
  final String icon;
  final String subtitle;
  final String tag;
  final String body;
  final String? imageUrl;

  const CalmMeme({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.tag,
    required this.body,
    this.imageUrl,
  });

  Map<String, String> toMap() => {
    'title': title,
    'icon': icon,
    'subtitle': subtitle,
    'tag': tag,
    'body': body,
    if (imageUrl != null) 'imageUrl': imageUrl!,
  };

  factory CalmMeme.fromMap(Map<String, String> map) => CalmMeme(
    title: map['title'] ?? '',
    icon: map['icon'] ?? '🖼️',
    subtitle: map['subtitle'] ?? '',
    tag: map['tag'] ?? '',
    body: map['body'] ?? '',
    imageUrl: map['imageUrl'],
  );
}

/// Curated Belong on the Spectrum calm-tech memes: zero flashing strobe animations,
/// zero third-party telemetry, 100% wholesome, sensory-safe, and relatable.
const List<CalmMeme> kCuratedCalmMemes = [
  CalmMeme(
    title: 'Elijah Under the Broom Tree',
    icon: '🍞 💤',
    subtitle: '1 Kings 19:5 — Snack & Nap',
    tag: 'Burnout & Recovery',
    body: 'When you have severe sensory burnout and think you are done with ministry, but God\'s holy prescription is literally a warm cake of bread and a nap under the broom tree.',
    imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop&q=80',
  ),
  CalmMeme(
    title: '2 Hours of Fellowship vs 3 Days in Dark Room',
    icon: '🕶️ 🤫',
    subtitle: 'Sensory Math for the Saints',
    tag: 'Masking & Church',
    body: 'Masking through Sunday fellowship hall small talk for 90 minutes = 72 hours of mandatory quiet sensory recharge under a weighted blanket in a dark room.',
  ),
  CalmMeme(
    title: 'Specially Interested by Divine Design',
    icon: '🧩 🚂',
    subtitle: 'Psalm 139:14 — Fearfully Made',
    tag: 'Special Interests',
    body: 'When someone asks a casual 5-second question about church history or train switching gears, and my autistic brain prepares a 45-minute PowerPoint with handouts.',
    imageUrl:
        'https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=600&auto=format&fit=crop&q=80',
  ),
  CalmMeme(
    title: 'Reading Greek Verbs at 2 AM',
    icon: '📖 🦉',
    subtitle: 'Hyperfixation as Worship',
    tag: 'Bible Deep-Dive',
    body: 'Who needs circadian rhythm when the aorist subjunctive in Romans 8:28 is demanding our immediate, uninterrupted hyperfixation until dawn?',
  ),
];
