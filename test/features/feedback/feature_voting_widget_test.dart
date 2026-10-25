import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/vote_storage_service.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  setUp(() {
    VoteStorageService.instance.clear();
  });

  tearDown(() {
    VoteStorageService.instance.clear();
  });

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

        // Verify header & WIP roadmap items (initialized to 0 votes for clean launch #304)
        expect($('Belong Roadmap & Feedback'), findsOneWidget);
        expect($('Direct Messages (Msgs Tab)'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_wip-direct-messages')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        // Tap upvote on Direct Messages (0 -> 1)
        await $(const Key('vote_button_wip-direct-messages')).tap();
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_wip-direct-messages')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        // Switch to Literal 3-Intent Feedback tab
        await $(const Key('tab_private_feedback')).tap();
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

    patrolWidgetTest(
      'renders Real-Time Alerts vs. Calm Digest item and toggles vote cleanly (#243)',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(
                BackendTarget.inMemory,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(),
              ),
            ),
          ),
        );

        // Scroll down in the ListView to bring the item into view
        await $.tester.dragUntilVisible(
          find.byKey(const Key('vote_button_idea-realtime-vs-calm-notifications')),
          find.byType(ListView).first,
          const Offset(0, -200),
        );
        await $.pumpAndSettle();

        // Verify the item is listed with 0 initial votes (#304)
        expect(
          $('Real-Time Instant Alerts vs. Calm Batched Digest Toggle'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(
              const Key('vote_button_idea-realtime-vs-calm-notifications'),
            ),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        // Upvote (0 -> 1)
        await $(const Key('vote_button_idea-realtime-vs-calm-notifications')).tap();
        expect(
          find.descendant(
            of: find.byKey(
              const Key('vote_button_idea-realtime-vs-calm-notifications'),
            ),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        // Toggle vote back off (1 -> 0)
        await $(const Key('vote_button_idea-realtime-vs-calm-notifications')).tap();
        expect(
          find.descendant(
            of: find.byKey(
              const Key('vote_button_idea-realtime-vs-calm-notifications'),
            ),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      '1-5 star rating bar auto-routes sentiment with literal labels and persists star rating (#386)',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        final inMemoryRepo = InMemoryFeatureVotingRepository();

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingRepositoryProvider.overrideWithValue(inMemoryRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(initialTabIndex: 1),
              ),
            ),
          ),
        );

        // Verify 1-5 Star Rating Bar is visible with default 5-star literal label
        expect($(const Key('star_rating_bar')), findsOneWidget);
        expect($('How do you like Belong on the Spectrum?'), findsOneWidget);
        expect($('5 ★ · Love it! Works great'), findsOneWidget);

        // Tap 2 stars -> auto-selects Bug / Confusing (sad)
        await $(const Key('star_rating_2')).tap();
        await $.pumpAndSettle();
        expect($('2 ★ · Frustrating / Needs work'), findsOneWidget);
        expect(
          $('What felt broken, confusing, or overwhelming?'),
          findsOneWidget,
        );

        // Tap 3 stars -> auto-selects Idea / Tweak (neutral)
        await $(const Key('star_rating_3')).tap();
        await $.pumpAndSettle();
        expect($("3 ★ · It's okay, could be better"), findsOneWidget);
        expect(
          $('What would make Belong clearer or calmer for you?'),
          findsOneWidget,
        );

        // Tap 4 stars -> auto-selects Works Great (happy)
        await $(const Key('star_rating_4')).tap();
        await $.pumpAndSettle();
        expect($('4 ★ · Good experience'), findsOneWidget);
        expect(
          $('What feels calm, clear, or welcoming?'),
          findsOneWidget,
        );

        // Submit 4-star feedback and verify rating is persisted
        await $(const Key('feedback_message_input')).enterText(
          'Love the calm PWA star rating flow!',
        );
        await $(const Key('submit_feedback_button')).tap();
        await $.pumpAndSettle();

        expect(inMemoryRepo.submittedFeedbackLog.length, 1);
        expect(inMemoryRepo.submittedFeedbackLog.first['rating'], '4');
        expect(inMemoryRepo.submittedFeedbackLog.first['sentiment'], 'happy');
      },
    );
  });
}
