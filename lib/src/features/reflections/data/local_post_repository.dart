import 'dart:async';

import '../domain/post.dart';
import 'post_repository.dart';

/// Resilient local-first in-memory implementation with asynchronous broadcast streams.
class LocalPostRepository implements PostRepository {
  final List<Post> _store = [];
  final StreamController<List<Post>> _controller =
      StreamController<List<Post>>.broadcast();

  LocalPostRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _store.addAll([
      Post(
        id: '1',
        authorName: 'David M. (UK)',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content:
            'Please pray for peace of mind this week. Transitioning to a new routine has been disorienting. Reminding myself that rest is spiritual.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        reactions: {'pray': 6, 'peace': 4},
      ),
      Post(
        id: '2',
        authorName: 'Elena R. (Colorado)',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content:
            'Heavy sensory fatigue after errands today with fluorescent glare. Just needed to share in a safe room. No advice needed, just glad this quiet space exists.',
        timestamp: now.subtract(const Duration(hours: 2)),
        reactions: {'pray': 11, 'peace': 14},
      ),
      Post(
        id: '3',
        authorName: 'Pastor Thomas (Melbourne)',
        spaceKey: 'study',
        toneTag: '[Question]',
        content:
            'In Psalm 23, David reflects on "quiet waters." How does that specific imagery ground your mental peace during hectic workdays?',
        timestamp: now.subtract(const Duration(hours: 5)),
        reactions: {'pray': 5, 'peace': 8},
      ),
      Post(
        id: '4',
        authorName: 'Nathan K. (Texas)',
        spaceKey: 'special_interests',
        toneTag: '[Autism & Faith Meme]',
        specialInterestTag: 'Church Acoustics',
        content:
            'When the pastor says "make a joyful noise unto the Lord" and my autistic brain starts calculating the sanctuary\'s 432Hz reverberation decay. Praise God for loop earplugs in worship! 😄🎧',
        timestamp: now.subtract(const Duration(minutes: 15)),
        reactions: {'pray': 4, 'peace': 8, 'relatable': 18},
      ),
      Post(
        id: '5',
        authorName: 'Sarah L. (Oxford)',
        spaceKey: 'study',
        toneTag: '[Bible Deep-Dive]',
        specialInterestTag: 'Markan Chiasms',
        content:
            'My special interest is literary chiasms in Mark. Did you know Mark 2:27 ("The Sabbath was made for man, not man for the Sabbath") is a perfect inverted parallel structure ABBA? Jesus loved systematic clarity!',
        timestamp: now.subtract(const Duration(hours: 1)),
        reactions: {'pray': 7, 'peace': 9, 'relatable': 14},
      ),
    ]);
    _notify();
  }

  void _notify() => _controller.add(List.unmodifiable(_store));
 
   @override
   Future<List<Post>> getPosts({required String spaceKey}) async =>
       _store.where((p) => p.spaceKey == spaceKey).toList();

  @override
  Future<Post> createPost(Post post) async {
    _store.insert(0, post);
    _notify();
    return post;
  }

  @override
  Future<void> addReaction({
    required String postId,
    required String reactionType,
  }) async {
    final index = _store.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _store[index];
      final currentCount = post.reactions[reactionType] ?? 0;
      final updatedReactions = Map<String, int>.from(post.reactions);
      updatedReactions[reactionType] = currentCount + 1;
      _store[index] = post.copyWith(reactions: updatedReactions);
      _notify();
    }
  }

  @override
  Stream<List<Post>> watchPosts({required String spaceKey}) async* {
    yield _store.where((p) => p.spaceKey == spaceKey).toList();
    yield* _controller.stream.map(
      (posts) => posts.where((p) => p.spaceKey == spaceKey).toList(),
    );
  }

  @override
  Future<String?> getQuietDigest({required String spaceKey}) async {
    final posts = _store.where((p) => p.spaceKey == spaceKey).toList();
    if (posts.isEmpty) {
      return 'A quiet, unhurried space awaiting the first community reflection.';
    }
    final totalReactions = posts.fold<int>(
      0,
      (sum, p) => sum + p.reactions.values.fold<int>(0, (a, b) => a + b),
    );
    return 'Gathered in peace • ${posts.length} reflections shared with $totalReactions care affirmations.';
  }
}
