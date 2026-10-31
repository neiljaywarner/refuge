import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'End-to-end integration flow: Feature Voting persists across modal sheet openings with Appwrite/Serverpod/Firebase adapters',
    ($) async {
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            featureVotingBackendTargetProvider.overrideWithValue(
              BackendTarget.appwrite,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const Key('open_feedback_sheet_btn'),
                    onPressed: () => BelongFeedbackAndVotingSheet.show(context),
                    child: const Text('Feedback & Vote'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Open modal sheet
      await $(const Key('open_feedback_sheet_btn')).tap();

      expect($('Belong Roadmap & Feedback'), findsOneWidget);
      expect($('0'), findsWidgets);

      // 2. Tap upvote on native store apps card (optimistic +1 in session)
      await $(const Key('vote_button_planned-native-store-apps')).tap();
      await $.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('vote_button_planned-native-store-apps')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );
}
