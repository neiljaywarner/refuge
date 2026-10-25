/// Multi-criteria feed sorting options for unhurried community browsing.
enum FeedSortOption {
  latest('Latest', '🕒', 'Newest reflections first'),
  forYou('For you', '✨', 'Curated for your interests & unhurried care'),
  newActivity(
    'New Activity',
    '💬',
    'Recent discussion replies floating to top',
  ),
  oldest('Oldest', '📜', 'Chronological earliest reflections first'),
  popular('Popular', '🔥', 'Most engaged reflections & discussions'),
  likes('Likes', '❤️', 'Highest care affirmations & qualitative reactions'),
  alphabetical('Alphabetical', '🔤', 'Alphabetical A-Z by reflection text');

  final String label;
  final String emoji;
  final String description;

  const FeedSortOption(this.label, this.emoji, this.description);
}
