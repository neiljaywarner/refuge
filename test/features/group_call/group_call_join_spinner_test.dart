import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_lobby.dart';

/// #977: Join call turns into a spinner while the token is minted, and a
/// second tap does not ask for a second token.
void main() {
  testWidgets(
    'Join call shows a spinner and ignores a second tap while joining',
    (tester) async {
      final gate = Completer<void>();
      var mints = 0;
      final httpClient = MockClient((request) async {
        mints++;
        await gate.future;
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
      await tester.pumpWidget(
        MaterialApp(
          home: GroupCallLobbyPage(
            displayName: 'Fellow Member',
            initialCallId: 'monthly',
            tokenClientFactory: () => StreamTokenClient(
              endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
              httpClient: httpClient,
              readIdToken: () async => 'id-token',
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

      const join = Key('group_call_confirm_join_button');
      await tester.tap(find.byKey(join));
      await tester.tap(find.byKey(join), warnIfMissed: false);
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(join),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(mints, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(mints, 1);
      expect(
        find.descendant(
          of: find.byKey(join),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('Join call shows a spinner when the name field is submitted', (
    tester,
  ) async {
    final gate = Completer<void>();
    var mints = 0;
    final httpClient = MockClient((request) async {
      mints++;
      await gate.future;
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
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallLobbyPage(
          displayName: 'Fellow Member',
          initialCallId: 'monthly',
          tokenClientFactory: () => StreamTokenClient(
            endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
            httpClient: httpClient,
            readIdToken: () async => 'id-token',
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

    const name = Key('group_call_name_field');
    const join = Key('group_call_confirm_join_button');
    await tester.enterText(find.byKey(name), 'monthly');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(join),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(mints, 1);

    await tester.tap(find.byKey(join), warnIfMissed: false);
    await tester.pump();
    expect(mints, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(mints, 1);
    expect(
      find.descendant(
        of: find.byKey(join),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  });
}
