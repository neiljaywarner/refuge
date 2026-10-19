import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  testWidgets(
    'End-to-end integration flow: Feature Voting persists across modal sheet openings with Appwrite/Serverpod/Firebase adapters',
    (tester) async {
      await tester.pumpWidget(
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
      await tester.tap(find.byKey(const Key('open_feedback_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);

      // 2. Tap upvote on Direct Messages
      await tester.tap(find.byKey(const Key('vote_button_wip-direct-messages')));
      await tester.pumpAndSettle();
      expect(find.text('25'), findsOneWidget);
    },
  );
}
