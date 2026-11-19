import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/observability/error_reporter_service.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_guest_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/group_call_analytics.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/stream_group_call_page.dart';

void main() {
  late CommunityAnalyticsService analytics;
  late ErrorReporterService errors;

  setUp(() {
    analytics = CommunityAnalyticsService(flavor: AppFlavor.dev);
    errors = ErrorReporterService(
      flavor: AppFlavor.dev,
      analyticsService: analytics,
      crashlyticsSupported: false,
    );
    GroupCallTelemetry.bind(GroupCallTelemetry(analytics: analytics, errors: errors));
  });

  tearDown(GroupCallTelemetry.unbind);

  test('call events carry role, surface, and platform, and drop unsafe text', () async {
    await analytics.logCallJoined(role: 'guest');
    await analytics.logCallLeft(role: 'member', durationSeconds: 12);
    await analytics.logCallFailed(role: 'member@example.com', failureReason: 'sign_in_required');
    await analytics.logCallFailed(
      role: 'guest',
      failureReason: 'https://example.com/invite/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    await analytics.logCallMediaToggled(role: 'guest', medium: 'camera', enabled: true);
    await analytics.logCallMediaToggled(
      role: 'member',
      medium: 'https://example.com/camera',
      enabled: false,
    );

    final names = analytics.recordedEventsForTesting.map((event) => event['name']).toList();
    expect(names, ['call_joined', 'call_left', 'call_failed', 'call_failed', 'call_media_toggled']);

    final joined = analytics.recordedEventsForTesting[0];
    expect(joined['role'], 'guest');
    expect(joined['surface'], 'native');
    expect(joined['platform'], isNotEmpty);

    final left = analytics.recordedEventsForTesting[1];
    expect(left['role'], 'member');
    expect(left['duration_seconds'], 12);

    expect(analytics.recordedEventsForTesting[2]['role'], 'member');
    expect(analytics.recordedEventsForTesting[2]['failure_reason'], 'sign_in_required');
    expect(analytics.recordedEventsForTesting[3]['failure_reason'], 'unavailable');
    expect(analytics.recordedEventsForTesting[4]['medium'], 'camera');
    expect(analytics.recordedEventsForTesting[4]['enabled'], isTrue);

    final blob = analytics.recordedEventsForTesting.toString();
    expect(blob, isNot(contains('@')));
    expect(blob, isNot(contains('http')));
    expect(blob, isNot(contains('invite/')));
  });

  test('known call sentences become reason codes and unknown text does not', () {
    expect(callFailureReasonForMessage(streamSignInRequiredMessage), 'sign_in_required');
    expect(callFailureReasonForMessage('This invite link has expired or was revoked.'), 'expired');
    expect(callFailureReasonForMessage('This invite link is not valid.'), 'invalid_invite');
    expect(
      callFailureReasonForMessage('Use a short name. Leave out email addresses and web links.'),
      'invalid_name',
    );
    expect(callFailureReasonForMessage(streamVideoUnconfiguredMessage), 'unconfigured');
    expect(
      callFailureReasonForMessage('member@example.com opened https://example.com'),
      'unavailable',
    );
    expect(callFailureReasonForMessage('Camera permission is off.'), 'unavailable');
  });

  test('a handled error is still an app_error when Crashlytics is unsupported', () async {
    await errors.recordError(
      StateError('call_failed'),
      StackTrace.empty,
      reason: 'see member@example.com at https://example.com/i/${'a' * 43}',
      context: {'note': 'bearer secret-value and eyJhbGciOiJIUzI1NiJ9.aaa.bbb'},
    );

    final event = analytics.recordedEventsForTesting.single;
    expect(event['name'], 'app_error');
    expect(event['crashlytics_recorded'], 0);
    expect(event['reason'], '[SCRUBBED_EMAIL]');
    expect(event.toString(), isNot(contains('example.com')));
    expect(event.toString(), isNot(contains('eyJ')));

    final recorded = errors.recordedErrorsForTesting.single;
    expect(recorded['reason'], '[SCRUBBED_EMAIL]');
    expect(recorded['context'], {'note': '[SCRUBBED_SECRET]'});
    expect(recorded.toString(), isNot(contains('a' * 43)));
  });

  test('mint and invite failures record a reason and omit credentials', () async {
    const idToken = 'firebase-id-token';
    final member = StreamTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      httpClient: MockClient(
        (request) async => http.Response('{"error":"Sign in is required."}', 401),
      ),
      readIdToken: () async => idToken,
    );
    addTearDown(member.close);
    await expectLater(member.mint(callId: 'monthly'), throwsA(isA<StreamTokenException>()));

    final invite = StreamTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      httpClient: MockClient((request) async => http.Response('{}', 503)),
      readIdToken: () async => idToken,
    );
    addTearDown(invite.close);
    await expectLater(
      invite.createGuestInvite(callId: 'monthly'),
      throwsA(isA<StreamTokenException>()),
    );

    const inviteToken = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final guest = StreamGuestTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      inviteToken: inviteToken,
      httpClient: MockClient(
        (request) async => http.Response(jsonEncode({'code': 'not-found'}), 404),
      ),
    );
    addTearDown(guest.close);
    await expectLater(
      guest.join(displayName: 'member@example.com'),
      throwsA(isA<StreamTokenException>()),
    );

    final failed = analytics.recordedEventsForTesting.where(
      (event) => event['name'] == 'call_failed',
    );
    expect(failed.map((event) => event['failure_reason']), [
      'sign_in_required',
      'unconfigured',
      'invalid_name',
    ]);
    expect(failed.map((event) => event['role']), ['member', 'member', 'guest']);

    final appErrors = analytics.recordedEventsForTesting.where(
      (event) => event['name'] == 'app_error',
    );
    expect(appErrors, hasLength(3));
    expect(appErrors.every((event) => event['crashlytics_recorded'] == 0), isTrue);

    final blob = '${analytics.recordedEventsForTesting} ${errors.recordedErrorsForTesting}';
    expect(blob, isNot(contains(idToken)));
    expect(blob, isNot(contains(inviteToken)));
    expect(blob, isNot(contains('member@example.com')));
    expect(blob, isNot(contains('example.com')));
  });

  test('a guest invite rejection records invalid_invite and not the invite token', () async {
    const inviteToken = 'ccccccccccccccccccccccccccccccccccccccccccc';
    final guest = StreamGuestTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      inviteToken: inviteToken,
      callId: 'monthly',
      httpClient: MockClient(
        (request) async => http.Response(jsonEncode({'code': 'not-found'}), 404),
      ),
    );
    addTearDown(guest.close);

    await expectLater(
      guest.join(displayName: 'Fellow Member'),
      throwsA(isA<StreamTokenException>()),
    );

    final failed = analytics.recordedEventsForTesting.firstWhere(
      (event) => event['name'] == 'call_failed',
    );
    expect(failed['role'], 'guest');
    expect(failed['failure_reason'], 'invalid_invite');
    expect(errors.recordedErrorsForTesting.single['context'], {
      'area': 'group_call',
      'role': 'guest',
      'action': 'join_guest',
    });
    final blob = '${analytics.recordedEventsForTesting} ${errors.recordedErrorsForTesting}';
    expect(blob, isNot(contains(inviteToken)));
    expect(blob, isNot(contains('Fellow Member')));
  });

  test('a malformed token body and a thrown reader stay unavailable', () async {
    const leakedBody = 'not-json unit-test-stream-secret eyJhbGciOiJIUzI1NiJ9.aaa.bbb';
    final member = StreamTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      httpClient: MockClient((request) async => http.Response(leakedBody, 200)),
      readIdToken: () async => 'firebase-id-token',
    );
    addTearDown(member.close);
    await expectLater(
      member.mint(callId: 'monthly'),
      throwsA(
        isA<StreamTokenException>().having(
          (error) => error.message,
          'message',
          streamTokenUnavailableMessage,
        ),
      ),
    );

    const leakedReader = 'reader-failed eyJhbGciOiJIUzI1NiJ9.ccc.ddd';
    final reader = StreamTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      httpClient: MockClient((request) async => http.Response('{}', 200)),
      readIdToken: () async => throw StateError(leakedReader),
    );
    addTearDown(reader.close);
    await expectLater(reader.mint(callId: 'monthly'), throwsA(isA<StreamTokenException>()));

    const inviteToken = 'ddddddddddddddddddddddddddddddddddddddddddd';
    final guest = StreamGuestTokenClient(
      endpoint: Uri.parse('https://example.com/mint'),
      inviteToken: inviteToken,
      httpClient: MockClient((request) async => http.Response(leakedBody, 200)),
    );
    addTearDown(guest.close);
    await expectLater(
      guest.join(displayName: 'Fellow Member'),
      throwsA(isA<StreamTokenException>()),
    );

    final reasons = analytics.recordedEventsForTesting
        .where((event) => event['name'] == 'call_failed')
        .map((event) => event['failure_reason']);
    expect(reasons, ['unavailable', 'unavailable', 'unavailable']);
    expect(
      analytics.recordedEventsForTesting.where((event) => event['name'] == 'app_error'),
      hasLength(3),
    );
    final blob = '${analytics.recordedEventsForTesting} ${errors.recordedErrorsForTesting}';
    expect(blob, isNot(contains(leakedBody)));
    expect(blob, isNot(contains('unit-test-stream-secret')));
    expect(blob, isNot(contains('eyJ')));
    expect(blob, isNot(contains(leakedReader)));
    expect(blob, isNot(contains(inviteToken)));
    expect(blob, isNot(contains('Fellow Member')));
  });

  test('a refresh failure is marked before Stream hides the exception', () async {
    var marked = '';
    await expectLater(
      loadReplacementCallToken(
        mint: () async => throw const StreamTokenException(streamSignInRequiredMessage),
        onTokenFailure: (message) => marked = message,
      ),
      throwsA(isA<StreamTokenException>()),
    );
    expect(marked, streamSignInRequiredMessage);
    expect(analytics.recordedEventsForTesting, isEmpty);
  });

  test('media helpers record the toggle and a failure without a display name', () async {
    await reportCallMediaToggle(signedInMember: false, medium: 'microphone', enabled: true);
    await reportCallMediaFailure(signedInMember: true, failureReason: 'camera_unavailable');

    final toggle = analytics.recordedEventsForTesting.first;
    expect(toggle['name'], 'call_media_toggled');
    expect(toggle['role'], 'guest');
    expect(toggle['medium'], 'microphone');
    expect(toggle['enabled'], isTrue);

    final failed = analytics.recordedEventsForTesting[1];
    expect(failed['name'], 'call_failed');
    expect(failed['role'], 'member');
    expect(failed['failure_reason'], 'camera_unavailable');
    expect(errors.recordedErrorsForTesting.single['context'], {
      'area': 'group_call',
      'role': 'member',
      'action': 'camera',
    });
  });

  testWidgets('the call page records joined, left, and a connect failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StreamGroupCallPage(
          credentials: _guestCredentials(),
          displayName: 'Fellow Member',
          tokenClient: _SilentTokens(),
          openConnection: (_) async {},
        ),
      ),
    );
    await tester.pump();

    expect(analytics.recordedEventsForTesting.single['name'], 'call_joined');
    expect(analytics.recordedEventsForTesting.single['role'], 'guest');

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    final left = analytics.recordedEventsForTesting[1];
    expect(left['name'], 'call_left');
    expect(left['role'], 'guest');
    expect(left['duration_seconds'], isA<int>());
    expect(left['duration_seconds'] as int, greaterThanOrEqualTo(0));
    final joinedBlob = analytics.recordedEventsForTesting.toString();
    expect(joinedBlob, isNot(contains('aaa.bbb.ccc')));
    expect(joinedBlob, isNot(contains('Fellow Member')));
    expect(joinedBlob, isNot(contains('s' * 43)));
    expect(joinedBlob, isNot(contains('g${'a' * 32}')));

    analytics.recordedEventsForTesting.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: StreamGroupCallPage(
          credentials: const StreamCallCredentials(
            apiKey: 'public-key',
            token: 'ddd.eee.fff',
            userId: 'member1',
            callId: 'monthly',
            expiresAt: 30,
          ),
          displayName: 'Fellow Member',
          tokenClient: _SilentTokens(),
          openConnection: (_) async => throw StateError('socket closed'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final failed = analytics.recordedEventsForTesting.firstWhere(
      (event) => event['name'] == 'call_failed',
    );
    expect(failed['role'], 'member');
    expect(failed['failure_reason'], 'connect_failed');
    expect(find.text('The call could not connect.'), findsOneWidget);
    expect(find.textContaining('socket closed'), findsNothing);
    expect(analytics.recordedEventsForTesting.toString(), isNot(contains('ddd.eee.fff')));
    expect(analytics.recordedEventsForTesting.toString(), isNot(contains('socket')));
  });
}

StreamCallCredentials _guestCredentials() => StreamCallCredentials(
  apiKey: 'public-key',
  token: 'aaa.bbb.ccc',
  userId: 'g${'a' * 32}',
  callId: 'monthly',
  expiresAt: 30,
  role: 'guest',
  displayName: 'Fellow Member',
  seatKey: 's' * 43,
);

class _SilentTokens implements GroupCallTokenSource {
  @override
  Future<StreamCallCredentials> mint({required String callId}) async {
    throw const StreamTokenException('not used');
  }

  @override
  Future<void> release() async {}

  @override
  void close() {}
}
