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
      expect(storage.isFeatureVoted('wip-events'), isFalse);

      storage.setFeatureVoted('wip-events', true);
      expect(storage.isFeatureVoted('wip-events'), isTrue);
      expect(storage.getVotedFeatureIds(), contains('wip-events'));

      storage.toggleFeatureVoted('wip-events');
      expect(storage.isFeatureVoted('wip-events'), isFalse);

      storage.toggleFeatureVoted('wip-google-apple-auth');
      expect(storage.isFeatureVoted('wip-google-apple-auth'), isTrue);

      storage.clear();
      expect(storage.getVotedFeatureIds(), isEmpty);
    });

    test('Simulated page reload restores guest vote and prevents vote inflation', () {
      // Session 1: Guest opens the app and upvotes a feature
      final container1 = ProviderContainer(
        overrides: [
          featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );

      final features1 = container1.read(featureVotingProvider);
      final target = features1.firstWhere((f) => f.id == 'wip-events');
      final baselineVotes = target.votes;
      expect(target.userVoted, isFalse);

      // Upvote
      container1.read(featureVotingProvider.notifier).toggleVote(target.id);
      final voted1 = container1.read(featureVotingProvider).firstWhere((f) => f.id == 'wip-events');
      expect(voted1.userVoted, isTrue);
      expect(voted1.votes, baselineVotes + 1);

      // Session 1 ends (user reloads page / closes tab)
      container1.dispose();

      // Session 2: Fresh reload
      final container2 = ProviderContainer(
        overrides: [
          featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container2.dispose);

      final features2 = container2.read(featureVotingProvider);
      final restored = features2.firstWhere((f) => f.id == 'wip-events');

      // Crucial assertion for #487 and #500: userVoted MUST remain true after reload!
      expect(restored.userVoted, isTrue, reason: 'Guest vote state must survive page reload');
      expect(restored.votes, baselineVotes + 1);

      // Tapping again removes vote instead of inflating count
      container2.read(featureVotingProvider.notifier).toggleVote(target.id);
      final unvoted2 = container2.read(featureVotingProvider).firstWhere((f) => f.id == 'wip-events');
      expect(unvoted2.userVoted, isFalse);
      expect(unvoted2.votes, baselineVotes);
    });

    test('FirebaseFeatureVotingRepository restores userVoted from VoteStorageService', () async {
      VoteStorageService.instance.setFeatureVoted('wip-events', true);
      final repo = FirebaseFeatureVotingRepository();

      final initial = repo.loadInitialFeatures();
      final item = initial.firstWhere((f) => f.id == 'wip-events');
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
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(),
              ),
            ),
          ),
        );

        // Switch to Vote on Features tab
        await $(find.text('Vote on Features')).tap();
        await $.pumpAndSettle();

        // Find vote button for wip-events
        final voteButton = find.byKey(const Key('vote_button_wip-events'));
        expect(voteButton, findsOneWidget);
        expect($(find.text('Vote for Events')).exists, isTrue);

        // Tap to vote
        await $(voteButton).tap();
        await $.pumpAndSettle();

        // Button turns green and shows "Remove vote"
        expect($(find.text('Remove vote')).exists, isTrue);

        // Simulate page reload by pumping a brand new ProviderScope
        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(),
              ),
            ),
          ),
        );

        await $(find.text('Vote on Features')).tap();
        await $.pumpAndSettle();

        // Verified: button remains in "Remove vote" state!
        expect($(find.text('Remove vote')).exists, isTrue);

        // Tapping it again un-votes cleanly without inflating
        await $(voteButton).tap();
        await $.pumpAndSettle();
        expect($(find.text('Vote for Events')).exists, isTrue);
      },
    );
  });
}
