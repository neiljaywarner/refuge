import 'dart:async';

import '../domain/post.dart';
import 'post_repository.dart';

/// Resilient local-first in-memory implementation with asynchronous broadcast streams.
/// Seeds both the original Sanctuary spaces and the Circle.so-style Belong spaces.
class LocalPostRepository implements PostRepository {
  final List<Post> _store = [];
  final StreamController<List<Post>> _controller =
      StreamController<List<Post>>.broadcast();

  LocalPostRepository({bool isDevMode = true, List<Post>? initialPosts}) {
    if (initialPosts != null) {
      _store.addAll(initialPosts);
    } else if (isDevMode) {
      _seedInitialData();
    }
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
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
        isDemo: true,
      ),
      Post(
        id: '6',
        authorName: 'Belong Organizer (DFW)',
        spaceKey: 'start_here',
        toneTag: '[Welcome]',
        specialInterestTag: 'Neurodivergent Fellowship',
        content:
            'Welcome to Belong on the Spectrum! Feel free to introduce yourself here at your own pace, share a favorite hobby or special interest, or simply read quietly.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        reactions: {'pray': 9, 'peace': 12, 'encouraged': 15},
        isDemo: true,
      ),
      Post(
        id: '7',
        authorName: 'Hannah W. (Dallas)',
        spaceKey: 'general_chat',
        toneTag: '[Fellowship]',
        content:
            'So grateful for a calm community space without flashing popups or algorithmic timelines. Wishing everyone a peaceful evening!',
        timestamp: now.subtract(const Duration(minutes: 25)),
        reactions: {'pray': 5, 'peace': 10},
        isDemo: true,
      ),
      Post(
        id: '8',
        authorName: 'Caleb T. (Fort Worth)',
        spaceKey: 'memes',
        toneTag: '[Autism & Faith Meme]',
        specialInterestTag: 'BiblicalMaps',
        imageUrl:
            'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=600&auto=format&fit=crop&q=80',
        content:
            'Me opening the back of my Bible to stare at Paul\'s 3rd Missionary Journey map for 45 minutes straight instead of making small talk in the lobby. 🗺️♾️',
        timestamp: now.subtract(const Duration(minutes: 40)),
        reactions: {'pray': 3, 'peace': 7, 'relatable': 22},
        isDemo: true,
      ),
      Post(
        id: '9',
        authorName: 'Rachel S. (Arlington)',
        spaceKey: 'resources_videos',
        toneTag: '[Resource]',
        specialInterestTag: 'Sensory Friendly Worship',
        content:
            'Shared a calm 10-minute video guide on creating sensory-friendly church welcome bags and quiet rooms (caption transcript included, zero autoplay).',
        timestamp: now.subtract(const Duration(hours: 3)),
        reactions: {'pray': 4, 'peace': 9, 'encouraged': 11},
        isDemo: true,
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
