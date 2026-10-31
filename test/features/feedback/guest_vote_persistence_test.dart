import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/vote_storage_service.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  setUp(() {
    VoteStorageService.instance.clear();
  });

  tearDown(() {
    VoteStorageService.instance.clear();
  });

  group('Guest Feature Vote Persistence Across Reloads (#487, #500)', () {
    test('VoteStorageService correctly records, toggles, and clears voted feature IDs', () {
      final storage = VoteStorageService.instance;
      expect(storage.getVotedFeatureIds(), isEmpty);
      expect(storage.isFeatureVoted('planned-autistic-events'), isFalse);

      storage.setFeatureVoted('planned-autistic-events', true);
      expect(storage.isFeatureVoted('planned-autistic-events'), isTrue);
      expect(storage.getVotedFeatureIds(), contains('planned-autistic-events'));

      storage.toggleFeatureVoted('planned-autistic-events');
      expect(storage.isFeatureVoted('planned-autistic-events'), isFalse);

      storage.toggleFeatureVoted('wip-google-apple-auth');
      expect(storage.isFeatureVoted('wip-google-apple-auth'), isTrue);

      storage.clear();
      expect(storage.getVotedFeatureIds(), isEmpty);
    });

    test('Simulated page reload restores guest vote and prevents vote inflation', () {
      // Session 1: Guest opens the app and upvotes a feature
      final container1 = ProviderContainer(
        overrides: [featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
      );

      final features1 = container1.read(featureVotingProvider);
      final target = features1.firstWhere((f) => f.id == 'planned-autistic-events');
      final baselineVotes = target.votes;
      expect(target.userVoted, isFalse);

      // Upvote
      container1.read(featureVotingProvider.notifier).toggleVote(target.id);
      final voted1 = container1
          .read(featureVotingProvider)
          .firstWhere((f) => f.id == 'planned-autistic-events');
      expect(voted1.userVoted, isTrue);
      expect(voted1.votes, baselineVotes + 1);

      // Session 1 ends (user reloads page / closes tab)
      container1.dispose();

      // Session 2: Fresh reload
      final container2 = ProviderContainer(
        overrides: [featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
      );
      addTearDown(container2.dispose);

      final features2 = container2.read(featureVotingProvider);
      final restored = features2.firstWhere((f) => f.id == 'planned-autistic-events');

      // Crucial assertion for #487 and #500: userVoted MUST remain true after reload!
      expect(restored.userVoted, isTrue, reason: 'Guest vote state must survive page reload');
      expect(restored.votes, baselineVotes + 1);

      // Tapping again removes vote instead of inflating count
      container2.read(featureVotingProvider.notifier).toggleVote(target.id);
      final unvoted2 = container2
          .read(featureVotingProvider)
          .firstWhere((f) => f.id == 'planned-autistic-events');
      expect(unvoted2.userVoted, isFalse);
      expect(unvoted2.votes, baselineVotes);
    });

    test('FirebaseFeatureVotingRepository restores userVoted from VoteStorageService', () async {
      VoteStorageService.instance.setFeatureVoted('planned-autistic-events', true);
      final repo = FirebaseFeatureVotingRepository();

      final initial = repo.loadInitialFeatures();
      final item = initial.firstWhere((f) => f.id == 'planned-autistic-events');
      expect(item.userVoted, isTrue);
    });

    patrolWidgetTest(
      'BDD: Guest votes in feedback sheet, sheet reloads, button shows voted state and unvotes cleanly',
      ($) async {
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
            ],
            child: const MaterialApp(home: Scaffold(body: BelongFeedbackAndVotingSheet())),
          ),
        );

        Finder countInsideVoteButton(String count) => find.descendant(
          of: find.byKey(const Key('vote_button_planned-autistic-events')),
          matching: find.text(count),
        );

        expect(countInsideVoteButton('0'), findsOneWidget);

        await $(find.byKey(const Key('vote_button_planned-autistic-events'))).tap();
        await $.pumpAndSettle();
        expect(countInsideVoteButton('1'), findsOneWidget);

        // Simulate page reload by pumping a brand new ProviderScope
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
            ],
            child: const MaterialApp(home: Scaffold(body: BelongFeedbackAndVotingSheet())),
          ),
        );

        expect(countInsideVoteButton('1'), findsOneWidget);

        await $(find.byKey(const Key('vote_button_planned-autistic-events'))).tap();
        await $.pumpAndSettle();
        expect(countInsideVoteButton('0'), findsOneWidget);
      },
    );
  });
}
