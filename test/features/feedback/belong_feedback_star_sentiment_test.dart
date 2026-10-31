import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  group('Feedback star rating and sentiment independence (#492)', () {
    patrolWidgetTest('Bug sentiment does not reset an explicit 5-star pick', ($) async {
      $.tester.view.physicalSize = const Size(1000, 1800);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            featureVotingRepositoryProvider.overrideWithValue(InMemoryFeatureVotingRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: 1)),
          ),
        ),
      );

      await $(const Key('star_rating_5')).tap();
      await $.pumpAndSettle();
      expect(find.textContaining('5 ★ · Love it!'), findsOneWidget);

      await $(const Key('sentiment_sad')).tap();
      await $.pumpAndSettle();
      expect(find.textContaining('5 ★ · Love it!'), findsOneWidget);
      expect(find.byKey(const Key('sentiment_sad')), findsOneWidget);
    });

    patrolWidgetTest('Confusing sentiment does not override after happy is chosen', ($) async {
      await $.pumpWidgetAndSettle(
        ProviderScope(
          overrides: [
            featureVotingRepositoryProvider.overrideWithValue(InMemoryFeatureVotingRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: 1)),
          ),
        ),
      );

      await $(const Key('sentiment_happy')).tap();
      await $.pumpAndSettle();
      await $(const Key('star_rating_2')).tap();
      await $.pumpAndSettle();

      expect(find.textContaining('2 ★ · Frustrating'), findsOneWidget);
      expect(find.byKey(const Key('sentiment_happy')), findsOneWidget);
    });
  });
}
