import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

Post _post({
  String id = 'post-1',
  DateTime? timestamp,
  Map<String, int> reactions = const {'pray': 1},
  bool isSaved = false,
  String content = 'Quiet hello.',
}) => Post(
  id: id,
  authorName: 'Fellow Member',
  spaceKey: ' Prayer ',
  toneTag: '',
  specialInterestTag: 'trains',
  imageUrl: 'https://example.com/calm.png',
  content: content,
  timestamp: timestamp ?? DateTime.utc(2026, 10, 1),
  reactions: reactions,
  isDemo: true,
  isSaved: isSaved,
);

void main() {
  group('Appwrite row id and space key', () {
    test('rewrites empty, unsafe, and overlong ids', () {
      expect(appwriteRowId('post-100'), 'post-100');
      expect(appwriteRowId('-abc'), 'r-abc');
      expect(appwriteRowId('[#]'), 'row');
      expect(appwriteRowId(''), 'row');
      final long = appwriteRowId('a' * 40);
      expect(long.length, 36);
      expect(long, 'a' * 36);
    });

    test('canonical space keys trim and fall back when blank', () {
      expect(canonicalSpaceKey(' Prayer '), 'prayer');
      expect(canonicalSpaceKey('   '), 'general_chat');
    });

    test('reaction columns map known care types and drop the rest', () {
      expect(reactionColumn('pray'), 'prayingCount');
      expect(reactionColumn('standing'), 'standingWithCount');
      expect(reactionColumn('peace'), 'peaceCount');
      expect(reactionColumn('encouraged'), 'encouragedCount');
      expect(reactionColumn('relatable'), 'encouragedCount');
      expect(reactionColumn('unknown'), isNull);
    });
  });

  group('reflection row payloads', () {
    test('row data fills defaults and keeps optional media', () {
      final data = reflectionRowData(_post());

      expect(data['spaceKey'], 'prayer');
      expect(data['intentTag'], '[Support]');
      expect(data['specialInterestTag'], 'trains');
      expect(data['imageUrl'], 'https://example.com/calm.png');
      expect(data['prayingCount'], 1);
      expect(data['encouragedCount'], 0);
      expect(data['isDemo'], isTrue);
      expect(data['createdAt'], '2026-10-01T00:00:00.000Z');
    });

    test('encouraged count prefers the encouraged reaction over relatable', () {
      final data = reflectionRowData(_post(reactions: const {'relatable': 3, 'encouraged': 4}));
      expect(data['encouragedCount'], 4);
    });

    test('firestore payload adds the author and the raw reaction map', () {
      final data = firestoreReflectionData(_post(), authorId: 'uid-1');
      expect(data['authorId'], 'uid-1');
      expect(data['toneTag'], '');
      expect(data['reactions'], {'pray': 1});
      expect(firestoreReflectionData(_post(), authorId: '').containsKey('authorId'), isFalse);
    });

    test('firestore reaction increment bumps the column and the map', () {
      final payload = firestoreReactionIncrement('peace', 'peaceCount');
      expect(payload['peaceCount'], isA<FieldValue>());
      expect(payload['reactions'], isA<Map<String, dynamic>>());
      expect((payload['reactions'] as Map)['peace'], isA<FieldValue>());
    });
  });

  group('reading rows back', () {
    test('postFromFirestore prefers the reactions map, then count columns', () {
      final post = postFromFirestore('row-1', {
        'authorName': 'Sarah K.',
        'reactions': {'pray': 2},
        'prayingCount': 9,
        'peaceCount': 3,
        'intentTag': '[Comfort]',
        'createdAt': '2026-10-02T00:00:00.000Z',
        'isDemo': true,
      }, 'study');

      expect(post.authorName, 'Sarah K.');
      expect(post.reactions['pray'], 2);
      expect(post.reactions['peace'], 3);
      expect(post.toneTag, '[Comfort]');
      expect(post.spaceKey, 'study');
      expect(post.isDemo, isTrue);
    });

    test('postFromFirestore falls back when names and dates are missing', () {
      final before = DateTime.now().toUtc();
      final post = postFromFirestore('row-2', {'content': 'Hello'}, '  ');
      expect(post.authorName, 'Fellowship Member');
      expect(post.spaceKey, 'general_chat');
      expect(post.toneTag, '[Support]');
      expect(post.content, 'Hello');
      expect(post.timestamp.isBefore(before.subtract(const Duration(days: 1))), isFalse);
    });

    test('Appwrite payloads accept nested data and reject empty rows', () {
      final post = postFromAppwritePayload({
        r'$id': 'post-9',
        'data': {
          'authorName': 'David M.',
          'spaceKey': 'memes',
          'content': 'A calm meme note.',
          'encouragedCount': 5,
          'createdAt': '2026-10-03T00:00:00.000Z',
        },
      });

      expect(post, isNotNull);
      expect(post!.id, 'post-9');
      expect(post.authorName, 'David M.');
      expect(post.spaceKey, 'memes');
      expect(post.reactions['encouraged'], 5);
      expect(post.reactions['relatable'], 5);
      expect(postFromAppwritePayload({r'$id': 'x'}), isNull);
      expect(postFromAppwritePayload({'content': 'no id'}), isNull);
      expect(postFromAppwritePayload({r'$id': '', 'content': 'blank id'}), isNull);
    });
  });

  group('mergePosts and preferPost', () {
    test('a newer incoming copy wins and keeps a local bookmark', () {
      final current = _post(isSaved: true, timestamp: DateTime.utc(2026, 10, 1));
      final incoming = _post(
        isSaved: false,
        timestamp: DateTime.utc(2026, 10, 2),
        content: 'Newer',
      );

      final winner = preferPost(current, incoming);
      expect(winner.content, 'Newer');
      expect(winner.isSaved, isTrue);
    });

    test('an older incoming copy does not replace a newer saved local copy', () {
      final current = _post(isSaved: false, timestamp: DateTime.utc(2026, 10, 3), content: 'Local');
      final incoming = _post(isSaved: true, timestamp: DateTime.utc(2026, 10, 1));

      final winner = preferPost(current, incoming);
      expect(winner.content, 'Local');
      expect(winner.isSaved, isTrue);
    });

    test('equal timestamps keep the copy with more care, and bookmarks', () {
      final same = DateTime.utc(2026, 10, 4);
      final current = _post(reactions: const {'pray': 1}, timestamp: same);
      final incoming = _post(
        reactions: const {'pray': 1, 'peace': 4},
        timestamp: same,
        content: 'More care',
        isSaved: true,
      );

      final winner = preferPost(current, incoming);
      expect(winner.content, 'More care');
      expect(winner.isSaved, isTrue);

      final currentWins = preferPost(
        _post(reactions: const {'pray': 9}, timestamp: same, content: 'Local care'),
        _post(reactions: const {'pray': 1}, timestamp: same, content: 'Cloud'),
      );
      expect(currentWins.content, 'Local care');
    });

    test('mergePosts overlays by id and sorts newest first', () {
      final older = _post(id: 'a', timestamp: DateTime.utc(2026, 10, 1), content: 'Old');
      final newer = _post(id: 'b', timestamp: DateTime.utc(2026, 10, 5), content: 'New');
      final updated = _post(
        id: 'a',
        timestamp: DateTime.utc(2026, 10, 6),
        content: 'Updated',
        isSaved: true,
      );

      final merged = mergePosts([older, newer], [updated]);
      expect(merged.map((post) => post.id), ['a', 'b']);
      expect(merged.first.content, 'Updated');
      expect(merged.first.isSaved, isTrue);
    });
  });
}
