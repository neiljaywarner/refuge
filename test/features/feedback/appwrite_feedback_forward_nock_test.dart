import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/features/feedback/data/member_feedback_bridge.dart';

import '../../support/http_cassette.dart';

bool _isFeedbackForwardBody(List<int> body, ContentType contentType) {
  final raw = utf8.decode(body);
  return contentType.mimeType == 'application/json' &&
      raw.contains('feedbackDoc1') &&
      raw.contains('firebase-id-token') &&
      !raw.contains('github_pat') &&
      !raw.contains('FEEDBACK_GITHUB_PAT');
}

/// Cassette replay for the feedback-forward Appwrite function.
///
/// The bridge builds a real `http.Client()`. Nock answers it. No token and
/// no live Appwrite project are involved.
void main() {
  const endpoint = 'https://nyc.cloud.appwrite.io/v1';
  const config = AppwriteConfig(endpoint: endpoint, projectId: AppwriteConfig.belongProjectId);

  setUpAll(nock.init);

  setUp(nock.cleanAll);

  tearDownAll(() {
    nock.cleanAll();
    HttpOverrides.global = null;
  });

  AppwriteMemberFeedbackBridge bridge() =>
      AppwriteMemberFeedbackBridge(config: config, idTokenReader: () async => 'firebase-id-token');

  void replay(String fixture, {int statusCode = 201}) {
    nock(endpoint)
        .post('/functions/feedback-forward/executions', _isFeedbackForwardBody)
        .reply(
          statusCode,
          loadHttpFixture('appwrite/$fixture'),
          headers: {'content-type': 'application/json'},
        );
  }

  test('replays a created GitHub issue from the cassette', () async {
    replay('feedback_forward_ok.json');

    final result = await bridge().forward('feedbackDoc1');

    expect(result, isNotNull);
    expect(result!.number, 12);
    expect(result.htmlUrl, 'https://github.com/neiljaywarner/belong_feedback/issues/12');
    expect(nock.pendingMocks, isEmpty);
  });

  test('a function error cassette returns null and keeps the local note', () async {
    replay('feedback_forward_function_error.json');

    expect(await bridge().forward('feedbackDoc1'), isNull);
    expect(nock.pendingMocks, isEmpty);
  });

  test('a refused forward cassette returns null', () async {
    replay('feedback_forward_refused.json');

    expect(await bridge().forward('feedbackDoc1'), isNull);
  });

  test('a string issue number falls back to the public issue URL', () async {
    replay('feedback_forward_string_number.json');

    final result = await bridge().forward('feedbackDoc1');

    expect(result!.number, 44);
    expect(result.htmlUrl, 'https://github.com/neiljaywarner/belong_feedback/issues/44');
  });

  test('an HTTP 401 cassette does not throw', () async {
    replay('feedback_forward_ok.json', statusCode: 401);

    expect(await bridge().forward('feedbackDoc1'), isNull);
  });

  test('a dropped socket returns null', () async {
    nock(endpoint)
        .post('/functions/feedback-forward/executions', _isFeedbackForwardBody)
        .throwNetworkError();

    expect(await bridge().forward('feedbackDoc1'), isNull);
  });

  test('does not call Appwrite when the feedback id or project is missing', () async {
    final unconfigured = AppwriteMemberFeedbackBridge(
      config: const AppwriteConfig(endpoint: '', projectId: ''),
      idTokenReader: () async => 'firebase-id-token',
    );

    expect(await unconfigured.forward('feedbackDoc1'), isNull);
    expect(await bridge().forward('   '), isNull);
    expect(nock.activeMocks, isEmpty);
  });
}
