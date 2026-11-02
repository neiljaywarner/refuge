import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/circle_ban.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';
import 'package:refuge4serverpod/src/features/messages/domain/stored_direct_message.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/pending_post_outbox.dart';
import 'package:refuge4serverpod/src/features/reflections/data/saved_posts_store.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingMirror implements ReflectionMirror {
  @override
  Future<void> upsertPost(Post post) async => throw StateError('cloud down');

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

class _DenyOutbox extends PendingPostOutbox {
  _DenyOutbox() : super(memory: {});

  @override
  Future<bool> enqueue(Post post) async => false;
}

class _FlakyMailbox extends InMemoryDirectMessageMailbox {
  var fail = true;

  @override
  Future<int> deleteBySender({required String senderId, required String senderName}) async {
    if (fail) throw StateError('message erase denied');
    return super.deleteBySender(senderId: senderId, senderName: senderName);
  }
}

Post _note(
  String id, {
  String space = 'prayer',
  PostPublishStatus status = PostPublishStatus.confirmed,
}) => Post(
  id: id,
  authorName: 'Fellow Member',
  authorId: 'uid-fellow-member-00000001',
  spaceKey: space,
  toneTag: '[Support]',
  content: 'A quiet note $id',
  timestamp: DateTime.utc(2026, 10, 24, 12),
  reactions: const {},
  publishStatus: status,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('publishStatusFor reports confirmed, pending, and failed', () {
    expect(
      publishStatusFor(
        queued: true,
        firestoreWrite: CloudWrite.ok,
        appwriteWrite: CloudWrite.failed,
      ),
      PostPublishStatus.confirmed,
    );
    expect(
      publishStatusFor(
        queued: true,
        firestoreWrite: CloudWrite.failed,
        appwriteWrite: CloudWrite.skipped,
      ),
      PostPublishStatus.pending,
    );
    expect(
      publishStatusFor(
        queued: false,
        firestoreWrite: CloudWrite.failed,
        appwriteWrite: CloudWrite.failed,
      ),
      PostPublishStatus.failed,
    );
    expect(
      publishStatusFor(
        queued: true,
        firestoreWrite: CloudWrite.skipped,
        appwriteWrite: CloudWrite.skipped,
      ),
      PostPublishStatus.confirmed,
    );
  });

  test('a failed cloud write keeps a durable pending copy across a restart', () async {
    final memory = <String, String>{};
    final outbox = PendingPostOutbox(environment: 'prod', memory: memory);
    final repo = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      mirror: _FailingMirror(),
      outbox: outbox,
    );

    final published = await repo.createPost(_note('post-pending'));

    expect(published.publishStatus, PostPublishStatus.pending);
    expect(
      (await repo.getPosts(spaceKey: 'prayer')).map((post) => post.id),
      contains('post-pending'),
    );

    final restarted = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      mirror: _FailingMirror(),
      outbox: PendingPostOutbox(environment: 'prod', memory: memory),
    );
    final afterRestart = await restarted.getPosts(spaceKey: 'prayer');
    expect(afterRestart.map((post) => post.id), contains('post-pending'));
    expect(
      afterRestart.singleWhere((post) => post.id == 'post-pending').publishStatus,
      PostPublishStatus.pending,
    );
  });

  test('a post is not shown as published when nothing durable was stored', () async {
    final repo = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      mirror: _FailingMirror(),
      outbox: _DenyOutbox(),
    );

    final published = await repo.createPost(_note('post-lost'));

    expect(published.publishStatus, PostPublishStatus.failed);
    expect(
      (await repo.getPosts(spaceKey: 'prayer')).map((post) => post.id),
      isNot(contains('post-lost')),
    );
  });

  test('a Firestore snapshot removes reflections that disappeared', () async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('reflections').doc('keep').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'Stay',
      'createdAt': '2026-10-24T12:00:00.000Z',
      'toneTag': '[Support]',
    });
    await fs.collection('reflections').doc('drop').set({
      'authorName': 'Fellow Member',
      'spaceKey': 'prayer',
      'content': 'Go',
      'createdAt': '2026-10-24T12:00:00.000Z',
      'toneTag': '[Support]',
    });
    final repo = AppwritePostRepository(
      isDevMode: false,
      fallback: LocalPostRepository(isDevMode: false),
      customFirestore: fs,
      mirror: _FailingMirror(),
      outbox: PendingPostOutbox(environment: 'prod', memory: {}),
    );

    expect(
      (await repo.getPosts(spaceKey: 'prayer')).map((post) => post.id),
      containsAll(['keep', 'drop']),
    );

    await fs.collection('reflections').doc('drop').delete();
    final second = await repo.getPosts(spaceKey: 'prayer');
    expect(second.map((post) => post.id), contains('keep'));
    expect(second.map((post) => post.id), isNot(contains('drop')));
  });

  test('an authoritative snapshot keeps pending and demo reflections', () async {
    final repo = LocalPostRepository(
      isDevMode: false,
      initialPosts: [
        _note('cloud-row'),
        _note('pending-local', status: PostPublishStatus.pending),
        _note('demo-row').copyWith(isDemo: true),
        _note('ghost-row'),
      ],
    );

    repo.retainAuthoritativeSpace(
      spaceKey: 'prayer',
      cloudIds: {'cloud-row'},
      pendingIds: const {},
    );

    final ids = (await repo.getPosts(spaceKey: 'prayer')).map((post) => post.id);
    expect(ids, containsAll(['cloud-row', 'pending-local', 'demo-row']));
    expect(ids, isNot(contains('ghost-row')));
  });

  test('bookmarks stay inside the account and environment that saved them', () async {
    final firstStore = SavedPostsStore(environment: 'dev');
    firstStore.adoptAccount('uid-account-a');
    final first = LocalPostRepository(isDevMode: true, savedPostsStore: firstStore);
    await first.adoptAccount('uid-account-a');
    await first.toggleSavePost(postId: '1');

    final otherStore = SavedPostsStore(environment: 'dev');
    otherStore.adoptAccount('uid-account-b');
    final other = LocalPostRepository(isDevMode: true, savedPostsStore: otherStore);
    await other.adoptAccount('uid-account-b');
    expect(await other.getSavedPosts(), isEmpty);

    await first.adoptAccount('uid-account-b');
    expect(await first.getSavedPosts(), isEmpty);
    await first.adoptAccount('uid-account-a');
    expect((await first.getSavedPosts()).map((post) => post.id), contains('1'));

    final prodStore = SavedPostsStore(environment: 'prod');
    prodStore.adoptAccount('uid-account-a');
    final prod = LocalPostRepository(isDevMode: false, savedPostsStore: prodStore);
    await prod.adoptAccount('uid-account-a');
    expect(await prod.getSavedPosts(), isEmpty);
  });

  test('ban erase is retryable after a message delete failure', () async {
    final bans = InMemoryAdminBanningRepository();
    addTearDown(bans.dispose);
    final posts = LocalPostRepository(isDevMode: false);
    final mailbox = _FlakyMailbox();
    await posts.createPost(_note('post-ban'));
    mailbox.cacheMessage(
      StoredDirectMessage(
        id: 'message-1',
        threadId: 'thread-1',
        senderId: 'caleb-123',
        senderName: 'Caleb Stone',
        recipientIds: const ['elena-1'],
        recipientNames: const ['Elena R.'],
        participantIds: const ['caleb-123', 'elena-1'],
        content: 'Hello',
        sentAt: DateTime.utc(2026, 10, 24),
      ),
    );

    await expectLater(
      applyCircleBan(
        bans: bans,
        posts: posts,
        comments: LocalCommentRepository(isDevMode: false),
        mailbox: mailbox,
        userId: 'caleb-123',
        displayName: 'Caleb Stone',
        bannedByAdminEmail: 'organizer@belongonthespectrum.com',
      ),
      throwsA(isA<CircleBanEraseException>()),
    );
    expect(await bans.isUserBanned('caleb-123'), isTrue);
    expect((await bans.watchBannedUsers().first).any((row) => row.erasePending), isTrue);
    expect(await mailbox.loadThreads('elena-1'), isNotEmpty);

    mailbox.fail = false;
    await retryCircleBanErase(
      bans: bans,
      posts: posts,
      comments: LocalCommentRepository(isDevMode: false),
      mailbox: mailbox,
      userId: 'caleb-123',
      displayName: 'Caleb Stone',
    );
    expect(await mailbox.loadThreads('elena-1'), isEmpty);
    expect((await bans.watchBannedUsers().first).every((row) => !row.erasePending), isTrue);
  });

  test('sending a message records an id-only index used by erase', () async {
    final fs = FakeFirebaseFirestore();
    final mailbox = FirestoreDirectMessageMailbox(firestore: fs);
    final result = await mailbox.sendMessage(
      senderId: 'uid-sender-000000000001',
      senderName: 'Fellow Member',
      recipients: const [
        MessageRecipient(
          id: 'uid-recipient-00000000001',
          name: 'Sarah K.',
          tagline: 'Quiet fellowship',
        ),
      ],
      content: 'A private note',
    );
    expect(result.message.content, 'A private note');
    final index = await fs
        .collection('users')
        .doc('uid-sender-000000000001')
        .collection('sent_message_ids')
        .get();
    expect(index.docs, hasLength(1));
    expect(index.docs.single.data().containsKey('content'), isFalse);

    final removed = await mailbox.deleteBySender(
      senderId: 'uid-sender-000000000001',
      senderName: 'Fellow Member',
    );
    expect(removed, greaterThan(0));
    final left = await fs.collection('direct_messages').get();
    expect(left.docs, isEmpty);
  });

  testWidgets('the composer keeps the draft when publish fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReflectionComposer(
            selectedSpace: 'prayer',
            primaryColor: Colors.teal,
            isContrast: false,
            isModal: true,
            onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async =>
                PostPublishStatus.failed,
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('reflection_composer_input')), 'Please keep this');
    await tester.tap(find.byKey(const Key('publish_reflection_button')));
    await tester.pump();

    expect(find.text('Please keep this'), findsOneWidget);
    expect(find.byKey(const Key('reflection_publish_failed_snackbar')), findsOneWidget);
  });
}
