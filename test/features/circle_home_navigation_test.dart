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
      expect(dmItem.votes, 0);
      expect(dmItem.userVoted, isFalse);

      container
          .read(featureVotingProvider.notifier)
          .toggleVote('wip-direct-messages');
      final afterUpvote = container
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(afterUpvote.votes, 1);
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
      expect(
        find.descendant(
          of: find.byKey(const Key('vote_button_wip-direct-messages')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );

      await $(const Key('vote_button_wip-direct-messages')).tap();
      expect(
        find.descendant(
          of: find.byKey(const Key('vote_button_wip-direct-messages')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

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

  patrolWidgetTest(
    'BDD: AppBar shows Sign In when signed out, and Avatar when signed in (#238)',
    ($) async {
      // 1. Signed-out state: verify Sign In button is present, avatar is absent
      await $.pumpWidgetAndSettle(
        RefugeApp(repository: LocalPostRepository()),
      );

      expect($(const Key('home_top_bar_sign_in_button')), findsOneWidget);
      expect($(const Key('belong_profile_avatar_button')), findsNothing);

      // 2. Signed-in state: override memberProfileProvider with signed-in profile
      final signedInContainer = ProviderContainer(
        overrides: [
          memberProfileProvider.overrideWith(
            () => _FakeSignedInProfileNotifier(),
          ),
        ],
      );
      addTearDown(signedInContainer.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: signedInContainer,
          child: RefugeApp(repository: LocalPostRepository()),
        ),
      );

      expect($(const Key('home_top_bar_sign_in_button')), findsNothing);
      expect($(const Key('belong_profile_avatar_button')), findsOneWidget);
      expect($('JD'), findsOneWidget);
    },
  );
}

class _FakeSignedInProfileNotifier extends MemberProfileNotifier {
  @override
  MemberProfile build() {
    return const MemberProfile(
      displayName: 'Joy Disciple',
      email: 'joy@belong.org',
      bio: 'Belong Disciple',
      comfortBadges: ['Literal communication appreciated'],
      isSignedIn: true,
      authMethod: 'firebase_auth',
    );
  }
}
