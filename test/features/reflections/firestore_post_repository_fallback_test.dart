import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firestore half of the reflection repository.
///
/// The spare mirror throws, the way a closed local port used to. Publish and
/// the quiet digest still keep the on-device copy. Nothing is sent to a live host.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppwritePostRepository build({
    required FakeFirebaseFirestore firestore,
    required LocalPostRepository fallback,
    bool isDevMode = true,
    ReflectionMirror? mirror,
  }) => AppwritePostRepository(
    fallback: fallback,
    customFirestore: firestore,
    isDevMode: isDevMode,
    mirror: mirror,
  );

  Post sample({String id = 'post-1', String authorId = 'member-1'}) => Post(
    id: id,
    authorName: 'David M.',
    authorId: authorId,
    spaceKey: 'prayer',
    toneTag: '[Prayer Request]',
    content: 'A quiet thought.',
    timestamp: DateTime.utc(2026, 11, 1, 12),
    reactions: const {'pray': 1, 'peace': 0},
    publishStatus: PostPublishStatus.pending,
  );

  test('an empty device reads the dev Firestore collection', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('reflections_dev').doc('cloud-1').set({
      'authorName': 'Sarah K.',
      'spaceKey': 'prayer',
      'intentTag': '[Comfort Only]',
      'specialInterestTag': 'maps',
      'content': 'A cloud row.',
      'createdAt': '2026-11-01T12:00:00.000Z',
      'prayingCount': 2,
      'peaceCount': 1,
    });
    final repo = build(
      firestore: firestore,
      fallback: LocalPostRepository(initialPosts: []),
    );

    expect(repo.collectionName, 'reflections_dev');
    expect(repo.isLiveConnected, isFalse);
    final posts = await repo.getPosts(spaceKey: 'prayer');
    expect(posts.single.authorName, 'Sarah K.');
    expect(posts.single.toneTag, '[Comfort Only]');
    expect(posts.single.specialInterestTag, 'maps');
    expect(posts.single.reactions['pray'], 2);
    expect(posts.single.reactions['peace'], 1);
    expect(repo.isLiveConnected, isTrue);

    final prod = build(
      firestore: firestore,
      fallback: LocalPostRepository(initialPosts: []),
      isDevMode: false,
    );
    expect(prod.collectionName, 'reflections');
    expect(await prod.getPosts(spaceKey: 'prayer'), isEmpty);
  });

  test('a pending local row stays, and a new post is stored in Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final local = LocalPostRepository(initialPosts: [sample()]);
    final mirror = _ClosedMirror();
    final repo = build(firestore: firestore, fallback: local, mirror: mirror);

    final cached = await repo.getPosts(spaceKey: 'prayer');
    expect(cached.map((post) => post.id), contains('post-1'));

    final created = await repo.createPost(sample(id: 'post-2'));
    expect(created.id, 'post-2');
    expect(mirror.failures, greaterThan(0));
    final stored = await firestore.collection('reflections_dev').doc('post-2').get();
    expect(stored.data()?['content'], 'A quiet thought.');
    expect(stored.data()?['spaceKey'], 'prayer');

    final digest = await repo.getQuietDigest(spaceKey: 'prayer');
    expect(digest, contains('Gathered in peace'));
    expect(await repo.getQuietDigest(spaceKey: ' prayer '), isNotNull);
  });

  test('a non-numeric id updates Firestore and then deletes that row', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('reflections_dev').doc('post-1').set({
      'prayingCount': 0,
      'authorName': 'David M.',
      'authorId': 'member-1',
      'spaceKey': 'prayer',
    });
    final repo = build(
      firestore: firestore,
      fallback: LocalPostRepository(initialPosts: [sample()]),
    );

    await repo.addReaction(postId: 'post-1', reactionType: 'pray');
    final doc = await firestore.collection('reflections_dev').doc('post-1').get();
    expect(doc.data()?['prayingCount'], 1);
    expect(repo.isLiveConnected, isTrue);

    final removed = await repo.deleteByAuthor(authorName: 'David M.', authorId: 'member-1');
    expect(removed, greaterThanOrEqualTo(0));
    expect((await firestore.collection('reflections_dev').doc('post-1').get()).exists, isFalse);
  });
}

class _ClosedMirror implements ReflectionMirror {
  int failures = 0;

  Future<void> _fail() async {
    failures++;
    throw StateError('closed');
  }

  @override
  Future<void> upsertPost(Post post) => _fail();

  @override
  Future<void> incrementReaction({required String postId, required String column}) => _fail();

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async {
    await _fail();
    return const [];
  }

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) => _fail();
}
