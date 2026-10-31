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
      'renders three planned roadmap items, increments vote count on 1-tap, and switches to feedback tab',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.appwrite),
            ],
            child: const MaterialApp(home: Scaffold(body: BelongFeedbackAndVotingSheet())),
          ),
        );

        expect($('Belong Roadmap & Feedback'), findsOneWidget);
        expect($('Actually Autistic Events Calendar'), findsOneWidget);
        expect($('Google Sign-In (Good Auth)'), findsOneWidget);
        await $.tester.dragUntilVisible(
          find.text('Native iOS App Store and Google Play Apps'),
          find.byType(ListView).first,
          const Offset(0, -120),
        );
        await $.pumpAndSettle();
        expect($('Native iOS App Store and Google Play Apps'), findsOneWidget);
        expect($('Direct Messages (Msgs Tab)'), findsNothing);
        expect($('Calm Notification Bell'), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_planned-native-store-apps')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );

        await $(const Key('vote_button_planned-native-store-apps')).tap();
        expect(
          find.descendant(
            of: find.byKey(const Key('vote_button_planned-native-store-apps')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );

        await $(const Key('tab_private_feedback')).tap();
        expect($('Works Great'), findsOneWidget);
        expect($('Idea / Tweak'), findsOneWidget);
        expect($('Bug / Confusing'), findsOneWidget);

        await $(const Key('sentiment_neutral')).tap();
        expect($('What would make Belong clearer or calmer for you?'), findsOneWidget);
      },
    );

    patrolWidgetTest('shows GitHub tracking line and toggles Google Sign-In vote', ($) async {
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          ],
          child: const MaterialApp(home: Scaffold(body: BelongFeedbackAndVotingSheet())),
        ),
      );

      await $.tester.dragUntilVisible(
        find.text('Tracked in GitHub #45 and #46'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await $.pumpAndSettle();

      expect($('Tracked in GitHub #33'), findsOneWidget);
      expect($('Tracked in GitHub #45 and #46'), findsOneWidget);

      await $(const Key('vote_button_planned-google-sign-in')).tap();
      expect(
        find.descendant(
          of: find.byKey(const Key('vote_button_planned-google-sign-in')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      await $(const Key('vote_button_planned-google-sign-in')).tap();
      expect(
        find.descendant(
          of: find.byKey(const Key('vote_button_planned-google-sign-in')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
    });

    patrolWidgetTest(
      '1-5 star rating bar auto-routes sentiment with literal labels and persists star rating (#386)',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        final inMemoryRepo = InMemoryFeatureVotingRepository();

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [featureVotingRepositoryProvider.overrideWithValue(inMemoryRepo)],
            child: const MaterialApp(
              home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: 1)),
            ),
          ),
        );

        expect($(const Key('star_rating_bar')), findsOneWidget);
        expect($('How do you like Belong on the Spectrum?'), findsOneWidget);
        expect($('5 ★ · Love it! Works great'), findsOneWidget);

        await $(const Key('star_rating_2')).tap();
        await $.pumpAndSettle();
        expect($('2 ★ · Frustrating / Needs work'), findsOneWidget);
        expect($('What felt broken, confusing, or overwhelming?'), findsOneWidget);

        await $(const Key('star_rating_3')).tap();
        await $.pumpAndSettle();
        expect($("3 ★ · It's okay, could be better"), findsOneWidget);
        expect($('What would make Belong clearer or calmer for you?'), findsOneWidget);

        await $(const Key('star_rating_4')).tap();
        await $.pumpAndSettle();
        expect($('4 ★ · Good experience'), findsOneWidget);
        expect($('What feels calm, clear, or welcoming?'), findsOneWidget);

        await $(const Key('feedback_message_input'))
            .enterText('Love the calm PWA star rating flow!');
        await $(const Key('submit_feedback_button')).tap();
        await $.pumpAndSettle();

        expect(inMemoryRepo.submittedFeedbackLog.length, 1);
        expect(inMemoryRepo.submittedFeedbackLog.first['rating'], '4');
        expect(inMemoryRepo.submittedFeedbackLog.first['sentiment'], 'happy');
      },
    );
  });
}
