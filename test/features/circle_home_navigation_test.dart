import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reflection.dart';

void main() {
  patrolWidgetTest(
    'BDD: Member lands on Sanctuary home, navigates spaces, and views announcements',
    ($) async {
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            reflectionsStreamProvider.overrideWith(
              (ref) => Stream.value([
                Reflection(
                  id: 'announcement-1',
                  authorId: 'organizer-marty',
                  authorName: 'Marty (Organizer)',
                  content: 'Welcome to Belong on the Spectrum alpha test!',
                  timestamp: DateTime.now(),
                  careAffirmations: const {'prayer': 5, 'encouraged': 3},
                  tags: const ['announcements'],
                ),
              ]),
            ),
          ],
          child: const SanctuaryApp(),
        ),
      );

      // 1. Verify app header and scripture anchor
      expect($('Belong'), findsWidgets);
      expect($('Feed'), findsWidgets);
      expect($('Spaces'), findsOneWidget);

      // 2. Navigate to Spaces directory
      await $(const Key('subnav_spaces_tab')).tap();
      expect($('PINNED'), findsOneWidget);
      expect($('WELCOME'), findsOneWidget);
      expect($('Start Here & Introduce Yourself'), findsOneWidget);
      expect($('General Chat'), findsWidgets);

      // 3. Tap Vote & Feedback button and upvote a WIP item in 1 tap
      await $(const Key('open_feedback_and_voting_button')).tap();
      expect($('Belong Roadmap & Feedback'), findsOneWidget);
      expect($('Direct Messages (Msgs Tab)'), findsOneWidget);
      expect($('24'), findsOneWidget);

      await $('24').tap();
      expect($('25'), findsOneWidget);

      // 4. Close bottom sheet and navigate back to feed
      await $.tester.tapAt(const Offset(20, 20));
      await $.pumpAndSettle();
      await $(const Key('subnav_feed_tab')).tap();
      expect($('Feed'), findsWidgets);
    },
  );

  patrolWidgetTest(
    'BDD: Member opens Directory from Spaces and browses fellowship members',
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: SanctuaryApp(),
        ),
      );

      // Navigate to Spaces
      await $(const Key('subnav_spaces_tab')).tap();

      // Tap on Members Section & Directory card
      await $('Members Section & Directory').tap();

      // Verify directory opens with search and members list
      expect($('Belong Members Directory'), findsOneWidget);
      expect($('Marty (Organizer)'), findsOneWidget);
      expect($('Hannah'), findsOneWidget);

      // Search for Hannah
      await $(const Key('members_search_field')).enterText('Hannah');
      expect($('Hannah'), findsOneWidget);
      expect($('Alex'), findsNothing);
    },
  );

  patrolWidgetTest(
    'BDD: Member views reflection and interacts with care affirmation reaction',
    ($) async {
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            reflectionsStreamProvider.overrideWith(
              (ref) => Stream.value([
                Reflection(
                  id: 'prayer-req-1',
                  authorId: 'member-alex',
                  authorName: 'Alex',
                  content: 'Please pray for my upcoming sensory exam.',
                  timestamp: DateTime.now(),
                  careAffirmations: const {'prayer': 2},
                  tags: const ['prayer-sanctuary'],
                ),
              ]),
            ),
          ],
          child: const SanctuaryApp(),
        ),
      );

      // Verify reflection and prayer button
      expect($('Alex'), findsOneWidget);
      expect($('Please pray for my upcoming sensory exam.'), findsOneWidget);
      expect($('2 Praying'), findsOneWidget);

      // Tap prayer reaction button to increment care affirmation
      await $('2 Praying').tap();
      expect($('3 Praying'), findsOneWidget);
    },
  );
}
