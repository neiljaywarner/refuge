import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_merge.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reaction_member.dart';

void main() {
  final when = DateTime.utc(2026, 11, 2, 12);
  final known = ReactionMember(userId: 'member-1', displayName: 'David M.', timestamp: when);

  Post post({
    DateTime? timestamp,
    Map<String, int>? reactions,
    Map<String, List<ReactionMember>>? members,
    bool isSaved = false,
  }) => Post(
    id: 'post-1',
    authorName: 'Sarah K.',
    spaceKey: 'prayer',
    toneTag: '[Prayer Request]',
    content: 'A quiet thought.',
    timestamp: timestamp ?? when,
    reactions: reactions ?? const {'pray': 1},
    reactionMembers: members ?? const {},
    isSaved: isSaved,
  );

  test('a cloud count keeps the local name when the incoming list is empty', () {
    final merged = retainKnownReactors(
      counts: const {'pray': 1, 'peace': 0},
      incoming: const {},
      known: {
        'pray': [known],
        'peace': [known],
        'relatable': const [],
      },
    );

    expect(merged['pray']!.single.displayName, 'David M.');
    expect(merged.containsKey('peace'), isFalse);
    expect(retainKnownReactors(counts: const {}, incoming: const {'pray': []}, known: const {}), {
      'pray': <ReactionMember>[],
    });
  });

  test('an incoming name wins, and a saved flag survives an older copy', () {
    final incomingMember = ReactionMember(
      userId: 'member-2',
      displayName: 'Sarah K.',
      timestamp: when,
    );
    final kept = retainKnownReactors(
      counts: const {'pray': 1},
      incoming: {
        'pray': [incomingMember],
      },
      known: {
        'pray': [known],
      },
    );
    expect(kept['pray']!.single.userId, 'member-2');

    final newer = preferPost(
      post(
        isSaved: true,
        members: {
          'pray': [known],
        },
      ),
      post(timestamp: when.add(const Duration(minutes: 1))),
    );
    expect(newer.isSaved, isTrue);
    expect(newer.reactionMembers['pray']!.single.displayName, 'David M.');
  });

  test('json round-trips a member and copyWith can drop nothing required', () {
    final restored = ReactionMember.fromJson(known.toJson());
    expect(restored, known);
    expect(restored.timestamp.isUtc, isTrue);

    final renamed = known.copyWith(displayName: 'Fellow Member');
    expect(renamed.displayName, 'Fellow Member');
    expect(renamed.userId, known.userId);
    expect(known.copyWith().timestamp, known.timestamp);
  });
}
