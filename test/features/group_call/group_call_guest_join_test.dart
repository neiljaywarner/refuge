import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/auth_gate.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_guest_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/guest_display_name.dart';
import 'package:refuge4serverpod/src/features/group_call/domain/stream_call_credentials.dart';
import 'package:refuge4serverpod/src/features/group_call/presentation/group_call_guest_join_page.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/presentation/sensory_theme_controller.dart';

void main() {
  const invite = 'ccccccccccccccccccccccccccccccccccccccccccc';

  test('guest names match the server checks', () {
    expect(sanitizeGuestDisplayName('  Alex   R  '), 'Alex R');
    expect(sanitizeGuestDisplayName(''), isNull);
    expect(sanitizeGuestDisplayName('Alex\nR'), isNull);
    expect(sanitizeGuestDisplayName('a' * 41), isNull);
    expect(sanitizeGuestDisplayName('member@belongonthespectrum.com'), isNull);
    expect(sanitizeGuestDisplayName('https://example.com/join'), isNull);
    expect(sanitizeGuestDisplayName('www.example.com'), isNull);
  });

  test('a guest response that claims host powers is refused', () {
    expect(
      () => parseStreamTokenResponse(
        jsonEncode({
          'apiKey': 'public-key',
          'token': 'aaa.bbb.ccc',
          'userId': 'g${'a' * 32}',
          'callId': 'monthly',
          'expiresAt': 30,
          'actor': 'guest',
          'callRole': 'host',
          'displayName': 'Alex',
          'canModerate': false,
        }),
        requestedCallId: 'monthly',
      ),
      throwsA(isA<StreamTokenException>()),
    );
    expect(
      () => parseStreamTokenResponse(
        jsonEncode({
          'apiKey': 'public-key',
          'token': 'aaa.bbb.ccc',
          'userId': 'g${'a' * 32}',
          'callId': 'monthly',
          'expiresAt': 30,
          'actor': 'guest',
          'callRole': 'call-member',
          'displayName': 'Alex',
          'canModerate': true,
        }),
        requestedCallId: 'monthly',
      ),
      throwsA(isA<StreamTokenException>()),
    );
  });

  testWidgets('a guest types a name and joins without a Firebase token', (
    tester,
  ) async {
    Map<String, dynamic>? payload;
    String? authorization;
    StreamCallCredentials? handedOff;
    await tester.pumpWidget(
      MaterialApp(
        home: GroupCallGuestJoinPage(
          inviteToken: invite,
          callId: 'monthly',
          tokenClientFactory: () => StreamGuestTokenClient(
            endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
            inviteToken: invite,
            callId: 'monthly',
            httpClient: MockClient((request) async {
              payload = jsonDecode(request.body) as Map<String, dynamic>;
              authorization = request.headers['Authorization'];
              return http.Response(
                jsonEncode({
                  'apiKey': 'public-key',
                  'token': 'aaa.bbb.ccc',
                  'userId': 'g${'d' * 32}',
                  'callId': 'monthly',
                  'expiresAt': 30,
                  'actor': 'guest',
                  'callRole': 'call-member',
                  'displayName': 'Alex',
                  'canModerate': false,
                }),
                200,
              );
            }),
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
                expect(displayName, 'Alex');
                expect(credentials.isGuest, isTrue);
              },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      '  Alex  ',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    await tester.pump();

    expect(payload?['action'], 'joinGuest');
    expect(payload?['displayName'], 'Alex');
    expect(payload?['inviteToken'], invite);
    expect(payload?['callId'], 'monthly');
    expect(payload?.containsKey('role'), isFalse);
    expect(authorization, isNull);
    expect(handedOff?.isGuest, isTrue);
    expect(handedOff?.role, 'guest');
    expect(find.textContaining('unit-test-stream-secret'), findsNothing);
  });

  testWidgets('an email, a link, or a full call do not join', (tester) async {
    var called = false;
    Widget page() => MaterialApp(
      home: GroupCallGuestJoinPage(
        inviteToken: invite,
        callId: 'monthly',
        tokenClientFactory: () => StreamGuestTokenClient(
          endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
          inviteToken: invite,
          callId: 'monthly',
          httpClient: MockClient((request) async {
            called = true;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (body['displayName'] == 'Alex') {
              return http.Response(
                jsonEncode({'code': 'cap', 'error': 'unit-test-stream-secret'}),
                409,
              );
            }
            return http.Response('{}', 500);
          }),
        ),
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
    );

    await tester.pumpWidget(page());
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'member@belongonthespectrum.com',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    expect(called, isFalse);
    expect(
      find.text('Use a short name. Leave out email addresses and web links.'),
      findsOneWidget,
    );
    expect(find.textContaining(invite), findsNothing);

    await tester.pumpWidget(page());
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'Alex',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    await tester.pump();
    expect(called, isTrue);
    expect(
      find.text(
        'This call already has 10 guests. Try again after someone leaves.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('unit-test-stream-secret'), findsNothing);
    expect(find.textContaining(invite), findsNothing);
  });

  testWidgets('an invite link opens the name page and a call name does not', (
    tester,
  ) async {
    final themes = ThemeNotifier();
    addTearDown(themes.dispose);
    final repository = LocalPostRepository();

    Future<void> pump(Uri location, {required bool preview}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
            appFlavorProvider.overrideWithValue(AppFlavor.dev),
          ],
          child: MaterialApp(
            home: AuthGate(
              repository: repository,
              themeNotifier: themes,
              groupCallPreviewCompiled: preview,
              groupCallLocation: location,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pump(
      Uri.parse('https://preview.example/?call=monthly&invite=$invite'),
      preview: true,
    );
    expect(find.byKey(const Key('group_call_guest_join_page')), findsOneWidget);
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsNothing);
    expect(find.text('You are joining monthly.'), findsOneWidget);
    expect(find.textContaining(invite), findsNothing);

    await pump(
      Uri.parse('https://preview.example/?call=monthly'),
      preview: true,
    );
    expect(find.byKey(const Key('group_call_guest_name_field')), findsNothing);
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);

    await pump(
      Uri.parse('https://preview.example/?call=monthly&invite=$invite'),
      preview: false,
    );
    expect(find.byKey(const Key('group_call_guest_join_page')), findsNothing);
    expect(find.byKey(const Key('auth_gate_sign_in_wall')), findsOneWidget);
  });

  testWidgets('a failed handoff releases the seat before the client closes', (
    tester,
  ) async {
    final client = _ScriptedGuestClient(
      onJoin: () async => StreamCallCredentials(
        apiKey: 'public-key',
        token: 'aaa.bbb.ccc',
        userId: 'g${'d' * 32}',
        callId: 'no',
        expiresAt: 30,
        role: 'guest',
        displayName: 'Alex',
      ),
    );
    var handedOff = false;
    await tester.pumpWidget(
      _guestPage(client: client, onHandOff: () => handedOff = true),
    );
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'Alex',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    await tester.pump();

    expect(handedOff, isFalse);
    expect(client.order, ['release', 'close']);
    expect(
      find.text('The call could not start. Try again in a moment.'),
      findsOneWidget,
    );
  });

  testWidgets('a join error releases the seat before the client closes', (
    tester,
  ) async {
    final client = _ScriptedGuestClient(
      onJoin: () async =>
          throw const StreamTokenException('This invite link is not valid.'),
    );
    await tester.pumpWidget(_guestPage(client: client));
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'Alex',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    await tester.pump();

    expect(client.order, ['release', 'close']);
    expect(find.text('This invite link is not valid.'), findsOneWidget);
    expect(find.textContaining(invite), findsNothing);
  });

  testWidgets('a handed-off guest join does not release the seat', (
    tester,
  ) async {
    final client = _ScriptedGuestClient(
      onJoin: () async => StreamCallCredentials(
        apiKey: 'public-key',
        token: 'aaa.bbb.ccc',
        userId: 'g${'d' * 32}',
        callId: 'monthly',
        expiresAt: 30,
        role: 'guest',
        displayName: 'Alex',
      ),
    );
    var handedOff = false;
    await tester.pumpWidget(
      _guestPage(client: client, onHandOff: () => handedOff = true),
    );
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'Alex',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();
    await tester.pump();

    expect(handedOff, isTrue);
    expect(client.order, isEmpty);
  });

  testWidgets('an abandoned join releases the claimed seat', (tester) async {
    final gate = Completer<http.Response>();
    final bodies = <Map<String, dynamic>>[];
    final userId = 'g${'e' * 32}';
    final client = _RecordingGuestClient(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        bodies.add(body);
        if (body['action'] == 'joinGuest') return gate.future;
        return http.Response(jsonEncode({'released': true}), 200);
      }),
    );

    await tester.pumpWidget(_guestPage(client: client));
    await tester.enterText(
      find.byKey(const Key('group_call_guest_name_field')),
      'Alex',
    );
    await tester.tap(find.byKey(const Key('group_call_guest_join_button')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    gate.complete(
      http.Response(
        jsonEncode({
          'apiKey': 'public-key',
          'token': 'aaa.bbb.ccc',
          'userId': userId,
          'callId': 'monthly',
          'expiresAt': 30,
          'actor': 'guest',
          'callRole': 'call-member',
          'displayName': 'Alex',
          'canModerate': false,
        }),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(bodies.map((body) => body['action']), ['joinGuest', 'releaseGuest']);
    expect(bodies.last['guestUserId'], userId);
    expect(bodies.last['inviteToken'], invite);
    expect(client.order, ['release', 'close']);
    expect(jsonEncode(bodies).contains('unit-test-stream-secret'), isFalse);
  });
}

Widget _guestPage({
  required StreamGuestTokenClient client,
  VoidCallback? onHandOff,
}) => MaterialApp(
  home: GroupCallGuestJoinPage(
    inviteToken: inviteToken,
    callId: 'monthly',
    tokenClientFactory: () => client,
    onReady:
        (
          context, {
          required room,
          required credentials,
          required displayName,
          required tokenClient,
        }) async {
          onHandOff?.call();
        },
  ),
);

/// The invite used by the guest join page tests.
const String inviteToken = 'ccccccccccccccccccccccccccccccccccccccccccc';

class _ScriptedGuestClient extends StreamGuestTokenClient {
  _ScriptedGuestClient({required this.onJoin})
    : super(
        endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
        inviteToken: inviteToken,
        callId: 'monthly',
        httpClient: MockClient((request) async => http.Response('{}', 500)),
      );

  final Future<StreamCallCredentials> Function() onJoin;
  final List<String> order = [];

  @override
  Future<StreamCallCredentials> join({required String displayName}) => onJoin();

  @override
  Future<void> release() async {
    order.add('release');
    await super.release();
  }

  @override
  void close() {
    order.add('close');
    super.close();
  }
}

class _RecordingGuestClient extends StreamGuestTokenClient {
  _RecordingGuestClient({required super.httpClient})
    : super(
        endpoint: Uri.parse('https://example.com/mintStreamCallToken'),
        inviteToken: inviteToken,
        callId: 'monthly',
      );

  final List<String> order = [];

  @override
  Future<void> release() async {
    order.add('release');
    await super.release();
  }

  @override
  void close() {
    order.add('close');
    super.close();
  }
}
