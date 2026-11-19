import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/pending_post_outbox.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository_factory.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

/// List and increment both fail the way the dev browser fails closed:
/// the Appwrite table is missing or the origin is not registered.
class _DownMirror implements ReflectionMirror {
  int increments = 0;

  @override
  Future<void> upsertPost(Post post) async => throw StateError('appwrite down');

  @override
  Future<void> incrementReaction({required String postId, required String column}) async {
    increments++;
    throw StateError('appwrite down');
  }

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async =>
      throw StateError('appwrite down');

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async => throw StateError('appwrite down');
}

Post _note(String id) => Post(
  id: id,
  authorName: 'Fellow Member',
  spaceKey: 'prayer',
  toneTag: '[Support]',
  content: 'A quiet note for the prayer room.',
  timestamp: DateTime.utc(2026, 11, 10, 3),
  reactions: const {'relatable': 0},
);

void main() {
  test('the default reflection repository does not call Appwrite', () {
    final repo = PostRepositoryFactory.create(flavor: AppFlavor.dev);
    expect(repo, isA<AppwritePostRepository>());
    expect((repo as AppwritePostRepository).mirrorsReflections, isFalse);

    final prod = PostRepositoryFactory.create(flavor: AppFlavor.prod) as AppwritePostRepository;
    expect(prod.mirrorsReflections, isFalse);
    expect(prod.isDevMode, isFalse);
  });

  test('Firestore reflections still load when the Appwrite list throws', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-live').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );

    final posts = await repo.getPosts(spaceKey: 'prayer');

    expect(posts.map((post) => post.id), contains('post-live'));
    expect(posts.singleWhere((post) => post.id == 'post-live').content, contains('prayer room'));
  });

  test('a Firestore write survives reload when Appwrite upsert throws', () async {
    final fs = FakeFirebaseFirestore();
    final memory = <String, String>{};
    final first = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'dev', memory: memory),
    );

    await first.createPost(_note('post-kept'));

    final reloaded = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'dev', memory: memory),
    );
    final posts = await reloaded.getPosts(spaceKey: 'prayer');

    expect(posts.map((post) => post.id), contains('post-kept'));
  });

  test('Relate toggles back to 0 and a failed cloud write rolls the tap back', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-relate').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });
    final mirror = _DownMirror();
    final fallback = LocalPostRepository(isDevMode: false);
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: mirror,
      fallback: fallback,
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );
    await repo.getPosts(spaceKey: 'prayer');

    await repo.toggleReaction(
      postId: 'post-relate',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );
    await repo.toggleReaction(
      postId: 'post-relate',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final stored = await repo.getPosts(spaceKey: 'prayer');
    final post = stored.singleWhere((item) => item.id == 'post-relate');
    final saved = (await fs.collection('reflections_dev').doc('post-relate').get()).data();

    expect(post.countForReaction('relatable'), 0);
    expect(post.hasMemberReacted('relatable', 'member-1'), isFalse);
    expect((saved!['reactions'] as Map)['relatable'], 0);
    // The spare mirror is attempted only when turning a reaction on.
    expect(mirror.increments, 1);

    await fs.collection('reflections_dev').doc('post-relate').delete();
    await repo.toggleReaction(
      postId: 'post-relate',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final rolled = fallback.findPost('post-relate');
    expect(rolled, isNotNull);
    expect(rolled!.countForReaction('relatable'), 0);
    expect(rolled.hasMemberReacted('relatable', 'member-1'), isFalse);
  });

  test('a failed toggle-off restores the member who had already related', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-off').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });
    final fallback = LocalPostRepository(isDevMode: false);
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: fallback,
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );
    await repo.getPosts(spaceKey: 'prayer');
    await repo.toggleReaction(
      postId: 'post-off',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );
    await fs.collection('reflections_dev').doc('post-off').delete();

    await repo.toggleReaction(
      postId: 'post-off',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final kept = fallback.findPost('post-off');
    expect(kept, isNotNull);
    expect(kept!.hasMemberReacted('relatable', 'member-1'), isTrue);
    expect(kept.countForReaction('relatable'), 1);
  });

  test('two taps on an uncached Firestore post do not increment twice', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections').doc('post-1').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'general_chat',
      'content': 'Hello',
      'createdAt': '2026-10-28T00:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'pray': 0},
      'prayingCount': 0,
    });
    final repo = AppwritePostRepository(
      isDevMode: false,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'prod', memory: {}),
    );

    await repo.addReaction(postId: 'post-1', reactionType: 'pray');
    await repo.addReaction(postId: 'post-1', reactionType: 'pray');

    final saved = (await fs.collection('reflections').doc('post-1').get()).data();
    expect((saved!['reactions'] as Map)['pray'], 0);
    expect(saved['prayingCount'], 1);
  });

  test('the next tap on another client removes a Relate instead of adding one', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-share').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });

    Future<AppwritePostRepository> open() async => AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: LocalPostRepository(isDevMode: false),
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );

    final first = await open();
    await first.getPosts(spaceKey: 'prayer');
    await first.toggleReaction(
      postId: 'post-share',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final second = await open();
    await second.getPosts(spaceKey: 'prayer');
    await second.toggleReaction(
      postId: 'post-share',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final saved = (await fs.collection('reflections_dev').doc('post-share').get()).data();
    expect((saved!['reactions'] as Map)['relatable'], 0);
  });

  test('toggle off leaves a zero cloud count at zero', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections_dev').doc('post-floor').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'A quiet note for the prayer room.',
      'createdAt': '2026-11-10T03:00:00.000Z',
      'toneTag': '[Support]',
      'reactions': {'relatable': 0},
    });
    final fallback = LocalPostRepository(isDevMode: false);
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: fs,
      mirror: _DownMirror(),
      fallback: fallback,
      outbox: PendingPostOutbox(environment: 'dev', memory: {}),
    );
    await repo.getPosts(spaceKey: 'prayer');
    await fallback.toggleReaction(
      postId: 'post-floor',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    await repo.toggleReaction(
      postId: 'post-floor',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );

    final saved = (await fs.collection('reflections_dev').doc('post-floor').get()).data();
    expect((saved!['reactions'] as Map)['relatable'], 0);

    await repo.toggleReaction(
      postId: 'post-floor',
      reactionType: 'relatable',
      userId: 'member-1',
      displayName: 'Jordan M.',
    );
    final raised = (await fs.collection('reflections_dev').doc('post-floor').get()).data();
    expect((raised!['reactions'] as Map)['relatable'], 1);
  });
}
