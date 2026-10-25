import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../data/comment_repository.dart';
import '../data/post_repository.dart';
import '../domain/comment.dart';
import '../domain/feed_sort_option.dart';
import '../domain/post.dart';

/// Riverpod StateProvider for filtering reflections by intent tone tag ('All', '[Prayer Request]', etc.)
final activeFilterProvider = StateProvider<String>((ref) => 'All');

/// Riverpod StateProvider for sorting feed reflections.
final feedSortOptionProvider = StateProvider<FeedSortOption>((ref) => FeedSortOption.latest);

/// FutureProvider resolving latest discussion activity timestamps across posts.
final postActivityTimestampsProvider = FutureProvider<Map<String, DateTime>>(
  (ref) => ref.watch(commentRepositoryProvider).getLatestActivityTimestamps(),
);

/// FutureProvider resolving total comment counts across all posts.
final allCommentCountsProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(commentRepositoryProvider).getAllCommentCounts(),
);

/// StreamProvider that yields posts for a given fellowship space.
final postsStreamProvider = StreamProvider.autoDispose.family<List<Post>, String>(
  (ref, spaceKey) => ref.watch(postRepositoryProvider).watchPosts(spaceKey: spaceKey),
);

/// FutureProvider that fetches the server-computed QuietDigest summary for a given space.
final quietDigestProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, spaceKey) => ref.watch(postRepositoryProvider).getQuietDigest(spaceKey: spaceKey),
);

/// Convenience provider returning the stream of posts for the currently active space.
final currentSpacePostsProvider = Provider.autoDispose<AsyncValue<List<Post>>>((ref) {
  final currentSpace = ref.watch(activeSpaceKeyProvider);
  final postsAsync = ref.watch(postsStreamProvider(currentSpace));
  final filter = ref.watch(activeFilterProvider);

  return postsAsync.whenData((posts) {
    if (filter == 'All') return posts;
    return posts.where((p) => p.toneTag == filter).toList();
  });
});

/// StreamProvider yielding threaded comments for a given post.
final postCommentsStreamProvider = StreamProvider.autoDispose.family<List<Comment>, String>(
  (ref, postId) => ref.watch(commentRepositoryProvider).watchComments(postId: postId),
);

/// StreamProvider yielding total comment count for a given post.
final postCommentCountStreamProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, postId) => ref.watch(commentRepositoryProvider).watchCommentCount(postId: postId),
);

/// StreamProvider yielding posts authored by a specific member.
final memberPostsStreamProvider = StreamProvider.autoDispose.family<List<Post>, String>(
  (ref, authorName) => ref.watch(postRepositoryProvider).watchPostsByAuthor(authorName: authorName),
);

/// StreamProvider yielding comments authored by a specific member.
final memberCommentsStreamProvider = StreamProvider.autoDispose.family<List<Comment>, String>(
  (ref, authorName) =>
      ref.watch(commentRepositoryProvider).watchCommentsByAuthor(authorName: authorName),
);

/// StreamProvider yielding reflections bookmarked / saved for later.
final savedPostsStreamProvider = StreamProvider.autoDispose<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).watchSavedPosts(),
);
