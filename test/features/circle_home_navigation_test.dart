import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Pragmatic TDD: FeatureVotingNotifier & Literal Feedback Intents', () {
    test('toggles vote count and userVoted state cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(featureVotingProvider);
      final dmItem = initial.firstWhere(
        (e) => e.id == 'wip-direct-messages',
      );
      expect(dmItem.votes, 24);
      expect(dmItem.userVoted, isFalse);

      container
          .read(featureVotingProvider.notifier)
          .toggleVote('wip-direct-messages');
      final afterUpvote = container
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(afterUpvote.votes, 25);
      expect(afterUpvote.userVoted, isTrue);
    });

    test('Literal 3-Intent FeedbackSentiment routes Neutral/Sad privately', () {
      expect(FeedbackSentiment.happy.isPrivateTriage, isFalse);
      expect(FeedbackSentiment.neutral.isPrivateTriage, isTrue);
      expect(FeedbackSentiment.sad.isPrivateTriage, isTrue);
    });
  });

  patrolWidgetTest(
    'BDD (patrol_finders): Member navigates Circle Spaces, opens Roadmap & Feedback, and upvotes WIP feature',
    ($) async {
      await $.pumpWidgetAndSettle(
        RefugeApp(repository: LocalPostRepository()),
      );

      // 1. Verify Belong header and sub-navigation chips
      expect($('Belong'), findsWidgets);
      expect($(const Key('subnav_feed_tab')), findsOneWidget);
      expect($(const Key('subnav_spaces_tab')), findsOneWidget);

      // 2. Tap Spaces sub-tab and verify Circle-style section headers
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

      await $(const Key('vote_button_wip-direct-messages')).tap();
      expect($('25'), findsOneWidget);

      // 4. Switch to Share Feedback tab and verify Literal 3-Intent cards
      await $(const Key('tab_private_feedback')).tap();
      expect($('Works Great'), findsOneWidget);
      expect($('Idea / Tweak'), findsOneWidget);
      expect($('Bug / Confusing'), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'BDD: Member opens Spaces and navigates to Members Section & Directory (#93)',
    ($) async {
      await $.tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));

      await $.pumpWidgetAndSettle(
        RefugeApp(repository: LocalPostRepository()),
      );

      await $(const Key('subnav_spaces_tab')).tap();
      await $.pumpAndSettle();

      expect($('Members Section & Directory'), findsOneWidget);
      await $('Members Section & Directory').tap();
      await $.pumpAndSettle();

      expect(
        $('Store profile info & connect with verified fellowship members'),
        findsOneWidget,
      );
      expect($('Marty (Organizer)'), findsOneWidget);
    },
  );
}
