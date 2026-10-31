import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/member_feedback_bridge.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_source_stamp.dart';

void main() {
  const preview = FeedbackSourceStamp(
    sourceEnvironment: 'preview',
    sourceHost: 'belongonthespectrum--feedback-659-abc.web.app',
    sourceUrl: 'https://belongonthespectrum--feedback-659-abc.web.app',
  );

  group('parseMemberFeedbackForwardResponse', () {
    test('reads an Appwrite execution envelope', () {
      final parsed = parseMemberFeedbackForwardResponse({
        'responseStatusCode': 200,
        'responseBody': jsonEncode({
          'forwarded': true,
          'githubIssueNumber': 12,
          'githubIssueUrl': 'https://github.com/neiljaywarner/belong_feedback/issues/12',
        }),
      });
      expect(parsed, isNotNull);
      expect(parsed!.number, 12);
      expect(parsed.htmlUrl, 'https://github.com/neiljaywarner/belong_feedback/issues/12');
    });

    test('a function failure and a skipped forward produce no issue', () {
      expect(
        parseMemberFeedbackForwardResponse({
          'responseStatusCode': 500,
          'responseBody': '{"error":"feedback forward failed"}',
        }),
        isNull,
      );
      expect(
        parseMemberFeedbackForwardResponse({
          'responseStatusCode': 200,
          'responseBody': '{"forwarded":false,"reason":"github credential is not configured"}',
        }),
        isNull,
      );
    });
  });

  group('AppwriteMemberFeedbackBridge', () {
    test('posts the feedback id and Firebase token, not a GitHub token', () async {
      String? raw;
      final httpClient = MockClient((request) async {
        raw = request.body;
        expect(request.url.path, endsWith('/functions/feedback-forward/executions'));
        expect(request.headers['X-Appwrite-Project'], AppwriteConfig.belongProjectId);
        expect(request.headers.containsKey('X-Appwrite-Key'), isFalse);
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          jsonEncode({
            'responseStatusCode': 200,
            'responseBody': jsonEncode({
              'forwarded': true,
              'githubIssueNumber': 12,
              'githubIssueUrl': 'https://github.com/neiljaywarner/belong_feedback/issues/12',
            }),
          }),
          201,
        );
      });

      final bridge = AppwriteMemberFeedbackBridge(
        httpClient: httpClient,
        idTokenReader: () async => 'firebase-id-token',
      );
      final result = await bridge.forward('feedbackDoc1');

      expect(result!.number, 12);
      final outer = jsonDecode(raw!) as Map<String, dynamic>;
      expect(outer['async'], isFalse);
      final inner = jsonDecode(outer['body'] as String) as Map<String, dynamic>;
      expect(inner['feedbackId'], 'feedbackDoc1');
      expect(inner['idToken'], 'firebase-id-token');
      expect(inner.containsKey('title'), isFalse);
      expect(raw, isNot(contains('FEEDBACK_GITHUB_PAT')));
      expect(raw, isNot(contains('github_pat')));
    });

    test('returns null when the execution HTTP call times out', () async {
      final httpClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response('{}', 201);
      });
      final bridge = AppwriteMemberFeedbackBridge(
        httpClient: httpClient,
        idTokenReader: () async => 'firebase-id-token',
        timeout: const Duration(milliseconds: 15),
      );
      expect(await bridge.forward('feedbackDoc1'), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('does not call the network without an id token', () async {
      var called = false;
      final httpClient = MockClient((request) async {
        called = true;
        return http.Response('{}', 201);
      });
      final bridge = AppwriteMemberFeedbackBridge(
        httpClient: httpClient,
        idTokenReader: () async => null,
      );
      expect(await bridge.forward('feedbackDoc1'), isNull);
      expect(called, isFalse);
    });
  });

  group('FirebaseFeatureVotingRepository forward', () {
    late Map<String, dynamic> stored;

    setUp(() {
      stored = {};
    });

    FirebaseFeatureVotingRepository repo({
      required FeedbackSourceStamp stamp,
      required MemberFeedbackForward? forward,
    }) => FirebaseFeatureVotingRepository(
      sourceStamp: stamp,
      memberId: () => 'member-1',
      feedbackForward: forward,
      persistFeedbackDocument: (data) async {
        stored = data;
        return 'fb-1';
      },
    );

    test('private triage writes the preview stamp and invokes the function', () async {
      String? forwardedId;
      final repoUnderTest = repo(
        stamp: preview,
        forward: (id) async {
          forwardedId = id;
          return (
            number: 15,
            htmlUrl: 'https://github.com/neiljaywarner/belong_feedback/issues/15',
          );
        },
      );

      final result = await repoUnderTest.submitFeedback(
        sentiment: FeedbackSentiment.sad,
        message: 'The banner overflows.',
        rating: 1,
      );

      expect(forwardedId, 'fb-1');
      expect(result.githubIssueNumber, 15);
      expect(result.githubIssueUrl, 'https://github.com/neiljaywarner/belong_feedback/issues/15');
      expect(stored['sourceEnvironment'], 'preview');
      expect(stored['sourceHost'], preview.sourceHost);
      expect(stored['sourceUrl'], preview.sourceUrl);
      expect(stored['submittedAt'], isA<String>());
      expect(stored['userId'], 'member-1');
      expect(stored['authorId'], 'member-1');
      expect(stored['githubIssueCreated'], isFalse);
      expect(repoUnderTest.submittedFeedbackLog.single['githubIssueNumber'], '15');
      expect(repoUnderTest.submittedFeedbackLog.single['sourceEnvironment'], 'preview');
    });

    test('public praise is stored with the stamp and does not call the function', () async {
      var calls = 0;
      final repoUnderTest = repo(
        stamp: preview,
        forward: (id) async {
          calls += 1;
          return (number: 1, htmlUrl: 'https://github.com/neiljaywarner/belong_feedback/issues/1');
        },
      );

      final result = await repoUnderTest.submitFeedback(
        sentiment: FeedbackSentiment.happy,
        message: 'The sage theme feels calm.',
        rating: 5,
      );

      expect(calls, 0);
      expect(result.githubIssueNumber, isNull);
      expect(stored['sourceEnvironment'], 'preview');
      expect(stored['isPrivateTriage'], isFalse);
    });

    test('a function failure keeps the saved-for-organizers result', () async {
      final repoUnderTest = repo(
        stamp: FeedbackSourceStamp.production,
        forward: (id) async => null,
      );

      final result = await repoUnderTest.submitFeedback(
        sentiment: FeedbackSentiment.neutral,
        message: 'Please keep the digest quiet.',
      );

      expect(result.githubIssueNumber, isNull);
      expect(result.savedLocally, isTrue);
      expect(stored['sourceEnvironment'], 'production');
      expect(repoUnderTest.submittedFeedbackLog.single['githubIssueCreated'], 'false');
    });
  });
}
