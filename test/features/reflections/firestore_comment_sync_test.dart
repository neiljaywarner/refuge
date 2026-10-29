// Cross-member comment sync and care reactions through Firestore (#662).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

Comment _comment(String id, {String postId = 'p1', String author = 'Ana', String? parent}) =>
    Comment(
      id: id,
      postId: postId,
      parentCommentId: parent,
      authorName: author,
      content: 'Hello from $author',
      toneTag: '[Support]',
      timestamp: DateTime.utc(2026, 10, 28, 12, id.length),
    );

/// Mirror that does nothing, so the test never builds a real Appwrite client.
class _NoopMirror implements ReflectionMirror {
  @override
  Future<void> upsertPost(Post post) async {}

  @override
  Future<void> incrementReaction({required String postId, required String column}) async {}

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async => const [];

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async {}
}

void main() {
  group('LocalCommentRepository Firestore sync (#662)', () {
    late FakeFirebaseFirestore fs;

    setUp(() => fs = FakeFirebaseFirestore());

    test('prod writes go to comments with authorId; dev writes go to comments_dev', () async {
      final prod = LocalCommentRepository(
        isDevMode: false,
        customFirestore: fs,
        currentUid: () => 'uid-ana',
      );
      final dev = LocalCommentRepository(
        initialComments: const [],
        isDevMode: true,
        customFirestore: fs,
        currentUid: () => 'uid-ana',
      );

      await prod.addComment(_comment('c-prod'));
      await dev.addComment(_comment('c-dev'));

      final prodDoc = await fs.collection('comments').doc('c-prod').get();
      expect(prodDoc.data()?['authorId'], 'uid-ana');
      expect(prodDoc.data()?['postId'], 'p1');
      expect((await fs.collection('comments').doc('c-dev').get()).exists, isFalse);
      expect((await fs.collection('comments_dev').doc('c-dev').get()).exists, isTrue);
    });

    test('getComments loads another member\'s comment written on a different device', () async {
      final ana = LocalCommentRepository(
        isDevMode: false,
        customFirestore: fs,
        currentUid: () => 'uid-ana',
      );
      await ana.addComment(_comment('c1'));
      await ana.addComment(_comment('c1-reply', parent: 'c1'));

      // Ben's device: fresh in-memory store (as after an app refresh).
      final ben = LocalCommentRepository(
        isDevMode: false,
        customFirestore: fs,
        currentUid: () => 'uid-ben',
      );
      final thread = await ben.getComments(postId: 'p1');

      expect(thread.map((c) => c.id), ['c1', 'c1-reply']);
      expect(thread.last.parentCommentId, 'c1');

      // A second load merges by id and does not duplicate.
      final again = await ben.getComments(postId: 'p1');
      expect(again, hasLength(2));
      expect(await ben.getCommentCount(postId: 'p1'), 2);
    });

    test('watchComments emits remote comments as they arrive', () async {
      final ben = LocalCommentRepository(isDevMode: false, customFirestore: fs);
      final emissions = <List<String>>[];
      final sub = ben
          .watchComments(postId: 'p1')
          .listen((list) => emissions.add(list.map((c) => c.id).toList()));

      await fs
          .collection('comments')
          .doc('remote-1')
          .set(firestoreCommentData(_comment('remote-1', author: 'Cara'), authorId: 'uid-cara'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.first, isEmpty);
      expect(emissions.last, ['remote-1']);
      await sub.cancel();
    });

    test('a care reaction from another member reaches the shared document', () async {
      final ana = LocalCommentRepository(isDevMode: false, customFirestore: fs);
      await ana.addComment(_comment('c1'));

      final ben = LocalCommentRepository(isDevMode: false, customFirestore: fs);
      await ben.getComments(postId: 'p1');
      await ben.addReaction(commentId: 'c1', reactionType: 'pray');

      final doc = await fs.collection('comments').doc('c1').get();
      expect((doc.data()?['reactions'] as Map)['pray'], 1);

      // Ana sees Ben's reaction after a reload.
      final reloaded = await ana.getComments(postId: 'p1');
      expect(reloaded.single.reactions['pray'], 1);
    });

    test('works without Firebase (widget tests) and returns the local thread', () async {
      final repo = LocalCommentRepository(initialComments: [_comment('local')], isDevMode: false);
      expect(repo.firestore, isNull);
      expect((await repo.getComments(postId: 'p1')).single.id, 'local');
      expect(await repo.watchComments(postId: 'p1').first, hasLength(1));
    });
  });

  group('commentFromFirestore', () {
    test('parses ISO strings, Timestamps, and reaction maps', () {
      final fromIso = commentFromFirestore('a', {
        'postId': 'p1',
        'content': 'hi',
        'authorName': 'Ana',
        'timestamp': '2026-10-28T12:00:00.000Z',
        'reactions': {'pray': 2, 'peace': 1.0},
      });
      expect(fromIso?.timestamp, DateTime.utc(2026, 10, 28, 12));
      expect(fromIso?.reactions, {'pray': 2, 'peace': 1});

      final fromTs = commentFromFirestore('b', {
        'postId': 'p1',
        'content': 'hi',
        'timestamp': Timestamp.fromDate(DateTime.utc(2026, 1, 2)),
        'parentCommentId': '',
      });
      expect(fromTs?.timestamp.toUtc(), DateTime.utc(2026, 1, 2));
      expect(fromTs?.parentCommentId, isNull);
      expect(fromTs?.authorName, 'Fellowship Member');
    });

    test('drops documents without postId or content', () {
      expect(commentFromFirestore('x', {'content': 'hi'}), isNull);
      expect(commentFromFirestore('y', {'postId': 'p1'}), isNull);
    });
  });

  group('AppwritePostRepository Firestore payloads (#662)', () {
    final post = Post(
      id: 'post-1',
      authorName: 'Ana',
      spaceKey: 'general_chat',
      toneTag: '[Support]',
      content: 'Hello',
      timestamp: DateTime.utc(2026, 10, 28),
      reactions: const {},
    );

    test('firestoreReflectionData stamps authorId only when known', () {
      expect(firestoreReflectionData(post, authorId: 'uid-ana')['authorId'], 'uid-ana');
      expect(firestoreReflectionData(post).containsKey('authorId'), isFalse);
      expect(firestoreReflectionData(post, authorId: '').containsKey('authorId'), isFalse);
    });

    test('a reaction bumps both the column and the reactions map', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('reflections').doc('post-1').set(firestoreReflectionData(post));
      final repo = AppwritePostRepository(
        fallback: LocalPostRepository(isDevMode: false),
        customFirestore: fs,
        mirror: _NoopMirror(),
        isDevMode: false,
      );

      await repo.addReaction(postId: 'post-1', reactionType: 'pray');
      await repo.addReaction(postId: 'post-1', reactionType: 'pray');

      final data = (await fs.collection('reflections').doc('post-1').get()).data()!;
      expect(data['prayingCount'], 2);
      expect((data['reactions'] as Map)['pray'], 2);
      expect(postFromFirestore('post-1', data, 'general_chat').reactions['pray'], 2);
    });
  });
}
