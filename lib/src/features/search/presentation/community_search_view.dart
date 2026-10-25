import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../reflections/data/post_repository.dart';
import '../../reflections/domain/post.dart';
import '../../reflections/presentation/reflection_card.dart';

/// Instant keyword, author, and special-interest search view for the `Search`
/// bottom navigation tab (#18, #22), built as a [HookConsumerWidget].
class CommunitySearchView extends HookConsumerWidget {
  const CommunitySearchView({super.key, required this.repository, required this.isContrast});

  final PostRepository repository;
  final bool isContrast;

  static const List<String> _searchableSpaces = [
    'prayer',
    'study',
    'announcements',
    'special_interests',
    'general',
    'general_chat',
    'start_here',
    'memes',
    'resources_videos',
    'actually_autistic_chat',
    'friends_chat',
    'family_chat',
  ];

  Future<List<Post>> _loadAllPosts() async {
    final seenIds = <String>{};
    final results = <Post>[];
    for (final space in _searchableSpaces) {
      final posts = await repository.getPosts(spaceKey: space);
      for (final post in posts) {
        if (seenIds.add(post.id)) {
          results.add(post);
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryController = useTextEditingController();
    final query = useValueListenable(queryController).text.trim().toLowerCase();
    final allPostsSnapshot = useFuture(useMemoized(_loadAllPosts, [repository]));

    final posts = (allPostsSnapshot.data ?? const <Post>[]).where((p) {
      if (query.isEmpty) return true;
      return p.content.toLowerCase().contains(query) ||
          p.authorName.toLowerCase().contains(query) ||
          p.toneTag.toLowerCase().contains(query) ||
          (p.specialInterestTag?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Padding(
      padding: const .all(12),
      child: Column(
        children: [
          TextField(
            key: const Key('community_search_text_field'),
            controller: queryController,
            decoration: InputDecoration(
              hintText: 'Search posts, Memes, Online Resources / Videos, or special interests...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: queryController.clear,
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: .circular(12)),
              isDense: true,
            ),
          ),
          const Gap(10),
          Expanded(
            child: posts.isEmpty
                ? const Center(
                    child: Text(
                      'No matching community posts found.',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final p = posts[index];
                      return ReflectionCard(
                        post: p,
                        isContrast: isContrast,
                        onAddReaction: (reactionType) =>
                            repository.addReaction(postId: p.id, reactionType: reactionType),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
