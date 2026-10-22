import 'feed_sort_option.dart';
import 'post.dart';

/// Pure functional service executing deterministic feed sorting across all 7 criteria.
class FeedSortService {
  /// Sorts a list of [Post]s according to [sortOption].
  ///
  /// [latestActivityByPost] maps postId to the timestamp of its latest comment/reply.
  /// [commentCounts] maps postId to its total comments.
  /// [userInterests] sets of special interest keywords/topics favored by the user.
  static List<Post> sortPosts(
    List<Post> posts, {
    required FeedSortOption sortOption,
    Map<String, DateTime>? latestActivityByPost,
    Map<String, int>? commentCounts,
    Set<String>? userInterests,
  }) {
    final list = List<Post>.from(posts);
    switch (sortOption) {
      case FeedSortOption.latest:
        list.sort((a, b) {
          final comp = b.timestamp.compareTo(a.timestamp);
          if (comp != 0) return comp;
          return b.id.compareTo(a.id);
        });
        break;

      case FeedSortOption.oldest:
        list.sort((a, b) {
          final comp = a.timestamp.compareTo(b.timestamp);
          if (comp != 0) return comp;
          return a.id.compareTo(b.id);
        });
        break;

      case FeedSortOption.likes:
        list.sort((a, b) {
          final aLikes = a.reactions.values.fold<int>(0, (sum, val) => sum + val);
          final bLikes = b.reactions.values.fold<int>(0, (sum, val) => sum + val);
          final comp = bLikes.compareTo(aLikes);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;

      case FeedSortOption.popular:
        list.sort((a, b) {
          final aLikes = a.reactions.values.fold<int>(0, (sum, val) => sum + val);
          final bLikes = b.reactions.values.fold<int>(0, (sum, val) => sum + val);
          final aComments = commentCounts?[a.id] ?? 0;
          final bComments = commentCounts?[b.id] ?? 0;
          final aScore = aLikes + (aComments * 2);
          final bScore = bLikes + (bComments * 2);
          final comp = bScore.compareTo(aScore);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;

      case FeedSortOption.newActivity:
        list.sort((a, b) {
          final aActivity = latestActivityByPost?[a.id] ?? a.timestamp;
          final bActivity = latestActivityByPost?[b.id] ?? b.timestamp;
          final comp = bActivity.compareTo(aActivity);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;

      case FeedSortOption.forYou:
        list.sort((a, b) {
          final aMatchesInterest = _matchesUserInterest(a, userInterests);
          final bMatchesInterest = _matchesUserInterest(b, userInterests);
          if (aMatchesInterest && !bMatchesInterest) return -1;
          if (!aMatchesInterest && bMatchesInterest) return 1;

          // Secondary ranking: qualitative care affirmations + recency
          final aScore = _computeCalmAffinityScore(a);
          final bScore = _computeCalmAffinityScore(b);
          final comp = bScore.compareTo(aScore);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;

      case FeedSortOption.alphabetical:
        list.sort((a, b) {
          final aClean = a.content.trim().toLowerCase();
          final bClean = b.content.trim().toLowerCase();
          final comp = aClean.compareTo(bClean);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;
    }
    return list;
  }

  static bool _matchesUserInterest(Post post, Set<String>? userInterests) {
    if (userInterests == null || userInterests.isEmpty) return false;
    final tag = post.specialInterestTag?.toLowerCase();
    final tone = post.toneTag.toLowerCase();
    final content = post.content.toLowerCase();
    for (final interest in userInterests) {
      final i = interest.toLowerCase().trim();
      if (i.isEmpty) continue;
      if (tag != null && tag.contains(i)) return true;
      if (tone.contains(i)) return true;
      if (content.contains(i)) return true;
    }
    return false;
  }

  static double _computeCalmAffinityScore(Post post) {
    final pray = post.reactions['pray'] ?? 0;
    final peace = post.reactions['peace'] ?? 0;
    final encouraged = post.reactions['encouraged'] ?? 0;
    final relatable = post.reactions['relatable'] ?? 0;
    return (pray * 1.5) + (peace * 1.5) + (encouraged * 1.2) + (relatable * 1.0);
  }
}
