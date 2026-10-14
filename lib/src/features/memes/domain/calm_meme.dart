/// Domain model representing a curated calm-tech meme or relatable insight.
class CalmMeme {
  final String title;
  final String icon;
  final String subtitle;
  final String tag;
  final String body;

  const CalmMeme({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.tag,
    required this.body,
  });

  Map<String, String> toMap() => {
    'title': title,
    'icon': icon,
    'subtitle': subtitle,
    'tag': tag,
    'body': body,
  };

  factory CalmMeme.fromMap(Map<String, String> map) => CalmMeme(
    title: map['title'] ?? '',
    icon: map['icon'] ?? '🖼️',
    subtitle: map['subtitle'] ?? '',
    tag: map['tag'] ?? '',
    body: map['body'] ?? '',
  );
}

/// Curated Belong on the Spectrum calm-tech memes: zero flashing strobe animations,
/// zero third-party telemetry, 100% wholesome and relatable.
const List<CalmMeme> kCuratedCalmMemes = [
  CalmMeme(
    title: 'Elijah Under the Broom Tree',
    icon: '🍞 💤',
    subtitle: '1 Kings 19:5 — Snack & Nap',
    tag: 'Burnout & Recovery',
    body: 'When you have severe sensory burnout and think you are done with ministry, but God\'s holy prescription is literally a warm cake of bread and a nap under the broom tree.',
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
  ),
  CalmMeme(
    title: 'Reading Greek Verbs at 2 AM',
    icon: '📖 🦉',
    subtitle: 'Hyperfixation as Worship',
    tag: 'Bible Deep-Dive',
    body: 'Who needs circadian rhythm when the aorist subjunctive in Romans 8:28 is demanding our immediate, uninterrupted hyperfixation until dawn?',
  ),
];
