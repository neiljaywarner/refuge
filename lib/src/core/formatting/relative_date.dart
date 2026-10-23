/// Relative or calendar label shared by posts, message threads, and direct
/// messages.
///
/// "Just now", "15m ago", "2 hrs ago", "3 days ago", or a calendar day such as
/// "Oct 20". Posts, message threads, and direct messages share this label.
String formatRelativeDate(DateTime when, [DateTime? clockNow]) {
  final now = clockNow ?? DateTime.now();
  final diff = now.difference(when);

  if (diff.isNegative || diff.inSeconds < 60) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hr${h == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[when.month - 1];
  final day = when.day;
  return '$month $day';
}
