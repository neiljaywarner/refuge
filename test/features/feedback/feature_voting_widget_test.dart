import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  group('BelongFeedbackAndVotingSheet Widget & Patrol BDD Tests', () {
    patrolWidgetTest(
      'renders WIP roadmap items, increments vote count on 1-tap, and switches to 3-intent feedback tab',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(
                BackendTarget.appwrite,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(),
              ),
            ),
          ),
        );

        // Verify header & WIP roadmap items
        expect($('Belong Roadmap & Feedback'), findsOneWidget);
        expect($('Direct Messages (Msgs Tab)'), findsOneWidget);
        expect($('24'), findsOneWidget);

        // Tap upvote on Direct Messages
        await $(const Key('vote_button_wip-direct-messages')).tap();
        expect($('25'), findsOneWidget);

        // Switch to Literal 3-Intent Feedback tab
        await $(const Key('tab_private_feedback')).tap();
        expect($('What kind of note would you like to share?'), findsOneWidget);
        expect($('Works Great'), findsOneWidget);
        expect($('Idea / Tweak'), findsOneWidget);
        expect($('Bug / Confusing'), findsOneWidget);

        // Select 'Idea / Tweak' (private suggestion)
        await $(const Key('sentiment_neutral')).tap();
        expect(
          $('What would make Belong clearer or calmer for you?'),
          findsOneWidget,
        );
      },
    );
  });
}
