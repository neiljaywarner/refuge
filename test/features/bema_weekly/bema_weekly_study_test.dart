import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/bema_weekly/bema_this_week_card.dart';
import 'package:refuge4serverpod/src/features/bema_weekly/bema_weekly_study.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

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
    expect(study.gatheringLabel, 'Sundays, 7:30 PM CT');
    expect(study.callRoom, 'bema-weekly');
    expect(study.questions, hasLength(5));
    expect(study.questions.first, contains('What sticks out to me?'));

    final post = weeklyDiscussionPost(study);
    expect(post.id, 'bema-week-183');
    expect(post.isDemo, isFalse);
    expect(post.spaceKey, 'study');
    expect(post.content, isNot(contains('https://')));
    expect(post.content, contains('This week is BEMA 183, ${study.title}.'));
    expect(post.content, contains('We gather ${study.gatheringLabel}.'));
    expect(post.content, contains('1. ${study.questions.first}'));
    expect(post.content, contains('5. ${study.questions.last}'));
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

    repo.absorbCloudPosts([
      weeklyDiscussionPost(bemaEpisode183).copyWith(
        content:
            'Show notes: ${bemaEpisode183.showNotesUrl} Transcript: ${bemaEpisode183.transcriptUrl}',
      ),
    ]);
    expect(repo.findPost('bema-week-183')!.content, isNot(contains('https://')));
    expect(repo.findPost('bema-week-183')!.content, contains('Discussion questions'));
  });

  testWidgets('the This Week card fits a phone and a desktop width', (tester) async {
    final overflows = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') || message.contains('RenderFlex')) {
        overflows.add(details);
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    for (final width in <double>[390, 1100]) {
      overflows.clear();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width + 80, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                child: BemaThisWeekCard(
                  study: bemaEpisode183,
                  primaryColor: const Color(0xFF2E6B56),
                  isContrast: false,
                  onJoinCall: () {},
                  onOpenDiscussion: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(overflows, isEmpty, reason: 'width $width overflowed');
      expect(find.text('Show notes'), findsOneWidget);
      expect(find.text('Transcript'), findsOneWidget);
      expect(find.textContaining('Sundays, 7:30 PM CT'), findsOneWidget);
      final notesWidth = tester.getSize(find.byKey(const Key('bema_card_show_notes'))).width;
      final appleWidth = tester.getSize(find.byKey(const Key('bema_card_apple_podcasts'))).width;
      final questionsWidth = tester.getSize(find.byKey(const Key('bema_card_questions'))).width;
      expect(appleWidth, notesWidth);
      expect(questionsWidth, notesWidth);
      final cardWidth = tester.getSize(find.byKey(const Key('bema_this_week_card'))).width;
      expect(cardWidth, lessThanOrEqualTo(width));
      expect(cardWidth, greaterThan(width - 40));
    }
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
    expect(find.textContaining('Sundays, 7:30 PM CT'), findsOneWidget);
    expect(find.text('Show notes'), findsOneWidget);
    expect(find.text('Transcript'), findsOneWidget);
    expect(find.text('Apple Podcasts'), findsOneWidget);

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
    expect(find.text('Discussion questions'), findsOneWidget);
    expect(find.textContaining('1. What are the problems'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);

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

  test('a Firestore row with a generated id is still this week\'s study', () {
    const oldDump = '''
BEMA 183 — Revelation — Seals from Scripture
The Return of the Horses

Gathering: Sundays, 7:30 PM CT
Listen: https://www.bemadiscipleship.com/183
Show notes: https://www.bemadiscipleship.com/183
Transcript: https://docs.google.com/document/d/example/pub
''';
    final cloud = Post(
      id: 'firestore-week-183',
      authorName: 'Weekly Study',
      spaceKey: 'study',
      toneTag: '[Question]',
      content: oldDump,
      timestamp: DateTime.utc(2026, 11, 22, 18),
      reactions: const {},
    );
    expect(weeklyStudyForPostId(cloud.id), isNull);
    expect(weeklyStudyForPost(cloud), same(bemaEpisode183));
  });

  testWidgets('the home feed paints the structured post, not the stored URL dump', (tester) async {
    const oldDump = '''
BEMA 183 — Revelation — Seals from Scripture
The Return of the Horses

Gathering: Sundays, 7:30 PM CT
Listen: https://www.bemadiscipleship.com/183
Show notes: https://www.bemadiscipleship.com/183
Transcript: https://docs.google.com/document/d/example/pub
Discussion video: https://www.youtube.com/watch?v=q4RSOhwDV4M
Apple Podcasts: https://podcasts.apple.com/us/podcast/the-bema-podcast/id1148115183
''';
    for (final width in <double>[390, 1280]) {
      final repository = LocalPostRepository(isDevMode: false);
      await repository.getPosts(spaceKey: 'study');
      repository.absorbCloudPosts([
        Post(
          id: 'firestore-week-183',
          authorName: 'Weekly Study',
          spaceKey: 'study',
          toneTag: '[Question]',
          content: oldDump,
          timestamp: DateTime.utc(2026, 11, 22, 18),
          reactions: const {},
        ),
      ]);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [postRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: RefugeHomeScreen(repository: repository, initialSpace: 'study'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('This week is BEMA'), findsWidgets);
      expect(find.textContaining('Listen: https://'), findsNothing);
      expect(find.textContaining('BEMA 183 —'), findsNothing);
      expect(find.byKey(const Key('bema_post_firestore-week-183_show_notes')), findsOneWidget);
      expect(find.byKey(const Key('bema_post_firestore-week-183_listen')), findsOneWidget);

      final notes = tester.getSize(find.byKey(const Key('bema_card_show_notes')));
      final apple = tester.getSize(find.byKey(const Key('bema_card_apple_podcasts')));
      final questions = tester.getSize(find.byKey(const Key('bema_card_questions')));
      expect(apple.width, notes.width);
      expect(questions.width, notes.width);
      expect(notes.width, greaterThan(width == 390 ? 120 : 200));
    }
  });

  testWidgets('Join the weekly call opens the lobby for bema-weekly', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LocalPostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: RefugeHomeScreen(repository: repository)),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bema_weekly_join_call')));
    await tester.pumpAndSettle();
    expect(find.text('Group call'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('group_call_name_field')));
    expect(field.controller?.text, 'bema-weekly');
  });
}
