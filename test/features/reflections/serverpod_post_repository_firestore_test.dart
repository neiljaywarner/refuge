import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/serverpod_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firestore half of the Serverpod repository.
///
/// The Serverpod client points at a closed local port so a publish or digest
/// call fails immediately and the test uses the local fallback. Nothing is
/// sent to a live host.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ServerpodPostRepository build({
    required FakeFirebaseFirestore firestore,
    required LocalPostRepository fallback,
    bool isDevMode = true,
  }) => ServerpodPostRepository(
    serverUrl: 'http://127.0.0.1:9',
    fallback: fallback,
    customFirestore: firestore,
    isDevMode: isDevMode,
    client: null,
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

    final prod = build(
      firestore: firestore,
      fallback: LocalPostRepository(initialPosts: []),
      isDevMode: false,
    );
    expect(prod.collectionName, 'reflections');
    expect(await prod.getPosts(spaceKey: 'prayer'), isEmpty);
  });

  test('a local row wins, and a failed publish is kept on the device', () async {
    final firestore = FakeFirebaseFirestore();
    final local = LocalPostRepository(initialPosts: [sample()]);
    final repo = build(firestore: firestore, fallback: local);

    final cached = await repo.getPosts(spaceKey: 'prayer');
    expect(cached.single.id, 'post-1');

    final created = await repo.createPost(sample(id: 'post-2'));
    expect(created.id, 'post-2');
    expect(repo.isLiveConnected, isFalse);
    final stored = await firestore.collection('reflections_dev').doc('post-2').get();
    expect(stored.data()?['content'], 'A quiet thought.');
    expect(stored.data()?['spaceKey'], 'prayer');

    final digest = await repo.getQuietDigest(spaceKey: ' prayer ');
    expect(repo.isLiveConnected, isFalse);
    expect(digest, isA<String?>());
  });

  test('a non-numeric id updates Firestore and then the local reaction', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('reflections_dev').doc('post-1').set({
      'prayCount': 0,
      'authorName': 'David M.',
      'authorId': 'member-1',
    });
    final repo = build(
      firestore: firestore,
      fallback: LocalPostRepository(initialPosts: [sample()]),
    );

    await repo.addReaction(postId: 'post-1', reactionType: 'pray');
    final doc = await firestore.collection('reflections_dev').doc('post-1').get();
    expect(doc.data()?['prayCount'], 1);
    expect(repo.isLiveConnected, isFalse);

    final removed = await repo.deleteByAuthor(authorName: 'David M.', authorId: 'member-1');
    expect(removed, greaterThanOrEqualTo(0));
    expect((await firestore.collection('reflections_dev').doc('post-1').get()).exists, isFalse);
  });
}
