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
}
