import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  group('FeatureVotingRepository & 1-Line Backend Adapter Switching (ADR-0009)', () {
    for (final target in BackendTarget.values) {
      test('executes vote toggle, feature proposal & feedback on ${target.displayName}', () async {
        final container = ProviderContainer(
          overrides: [
            featureVotingBackendTargetProvider.overrideWithValue(target),
          ],
        );
        addTearDown(container.dispose);

        final repo = container.read(featureVotingRepositoryProvider);
        expect(repo.target, target);

        final initial = container.read(featureVotingProvider);
        expect(initial, isNotEmpty);

        final firstItem = initial.first;
        final initialVotes = firstItem.votes;
        expect(firstItem.userVoted, isFalse);

        // 1. Upvote feature
        container.read(featureVotingProvider.notifier).toggleVote(firstItem.id);
        final afterUpvote = container.read(featureVotingProvider).first;
        expect(afterUpvote.userVoted, isTrue);
        expect(afterUpvote.votes, initialVotes + 1);

        // 2. Unvote feature (idempotent toggle)
        container.read(featureVotingProvider.notifier).toggleVote(firstItem.id);
        final afterUnvote = container.read(featureVotingProvider).first;
        expect(afterUnvote.userVoted, isFalse);
        expect(afterUnvote.votes, initialVotes);

        // 3. Propose a new community feature
        container.read(featureVotingProvider.notifier).proposeFeature(
              title: 'Audio MP3 60-Second Release Notes',
              description: 'Calm spoken summary for members who prefer listening.',
            );
        final withProposed = container.read(featureVotingProvider);
        expect(withProposed.length, initial.length + 1);
        expect(withProposed.last.title, 'Audio MP3 60-Second Release Notes');
        expect(withProposed.last.stage, FeatureStage.communityIdea);
        expect(withProposed.last.votes, 1);
        expect(withProposed.last.userVoted, isTrue);

        // 4. Empty title proposal is ignored safely
        container.read(featureVotingProvider.notifier).proposeFeature(
              title: '   ',
              description: 'Ignored',
            );
        expect(container.read(featureVotingProvider).length, initial.length + 1);

        // 5. Submit 3-intent feedback
        await container.read(featureVotingProvider.notifier).submitFeedback(
              sentiment: FeedbackSentiment.neutral,
              message: 'Please add high-contrast dark mode toggle in header',
              contactEmail: 'member@belongonthespectrum.com',
            );
      });
    }

    test('FeedbackSentiment literal 3-intent privacy routing matches ADR-0007', () {
      expect(FeedbackSentiment.happy.isPrivateTriage, isFalse);
      expect(FeedbackSentiment.neutral.isPrivateTriage, isTrue);
      expect(FeedbackSentiment.sad.isPrivateTriage, isTrue);
    });

    test('resolveStarRating and submitFeedback persist 1-5 star ratings for PWA/Web/Mobile audit (#386)', () async {
      final repo = InMemoryFeatureVotingRepository();

      // Default star mapping when rating is omitted
      expect(
        FeatureVotingStateTransformMixin.resolveStarRating(FeedbackSentiment.happy, null),
        5,
      );
      expect(
        FeatureVotingStateTransformMixin.resolveStarRating(FeedbackSentiment.neutral, null),
        3,
      );
      expect(
        FeatureVotingStateTransformMixin.resolveStarRating(FeedbackSentiment.sad, null),
        1,
      );

      // Explicit 4-star rating on happy sentiment
      await repo.submitFeedback(
        sentiment: FeedbackSentiment.happy,
        rating: 4,
        message: 'PWA works great on my iPad Home Screen!',
      );
      expect(repo.submittedFeedbackLog.last['rating'], '4');
      expect(repo.submittedFeedbackLog.last['sentiment'], 'happy');

      // Explicit 2-star rating on sad sentiment
      await repo.submitFeedback(
        sentiment: FeedbackSentiment.sad,
        rating: 2,
        message: 'Landscape rotation test',
      );
      expect(repo.submittedFeedbackLog.last['rating'], '2');
      expect(repo.submittedFeedbackLog.last['sentiment'], 'sad');
    });
  });
}
