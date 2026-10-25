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
    try {
      _sortInPlace(
        list,
        sortOption: sortOption,
        latestActivityByPost: latestActivityByPost,
        commentCounts: commentCounts,
        userInterests: userInterests,
      );
    } catch (_) {
      // A comparator failure must not red-screen the feed. Keep the
      // pre-sort copy so the member can still read reflections.
      return List<Post>.from(posts);
    }
    return list;
  }

  static void _sortInPlace(
    List<Post> list, {
    required FeedSortOption sortOption,
    Map<String, DateTime>? latestActivityByPost,
    Map<String, int>? commentCounts,
    Set<String>? userInterests,
  }) {
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
          final aLikes = a.reactions.values.fold<int>(
            0,
            (sum, val) => sum + val,
          );
          final bLikes = b.reactions.values.fold<int>(
            0,
            (sum, val) => sum + val,
          );
          final comp = bLikes.compareTo(aLikes);
          if (comp != 0) return comp;
          return b.timestamp.compareTo(a.timestamp);
        });
        break;

      case FeedSortOption.popular:
        list.sort((a, b) {
          final aLikes = a.reactions.values.fold<int>(
            0,
            (sum, val) => sum + val,
          );
          final bLikes = b.reactions.values.fold<int>(
            0,
            (sum, val) => sum + val,
          );
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
  }

  static bool _matchesUserInterest(Post post, Set<String>? userInterests) {
    if (userInterests == null || userInterests.isEmpty) return false;
    final tag = post.specialInterestTag?.toLowerCase();
    final tone = post.toneTag.toLowerCase();
    final content = post.content.toLowerCase();
    for (final interest in userInterests) {
      final i = interest.toLowerCase().trim();
      if (i.length < 4) continue;
      try {
        final pattern = RegExp('\\b${RegExp.escape(i)}\\b');
        if (tag != null && pattern.hasMatch(tag)) return true;
        if (pattern.hasMatch(tone)) return true;
        if (pattern.hasMatch(content)) return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  static double _computeCalmAffinityScore(Post post) {
    final pray = post.reactions['pray'] ?? 0;
    final peace = post.reactions['peace'] ?? 0;
    final encouraged = post.reactions['encouraged'] ?? 0;
    final relatable = post.reactions['relatable'] ?? 0;
    return (pray * 1.5) +
        (peace * 1.5) +
        (encouraged * 1.2) +
        (relatable * 1.0);
  }
}

/// Signed-in / demo / tone filter plus [FeedSortService] ordering.
///
/// The feed screen applies this on every sort or filter tap. Metadata maps
/// are optional so a failed comment lookup sorts with creation time and
/// zero replies instead of throwing.
class FeedQuery {
  static Set<String> interestsFrom({
    required Iterable<String> comfortBadges,
    required String bio,
    String? tagline,
  }) {
    return {
      ...comfortBadges,
      if (bio.isNotEmpty) ...bio.split(RegExp(r'[\s,.]+')),
      if (tagline != null) ...tagline.split(RegExp(r'[\s,.]+')),
    };
  }

  /// Returns true if [post] contains developer test junk, debugging tokens,
  /// numbered placeholder phrases, or bot artifacts that should not be visible
  /// in calm community feeds (#501, #611).
  static bool isTestJunk(Post post) {
    final content = post.content.toLowerCase().trim();
    final author = post.authorName.toLowerCase().trim();
    if (content.isEmpty) return true;

    if (content.contains('blah your face') ||
        content.contains('grokbot') ||
        author.contains('grokbot') ||
        content.contains('cursor test') ||
        content.contains('[test]')) {
      return true;
    }

    final junkRegex = RegExp(
      r'\b(test\s*\d+|test\s*post|quick\s*test|debug\s*test|hello\s*world\s*test|asdf+|lorem\s*ipsum|foo\s*bar)\b',
    );
    if (junkRegex.hasMatch(content) || junkRegex.hasMatch(author)) {
      return true;
    }

    return false;
  }

  static bool _isTestJunk(Post post) => isTestJunk(post);

  static List<Post> apply({
    required List<Post> posts,
    required String toneFilter,
    required FeedSortOption sort,
    required bool signedIn,
    Map<String, DateTime>? latestActivityByPost,
    Map<String, int>? commentCounts,
    Set<String>? userInterests,
  }) {
    final nonJunk = posts.where((p) => !_isTestJunk(p)).toList();
    final available = signedIn
        ? nonJunk.where((p) => !p.isDemo).toList()
        : nonJunk;
    final filtered = toneFilter == 'All'
        ? available
        : available.where((p) => p.toneTag == toneFilter).toList();
    return FeedSortService.sortPosts(
      filtered,
      sortOption: sort,
      latestActivityByPost: latestActivityByPost,
      commentCounts: commentCounts,
      userInterests: userInterests,
    );
  }
}
