import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_lobby.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_preview_banner.dart';

void main() {
  test('token response keeps the public key and drops a secret field', () {
    final credentials = parseStreamTokenResponse(
      jsonEncode({
        'apiKey': 'public-key',
        'token': 'aaa.bbb.ccc',
        'userId': 'member1',
        'expiresAt': 30,
      }),
      requestedCallId: 'monthly',
    );
    expect(credentials.apiKey, 'public-key');
    expect(credentials.userId, 'member1');
    expect(credentials.callId, 'monthly');

    expect(
      () => parseStreamTokenResponse(
        jsonEncode({
          'apiKey': 'public-key',
          'token': 'aaa.bbb.ccc',
          'userId': 'member1',
          'secret': 'nope',
        }),
        requestedCallId: 'monthly',
      ),
      throwsA(isA<StreamTokenException>()),
    );
  });

  testWidgets('join asks for a user token and does not send a secret', (tester) async {
    String? body;
    final httpClient = MockClient((request) async {
      body = request.body;
      expect(request.headers['Authorization'], 'Bearer firebase-id-token');
      return http.Response(
        jsonEncode({
          'apiKey': 'public-key',
          'token': 'aaa.bbb.ccc',
          'userId': 'member1',
          'callId': 'monthly',
          'expiresAt': 30,
        }),
        200,
      );
    });
    StreamCallCredentials? handedOff;
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          tokenClientFactory: () => StreamTokenClient(
            endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
            httpClient: httpClient,
            readIdToken: () async => 'firebase-id-token',
          ),
          onReady:
              (
                context, {
                required room,
                required credentials,
                required displayName,
                required tokenClient,
              }) async {
                handedOff = credentials;
                expect(room.id, 'monthly');
                expect(displayName, 'Fellow Member');
              },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('group_call_confirm_join_button')));
    await tester.pump();
    await tester.pump();

    expect(body, '{"callId":"monthly"}');
    expect(body, isNot(contains('secret')));
    expect(handedOff?.apiKey, 'public-key');
  });

  testWidgets('the home entry opens the lobby', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroupCallPreviewBanner(initialCallId: 'monthly', displayName: 'Fellow Member'),
        ),
      ),
    );
    expect(find.text('Join call'), findsOneWidget);
    await tester.tap(find.byKey(const Key('group_call_join_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group_call_name_field')), findsOneWidget);
    expect(find.text('Group call'), findsOneWidget);
  });

  test('guest mode does not call the token function', () async {
    var called = false;
    final client = StreamTokenClient(
      endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
      httpClient: MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      }),
      readIdToken: () async => null,
    );
    addTearDown(client.close);
    await expectLater(
      client.mint(callId: 'monthly'),
      throwsA(
        isA<StreamTokenException>().having(
          (error) => error.message,
          'message',
          streamSignInRequiredMessage,
        ),
      ),
    );
    expect(called, isFalse);
  });

  test('mint hides a secret in an auth, setup, or other failure', () async {
    const leaked = 'unit-test-stream-secret';
    Future<void> expectStatus(int status, String message) async {
      final client = StreamTokenClient(
        endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
        httpClient: MockClient((request) async => http.Response('{"secret":"$leaked"}', status)),
        readIdToken: () async => 'firebase-id-token',
      );
      addTearDown(client.close);
      await expectLater(
        client.mint(callId: 'monthly'),
        throwsA(
          isA<StreamTokenException>()
              .having((error) => error.message, 'message', message)
              .having((error) => error.message, 'message', isNot(contains(leaked))),
        ),
      );
    }

    await expectStatus(401, streamSignInRequiredMessage);
    await expectStatus(503, 'Video calling is not configured on this preview yet.');
    await expectStatus(500, 'The call could not start. Try again in a moment.');
  });

  testWidgets('a too-short call name stays on the lobby', (tester) async {
    var minted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          tokenClientFactory: () {
            minted = true;
            return null;
          },
          onReady: (
            context, {
            required room,
            required credentials,
            required displayName,
            required tokenClient,
          }) async {},
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('group_call_name_field')), 'ab');
    await tester.tap(find.byKey(const Key('group_call_confirm_join_button')));
    await tester.pump();
    expect(minted, isFalse);
    expect(
      find.text('Use a short name like monthly. Letters, numbers, and single dashes.'),
      findsOneWidget,
    );
  });

  testWidgets('a preview without a token address explains the missing endpoint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          tokenClientFactory: () => null,
          onReady:
              (
                context, {
                required room,
                required credentials,
                required displayName,
                required tokenClient,
              }) async {
                fail('should not join');
              },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('group_call_confirm_join_button')));
    await tester.pump();
    expect(
      find.text(
        'This preview build has no token address yet. '
        'An operator sets STREAM_TOKEN_ENDPOINT when building the preview.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a member can create a guest link and revoke it', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final invite = 'b' * 43;
    final bodies = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          pageLocation: Uri.parse('https://preview.example/hall'),
          tokenClientFactory: () => StreamTokenClient(
            endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
            httpClient: MockClient((request) async {
              final payload = jsonDecode(request.body) as Map<String, dynamic>;
              bodies.add(payload);
              expect(request.headers['Authorization'], 'Bearer firebase-id-token');
              expect(request.body, isNot(contains('unit-test-stream-secret')));
              if (payload['action'] == 'revokeInvite') {
                return http.Response(jsonEncode({'revoked': true, 'callId': 'monthly'}), 200);
              }
              return http.Response(
                jsonEncode({
                  'inviteToken': invite,
                  'callId': 'monthly',
                  'expiresAt': 30,
                  'guestLimit': 10,
                }),
                200,
              );
            }),
            readIdToken: () async => 'firebase-id-token',
          ),
          onReady:
              (
                context, {
                required room,
                required credentials,
                required displayName,
                required tokenClient,
              }) async {
                fail('join should not run');
              },
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('group_call_invite_button')));
    await tester.tap(find.byKey(const Key('group_call_invite_button')));
    await tester.pumpAndSettle();

    expect(bodies.single['action'], 'createInvite');
    expect(bodies.single['callId'], 'monthly');
    expect(find.text('https://preview.example/hall?call=monthly&invite=$invite'), findsOneWidget);
    expect(find.textContaining('unit-test-stream-secret'), findsNothing);
    expect(find.textContaining('10 guests'), findsWidgets);

    await tester.tap(find.byKey(Key('group_call_revoke_invite_$invite')));
    await tester.pumpAndSettle();
    expect(find.text('Revoke this guest link?'), findsOneWidget);
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();

    expect(bodies.last['action'], 'revokeInvite');
    expect(bodies.last['inviteToken'], invite);
    expect(find.text('https://preview.example/hall?call=monthly&invite=$invite'), findsNothing);
    expect(find.text('This link no longer works.'), findsOneWidget);
  });

  testWidgets('a second guest link stays listed until the member revokes the call', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bodies = <Map<String, dynamic>>[];
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          pageLocation: Uri.parse('https://preview.example/hall'),
          tokenClientFactory: () => StreamTokenClient(
            endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
            httpClient: MockClient((request) async {
              final payload = jsonDecode(request.body) as Map<String, dynamic>;
              bodies.add(payload);
              if (payload['action'] == 'revokeMyInvites') {
                return http.Response(jsonEncode({'revoked': 2, 'callId': 'monthly'}), 200);
              }
              created += 1;
              final invite = created == 1 ? 'b' * 43 : 'c' * 43;
              return http.Response(
                jsonEncode({
                  'inviteToken': invite,
                  'callId': 'monthly',
                  'expiresAt': 30,
                  'guestLimit': 10,
                }),
                200,
              );
            }),
            readIdToken: () async => 'firebase-id-token',
          ),
          onReady: (
            context, {
            required room,
            required credentials,
            required displayName,
            required tokenClient,
          }) async {},
        ),
      ),
    );

    final inviteButton = find.byKey(const Key('group_call_invite_button'));
    await tester.ensureVisible(inviteButton);
    await tester.tap(inviteButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(inviteButton);
    await tester.tap(inviteButton);
    await tester.pumpAndSettle();

    expect(
      find.text('https://preview.example/hall?call=monthly&invite=${'b' * 43}'),
      findsOneWidget,
    );
    expect(
      find.text('https://preview.example/hall?call=monthly&invite=${'c' * 43}'),
      findsOneWidget,
    );

    final revokeAll = find.byKey(const Key('group_call_revoke_my_links_button'));
    await tester.ensureVisible(revokeAll);
    await tester.tap(revokeAll);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();

    expect(bodies.last['action'], 'revokeMyInvites');
    expect(bodies.last['callId'], 'monthly');
    expect(bodies.last.containsKey('inviteToken'), isFalse);
    expect(find.textContaining('invite='), findsNothing);
    expect(find.text('Your guest links for this call no longer work.'), findsOneWidget);
  });
}
