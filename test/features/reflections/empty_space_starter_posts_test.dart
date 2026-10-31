import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/data/canonical_organizer_starter_posts.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';

void main() {
  test('prod local repo injects organizer starters when space is empty', () async {
    final repo = LocalPostRepository(isDevMode: false);
    final startHere = await repo.getPosts(spaceKey: 'start_here');
    expect(startHere.length, 1);
    expect(startHere.single.id, 'canonical-organizer-welcome');
    expect(startHere.single.isDemo, isFalse);

    final memes = await repo.getPosts(spaceKey: 'memes');
    expect(memes.single.id, 'canonical-memes-church-acoustics');

    final emptySpace = await repo.getPosts(spaceKey: 'events');
    expect(emptySpace, isEmpty);
  });

  test('dev mode does not inject organizer starters', () async {
    final repo = LocalPostRepository(isDevMode: true);
    final events = await repo.getPosts(spaceKey: 'events');
    expect(events, isEmpty);
  });

  test('canonical list has five non-demo posts across five spaces', () {
    expect(kCanonicalOrganizerReflections.length, 5);
    expect(kCanonicalOrganizerReflections.every((p) => !p.isDemo), isTrue);
    final spaces = kCanonicalOrganizerReflections.map((p) => p.spaceKey).toSet();
    expect(spaces, {'start_here', 'general_chat', 'study', 'prayer', 'memes'});
  });

  test('organizerStarterPostsForSpace normalizes keys', () {
    final posts = organizerStarterPostsForSpace('  START_HERE  ');
    expect(posts.length, 1);
    expect(posts.single.spaceKey, 'start_here');
  });
}
