import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/bema_weekly/bema_this_week_card.dart';
import 'package:refuge4serverpod/src/features/bema_weekly/bema_weekly_study.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

void main() {
  test('episode 183 keeps the links published on the episode page', () {
    const study = bemaEpisode183;
    expect(currentBemaWeeklyStudy.episodeNumber, 183);
    expect(study.title, 'Revelation — Seals from Scripture');
    expect(study.subtitle, 'The Return of the Horses');
    expect(study.listenUrl, 'https://www.bemadiscipleship.com/183');
    expect(study.showNotesUrl, 'https://www.bemadiscipleship.com/183');
    expect(
      study.transcriptUrl,
      'https://docs.google.com/document/d/e/2PACX-1vSGLBFW5q1hmjuBRFR2D4SkPi5tTyHoHMaHJR9AoTyFgm_FRIIxrtvfLuXTgNFnhH2c_l92fVSYXR4o/pub',
    );
    expect(study.discussionVideoUrl, 'https://www.youtube.com/watch?v=q4RSOhwDV4M');
    expect(
      study.applePodcastsUrl,
      'https://podcasts.apple.com/us/podcast/the-bema-podcast/id1148115183',
    );
    expect(study.presentationUrl, isNull);
    expect(study.callRoom, 'bema-weekly');
    expect(study.questions, hasLength(5));
    expect(study.questions.first, contains('What sticks out to me?'));

    final post = weeklyDiscussionPost(study);
    expect(post.id, 'bema-week-183');
    expect(post.isDemo, isFalse);
    expect(post.spaceKey, 'study');
    expect(post.content, contains('Show notes: ${study.showNotesUrl}'));
    expect(post.content, contains('Transcript: ${study.transcriptUrl}'));
    expect(post.content, contains('Apple Podcasts: ${study.applePodcastsUrl}'));
    expect(weeklyStudyForPostId(post.id), same(study));
    expect(weeklyStudyForPostId('post-1'), isNull);
  });

  test('the weekly discussion post is seeded once and survives a cloud snapshot', () async {
    final repo = LocalPostRepository(isDevMode: false);
    final first = await repo.getPosts(spaceKey: 'study');
    final second = await repo.getPosts(spaceKey: 'study');
    expect(first.where((post) => post.id == 'bema-week-183'), hasLength(1));
    expect(second.where((post) => post.id == 'bema-week-183'), hasLength(1));

    repo.retainAuthoritativeSpace(spaceKey: 'study', cloudIds: const {}, pendingIds: const {});
    expect(repo.findPost('bema-week-183'), isNotNull);
    final kept = await repo.getPosts(spaceKey: 'study');
    expect(kept.map((post) => post.id), contains('bema-week-183'));
  });

  testWidgets('the call card and the week post both open transcript and show notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              BemaThisWeekCard(
                study: bemaEpisode183,
                primaryColor: const Color(0xFF2E6B56),
                isContrast: false,
                onJoinCall: () {},
                onOpenDiscussion: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('bema_card_show_notes')), findsOneWidget);
    expect(find.byKey(const Key('bema_card_transcript')), findsOneWidget);
    expect(find.byKey(const Key('bema_card_apple_podcasts')), findsOneWidget);
    expect(find.text('Join the weekly call'), findsOneWidget);
    expect(find.text('Show notes'), findsOneWidget);
    expect(find.text('Transcript'), findsOneWidget);

    final post = weeklyDiscussionPost(bemaEpisode183);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {})],
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('bema_post_bema-week-183_show_notes')), findsOneWidget);
    expect(find.byKey(const Key('bema_post_bema-week-183_transcript')), findsOneWidget);
    expect(find.byKey(const Key('bema_post_bema-week-183_apple_podcasts')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bema_post_bema-week-183_transcript')));
    await tester.pump();

    final other = Post(
      id: 'post-ordinary',
      authorName: 'Fellow Member',
      spaceKey: 'prayer',
      toneTag: '[Support]',
      content: 'A quiet hello.',
      timestamp: DateTime.utc(2026, 11, 22),
      reactions: const {},
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [ReflectionCard(post: other, isContrast: false, onAddReaction: (_) {})],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Transcript'), findsNothing);
    expect(find.text('Show notes'), findsNothing);
  });
}
