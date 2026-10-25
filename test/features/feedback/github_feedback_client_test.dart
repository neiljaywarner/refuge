import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/features/feedback/application/private_feedback_router.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/github_feedback_client.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';

void main() {
  group('GitHubFeedbackClient Unit Tests', () {
    test('isConfigured is false when token is empty or whitespace', () {
      final unconfiguredClient = GitHubFeedbackClient(token: '');
      expect(unconfiguredClient.isConfigured, isFalse);

      final whitespaceClient = GitHubFeedbackClient(token: '   ');
      expect(whitespaceClient.isConfigured, isFalse);
    });

    test('isConfigured is true when token is non-empty', () {
      final client = GitHubFeedbackClient(token: 'ghp_test_token_123');
      expect(client.isConfigured, isTrue);
    });

    test('createIssue returns null immediately when token is empty', () async {
      var requestMade = false;
      final mockHttp = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final client = GitHubFeedbackClient(httpClient: mockHttp, token: '');
      final result = await client.createIssue(
        repository: 'neiljaywarner/belong_feedback',
        title: '[Bug] Test bug',
        body: 'Details here',
        labels: ['user-feedback', 'bug-report'],
      );

      expect(result, isNull);
      expect(requestMade, isFalse);
    });

    test('createIssue sends headers and payload, returns issue number and url on 201', () async {
      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.github.com/repos/neiljaywarner/belong_feedback/issues',
        );
        expect(request.headers['Authorization'], 'Bearer test_pat_abc');
        expect(request.headers['Accept'], 'application/vnd.github+json');
        expect(request.headers['X-GitHub-Api-Version'], '2022-11-28');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], '[Bug / Confusing] Button cut off');
        expect(body['body'], contains('Community Feedback Submission'));
        expect(body['labels'], ['user-feedback', 'bug-report']);

        return http.Response(
          jsonEncode({
            'number': 2,
            'html_url':
                'https://github.com/neiljaywarner/belong_feedback/issues/2',
          }),
          201,
        );
      });

      final client = GitHubFeedbackClient(
        httpClient: mockHttp,
        token: 'test_pat_abc',
      );
      final result = await client.createIssue(
        repository: 'neiljaywarner/belong_feedback',
        title: '[Bug / Confusing] Button cut off',
        body:
            '## Community Feedback Submission\n\nButton cut off on landscape.',
        labels: ['user-feedback', 'bug-report'],
      );

      expect(result, isNotNull);
      expect(result!.number, 2);
      expect(
        result.htmlUrl,
        'https://github.com/neiljaywarner/belong_feedback/issues/2',
      );
    });

    test(
      'createIssue survives 403 rate limit / auth errors without throwing',
      () async {
        final mockHttp = MockClient(
          (request) async => http.Response(
            jsonEncode({'message': 'API rate limit exceeded'}),
            403,
          ),
        );

        final client = GitHubFeedbackClient(
          httpClient: mockHttp,
          token: 'test_pat_abc',
        );
        final result = await client.createIssue(
          repository: 'neiljaywarner/belong_feedback',
          title: '[Bug] Broken link',
          body: 'Link fails',
          labels: ['user-feedback'],
        );

        expect(result, isNull);
      },
    );

    test(
      'createIssue survives socket / client exceptions without throwing',
      () async {
        final mockHttp = MockClient((request) async {
          throw http.ClientException('Network unreachable');
        });

        final client = GitHubFeedbackClient(
          httpClient: mockHttp,
          token: 'test_pat_abc',
        );
        final result = await client.createIssue(
          repository: 'neiljaywarner/belong_feedback',
          title: '[Bug] Broken link',
          body: 'Link fails',
          labels: ['user-feedback'],
        );

        expect(result, isNull);
      },
    );
  });

  group('PrivateFeedbackRouter Inline Base64 Screenshot Embedding', () {
    test('formatPrivateIssue embeds base64 image and collapsible details when bytes present', () {
      const router = PrivateFeedbackRouter();
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final expectedBase64 = base64Encode(sampleBytes);

      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.sad,
        message: 'The contrast is too harsh in dark mode.',
        attachmentBytes: sampleBytes,
      );

      expect(
        payload.body,
        contains(
          '<img src="data:image/png;base64,$expectedBase64" alt="Annotated Screenshot" width="400" />',
        ),
      );
      expect(
        payload.body,
        contains('<details><summary>Raw Base64 PNG</summary>'),
      );
      expect(payload.body, contains(expectedBase64));
    });
  });

  group('InMemoryFeatureVotingRepository with GitHubFeedbackClient', () {
    test('submitFeedback calls GitHub client and sets result metadata for private triage', () async {
      final mockHttp = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'number': 5,
            'html_url':
                'https://github.com/neiljaywarner/belong_feedback/issues/5',
          }),
          201,
        ),
      );

      final gitHubClient = GitHubFeedbackClient(
        httpClient: mockHttp,
        token: 'pat_123',
      );

      final repo = InMemoryFeatureVotingRepository(gitHubClient: gitHubClient);
      final result = await repo.submitFeedback(
        sentiment: FeedbackSentiment.sad,
        message: 'Layout overflow on small phone screen.',
        rating: 1,
        contactEmail: 'tester@belong.org',
      );

      expect(result.isPrivateTriage, isTrue);
      expect(result.githubIssueNumber, 5);
      expect(
        result.githubIssueUrl,
        'https://github.com/neiljaywarner/belong_feedback/issues/5',
      );
      expect(result.savedLocally, isTrue);

      expect(repo.submittedFeedbackLog.length, 1);
      final log = repo.submittedFeedbackLog.first;
      expect(log['githubIssueCreated'], 'true');
      expect(log['githubIssueNumber'], '5');
      expect(
        log['githubIssueUrl'],
        'https://github.com/neiljaywarner/belong_feedback/issues/5',
      );
    });

    test('submitFeedback skips GitHub client for public praise', () async {
      var requestMade = false;
      final mockHttp = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 201);
      });

      final gitHubClient = GitHubFeedbackClient(
        httpClient: mockHttp,
        token: 'pat_123',
      );

      final repo = InMemoryFeatureVotingRepository(gitHubClient: gitHubClient);
      final result = await repo.submitFeedback(
        sentiment: FeedbackSentiment.happy,
        message: 'I love this community app so much!',
        rating: 5,
      );

      expect(result.isPrivateTriage, isFalse);
      expect(result.githubIssueNumber, isNull);
      expect(requestMade, isFalse);
    });
  });
}
