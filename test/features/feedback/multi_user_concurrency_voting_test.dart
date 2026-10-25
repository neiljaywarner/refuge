import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  group('Multi-User Concurrency & Cross-Session Real-Time Sync (#302, #303, #309)', () {
    test('User A and User B concurrently update vote tallies and proposals in real time', () async {
      // Shared broadcast controller simulating a real-time WebSocket or Firestore stream
      final sharedStreamController = StreamController<List<VotableFeatureItem>>.broadcast();
      addTearDown(sharedStreamController.close);

      final repoA = InMemoryFeatureVotingRepository(customStreamController: sharedStreamController);
      final repoB = InMemoryFeatureVotingRepository(customStreamController: sharedStreamController);

      final containerA = ProviderContainer(
        overrides: [featureVotingRepositoryProvider.overrideWithValue(repoA)],
      );
      final containerB = ProviderContainer(
        overrides: [featureVotingRepositoryProvider.overrideWithValue(repoB)],
      );
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      // Initial state for both users
      final initialA = containerA.read(featureVotingProvider);
      final initialB = containerB.read(featureVotingProvider);
      expect(initialA.first.votes, 0);
      expect(initialA.first.userVoted, isFalse);
      expect(initialB.first.votes, 0);
      expect(initialB.first.userVoted, isFalse);

      // Step 1: User A votes for WIP Direct Messages
      containerA.read(featureVotingProvider.notifier).toggleVote('wip-direct-messages');

      // User A's optimistic local state
      final userAAfterVote = containerA
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userAAfterVote.votes, 1);
      expect(userAAfterVote.userVoted, isTrue);

      // Allow microtask broadcast to deliver to User B's stream listener
      await pumpEventQueue();

      // User B's state reactively receives update (votes: 1, userVoted: false)
      final userBAfterSync = containerB
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userBAfterSync.votes, 1);
      expect(userBAfterSync.userVoted, isFalse);

      // Step 2: User B also votes for WIP Direct Messages (now 2 votes)
      containerB.read(featureVotingProvider.notifier).toggleVote('wip-direct-messages');

      final userBAfterVote = containerB
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userBAfterVote.votes, 2);
      expect(userBAfterVote.userVoted, isTrue);

      await pumpEventQueue();

      // User A receives User B's vote; User A remains userVoted: true
      final userAAfterSecondSync = containerA
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userAAfterSecondSync.votes, 2);
      expect(userAAfterSecondSync.userVoted, isTrue);

      // Step 3: User A unvotes (reverts to 1 vote)
      containerA.read(featureVotingProvider.notifier).toggleVote('wip-direct-messages');

      final userAAfterUnvote = containerA
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userAAfterUnvote.votes, 1);
      expect(userAAfterUnvote.userVoted, isFalse);

      await pumpEventQueue();

      final userBAfterUnvoteSync = containerB
          .read(featureVotingProvider)
          .firstWhere((e) => e.id == 'wip-direct-messages');
      expect(userBAfterUnvoteSync.votes, 1);
      expect(userBAfterUnvoteSync.userVoted, isTrue);

      // Step 4: User A proposes a new community idea
      containerA
          .read(featureVotingProvider.notifier)
          .proposeFeature(
            title: 'Sensory Audio Calming Room',
            description: 'Ambient brown noise and soft fellowship tones.',
          );

      await pumpEventQueue();

      final userBFeatures = containerB.read(featureVotingProvider);
      expect(userBFeatures.length, initialB.length + 1);
      expect(userBFeatures.last.title, 'Sensory Audio Calming Room');
      expect(userBFeatures.last.votes, 1);
      expect(userBFeatures.last.userVoted, isFalse); // User B hasn't voted on it
    });

    patrolWidgetTest(
      'Dual-client UI widget concurrency: User A vote immediately renders in User B UI without reload',
      ($) async {
        final sharedStreamController = StreamController<List<VotableFeatureItem>>.broadcast();
        addTearDown(sharedStreamController.close);

        final repoA = InMemoryFeatureVotingRepository(
          customStreamController: sharedStreamController,
        );
        final repoB = InMemoryFeatureVotingRepository(
          customStreamController: sharedStreamController,
        );

        // Render both clients side-by-side in dual sub-scopes
        await $.pumpWidgetAndSettle(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: ProviderScope(
                      overrides: [featureVotingRepositoryProvider.overrideWithValue(repoA)],
                      child: const Column(
                        children: [
                          Text('Client A (User 1)'),
                          Expanded(child: BelongFeedbackAndVotingSheet()),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ProviderScope(
                      overrides: [featureVotingRepositoryProvider.overrideWithValue(repoB)],
                      child: const Column(
                        children: [
                          Text('Client B (User 2)'),
                          Expanded(child: BelongFeedbackAndVotingSheet()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Both clients start with 0 votes on WIP Direct Messages
        expect($('Client A (User 1)'), findsOneWidget);
        expect($('Client B (User 2)'), findsOneWidget);

        final voteButtons = $(const Key('vote_button_wip-direct-messages'));
        expect(voteButtons, findsNWidgets(2));

        // Client A taps vote button
        await voteButtons.first.tap();
        await $.pumpAndSettle();

        // Both Client A and Client B should now display '1'
        final countOnA = find.descendant(of: voteButtons.first, matching: find.text('1'));
        final countOnB = find.descendant(of: voteButtons.last, matching: find.text('1'));
        expect(countOnA, findsOneWidget);
        expect(countOnB, findsOneWidget);

        // Client B taps vote button -> count updates to 2 for both!
        await voteButtons.last.tap();
        await $.pumpAndSettle();

        final countTwoOnA = find.descendant(of: voteButtons.first, matching: find.text('2'));
        final countTwoOnB = find.descendant(of: voteButtons.last, matching: find.text('2'));
        expect(countTwoOnA, findsOneWidget);
        expect(countTwoOnB, findsOneWidget);
      },
    );
  });
}
