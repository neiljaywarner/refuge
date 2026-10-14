import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fellowship_spaces/domain/fellowship_space.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';

/// Riverpod StateProvider for filtering reflections by intent tone tag ('All', '[Prayer Request]', etc.)
final activeFilterProvider = StateProvider<String>((ref) => 'All');

/// StreamProvider that yields posts for a given fellowship space.
final postsStreamProvider =
    StreamProvider.autoDispose.family<List<Post>, String>(
  (ref, spaceKey) =>
      ref.watch(postRepositoryProvider).watchPosts(spaceKey: spaceKey),
);

/// FutureProvider that fetches the server-computed QuietDigest summary for a given space.
final quietDigestProvider =
    FutureProvider.autoDispose.family<String?, String>(
  (ref, spaceKey) =>
      ref.watch(postRepositoryProvider).getQuietDigest(spaceKey: spaceKey),
);

/// Convenience provider returning the stream of posts for the currently active space.
final currentSpacePostsProvider =
    Provider.autoDispose<AsyncValue<List<Post>>>((ref) {
  final currentSpace = ref.watch(activeSpaceKeyProvider);
  final postsAsync = ref.watch(postsStreamProvider(currentSpace));
  final filter = ref.watch(activeFilterProvider);

  return postsAsync.whenData((posts) {
    if (filter == 'All') return posts;
    return posts.where((p) => p.toneTag == filter).toList();
  });
});
