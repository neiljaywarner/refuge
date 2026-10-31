import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/feedback/application/private_feedback_router.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_source_stamp.dart';

void main() {
  group('PrivateFeedbackRouter & Sibling Repo Decoupling (#124)', () {
    const router = PrivateFeedbackRouter();

    test('routes public praise (happy / Works Great) to PublicPraiseDestination', () {
      final destination = router.resolveDestination(FeedbackSentiment.happy);
      expect(destination, equals(const PublicPraiseDestination()));
    });

    test('routes private suggestion (neutral / Idea / Tweak) to PrivateRepoDestination', () {
      final destination = router.resolveDestination(FeedbackSentiment.neutral);
      expect(
        destination,
        equals(const PrivateRepoDestination(repository: 'neiljaywarner/belong_feedback')),
      );
    });

    test('routes bug / sensory overload (sad / Bug / Confusing) to PrivateRepoDestination', () {
      final destination = router.resolveDestination(FeedbackSentiment.sad);
      expect(
        destination,
        equals(const PrivateRepoDestination(repository: 'neiljaywarner/belong_feedback')),
      );
    });

    test('formats private issue payload with labels, markdown summary, and zero PII leaks to public repo', () {
      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.sad,
        message: 'The font size in the quiet digest banner is slightly small on mobile.\nPlease consider adding a larger text option.',
        contactEmail: 'alex@belong.org',
        timestamp: DateTime.parse('2026-10-19T20:30:00Z'),
        source: FeedbackSourceStamp.production,
      );

      expect(payload.repository, 'neiljaywarner/belong_feedback');
      expect(
        payload.title,
        startsWith('[Bug / Confusing] The font size in the quiet digest banner'),
      );
      expect(payload.labels, containsAll(['user-feedback', 'bug-report']));
      expect(payload.body, contains('## Community Feedback Submission'));
      expect(payload.body, contains('alex@belong.org'));
      expect(payload.body, contains('neiljaywarner/belong_feedback'));
      expect(payload.body, contains('**Source environment**: `production`'));
      expect(payload.labels, isNot(contains('preview')));
    });

    test('prefixes a preview note and adds the preview label', () {
      const preview = FeedbackSourceStamp(
        sourceEnvironment: 'preview',
        sourceHost: 'belongonthespectrum--feedback-659-abc.web.app',
        sourceUrl: 'https://belongonthespectrum--feedback-659-abc.web.app',
      );
      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.neutral,
        message: 'Please keep the digest quiet.',
        source: preview,
      );

      expect(payload.title, startsWith('[preview] [Idea / Tweak]'));
      expect(payload.labels, contains('preview'));
      expect(payload.body, contains('**Source environment**: `preview` (`${preview.sourceHost}`)'));
      expect(payload.body, contains('**Source URL**: `${preview.sourceUrl}`'));
    });

    test('records the source environment on the submission log', () async {
      const preview = FeedbackSourceStamp(
        sourceEnvironment: 'preview',
        sourceHost: 'belongonthespectrum--feedback-659-abc.web.app',
        sourceUrl: 'https://belongonthespectrum--feedback-659-abc.web.app',
      );
      final repo = InMemoryFeatureVotingRepository(sourceStamp: preview);
      await repo.submitFeedback(
        sentiment: FeedbackSentiment.neutral,
        message: 'A quieter digest please.',
      );

      final logged = repo.submittedFeedbackLog.single;
      expect(logged['sourceEnvironment'], 'preview');
      expect(logged['sourceHost'], preview.sourceHost);
      expect(logged['sourceUrl'], preview.sourceUrl);
      expect(logged['submittedAt'], isNotEmpty);
    });

    test('records destination in FeatureVotingRepository submittedFeedbackLog', () async {
      final repo = InMemoryFeatureVotingRepository();
      await repo.submitFeedback(
        sentiment: FeedbackSentiment.sad,
        message: 'Unexpected screen pop when double tapping back.',
        contactEmail: 'tester@belong.org',
      );

      expect(repo.submittedFeedbackLog, hasLength(1));
      final logged = repo.submittedFeedbackLog.first;
      expect(logged['sentiment'], 'sad');
      expect(logged['isPrivateTriage'], 'true');
      expect(logged['destination'], 'neiljaywarner/belong_feedback');
      expect(logged['contactEmail'], 'tester@belong.org');

      // Now submit public praise
      await repo.submitFeedback(
        sentiment: FeedbackSentiment.happy,
        message: 'I love the sage calm theme! So relaxing.',
      );

      expect(repo.submittedFeedbackLog, hasLength(2));
      final praiseLogged = repo.submittedFeedbackLog[1];
      expect(praiseLogged['sentiment'], 'happy');
      expect(praiseLogged['isPrivateTriage'], 'false');
      expect(praiseLogged['destination'], 'public_community_board');
    });
  });
}
