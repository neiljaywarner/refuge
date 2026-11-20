import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_guest_token_client.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_token_client.dart';

/// Guest mint, seat refresh, and the function's error sentences.
///
/// The HTTP client is a [MockClient]. No live token endpoint is called, and
/// the bodies use a public key placeholder rather than a secret.
void main() {
  const invite = 'iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii';
  const seatKey = 'sssssssssssssssssssssssssssssssssssssssssss';
  final endpoint = Uri.parse('https://example.com/mintStreamCallToken');

  Map<String, Object?> guestBody({String callId = 'monthly', String? seat = seatKey}) => {
    'apiKey': 'public-key',
    'token': 'aaa.bbb.ccc',
    'userId': 'g${'d' * 32}',
    'callId': callId,
    'expiresAt': 30,
    'actor': 'guest',
    'callRole': 'call-member',
    'displayName': 'Alex',
    'canModerate': false,
    'seatKey': ?seat,
  };

  StreamGuestTokenClient client(MockClient handler, {String? callId = 'monthly'}) =>
      StreamGuestTokenClient(
        endpoint: endpoint,
        inviteToken: invite,
        callId: callId,
        httpClient: handler,
      );

  test('join stores the seat and a later mint keeps that same seat', () async {
    final bodies = <Map<String, dynamic>>[];
    final guest = client(
      MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        final action = bodies.last['action'];
        return http.Response(jsonEncode(guestBody()), action == 'releaseGuest' ? 204 : 200);
      }),
    );

    final joined = await guest.join(displayName: '  Alex  ');
    expect(joined.seatKey, seatKey);
    expect(joined.isGuest, isTrue);
    expect(bodies.single['guestUserId'], isNull);
    expect(bodies.single.containsKey('seatKey'), isFalse);

    final refreshed = await guest.mint(callId: 'monthly');
    expect(refreshed.seatKey, seatKey);
    expect(bodies.last['action'], 'joinGuest');
    expect(bodies.last['guestUserId'], joined.userId);
    expect(bodies.last['seatKey'], seatKey);
    expect(bodies.last['displayName'], 'Alex');

    await guest.release();
    expect(bodies.last['action'], 'releaseGuest');
    expect(bodies.last['seatKey'], seatKey);
    guest.close();
  });

  test('mint before a name, or for another call, does not take a seat', () async {
    final guest = client(MockClient((request) async => http.Response('{}', 500)));

    expect(
      () => guest.mint(callId: 'monthly'),
      throwsA(
        isA<StreamTokenException>().having(
          (error) => error.message,
          'message',
          streamTokenUnavailableMessage,
        ),
      ),
    );
    guest.close();

    final joined = client(
      MockClient((request) async => http.Response(jsonEncode(guestBody()), 200)),
    );
    await joined.join(displayName: 'Alex');
    expect(
      () => joined.mint(callId: 'other-room'),
      throwsA(
        isA<StreamTokenException>().having(
          (error) => error.message,
          'message',
          'This invite link is for a different call.',
        ),
      ),
    );
    joined.close();
  });

  test('a closed client and a failed release still let the person leave', () async {
    var posts = 0;
    final guest = client(
      MockClient((request) async {
        posts += 1;
        if (posts == 1) return http.Response(jsonEncode(guestBody()), 200);
        throw http.ClientException('offline');
      }),
    );
    await guest.join(displayName: 'Alex');
    await guest.release();
    guest.close();
    guest.close();
    await expectLater(guest.mint(callId: 'monthly'), throwsA(isA<StreamTokenException>()));
    await guest.release();
  });

  test('an empty seat, a member-shaped body, or a dropped connection is refused', () async {
    Future<void> expectJoin(MockClient handler) async {
      final guest = client(handler, callId: null);
      await expectLater(guest.join(displayName: 'Alex'), throwsA(isA<StreamTokenException>()));
      guest.close();
    }

    await expectJoin(
      MockClient((request) async => http.Response(jsonEncode(guestBody(seat: '')), 200)),
    );
    await expectJoin(
      MockClient(
        (request) async => http.Response(
          jsonEncode({
            'apiKey': 'public-key',
            'token': 'aaa.bbb.ccc',
            'userId': 'member-1',
            'expiresAt': 30,
          }),
          200,
        ),
      ),
    );
    await expectJoin(MockClient((request) async => throw http.ClientException('offline')));
    await expectJoin(
      MockClient(
        (request) async => http.Response(jsonEncode({'apiSecret': 'not-a-real-secret'}), 500),
      ),
    );
  });

  test('function error codes become calm sentences and hide the body', () async {
    const sentences = {
      'name': 'Use a short name. Leave out email addresses and web links.',
      'not-found': 'This invite link is not valid.',
      'expired': 'This invite link has expired or was revoked.',
      'revoked': 'This invite link has expired or was revoked.',
      'cap': 'This call already has 10 guests. Try again after someone leaves.',
      'mismatch': 'This invite link is for a different call.',
      'seat': 'This invite link is not valid for that seat. Open the link again.',
      'rate': 'Too many join attempts. Wait a few minutes and try the link again.',
      'unconfigured': streamVideoUnconfiguredMessage,
      'room': 'The call could not be prepared. Try again in a moment.',
    };

    for (final entry in sentences.entries) {
      final guest = client(
        MockClient(
          (request) async =>
              http.Response(jsonEncode({'code': entry.key, 'error': 'not-a-real-secret'}), 418),
        ),
        callId: null,
      );
      await expectLater(
        guest.join(displayName: 'Alex'),
        throwsA(
          isA<StreamTokenException>().having((error) => error.message, 'message', entry.value),
        ),
      );
      guest.close();
    }
  });

  test('status codes without a code still map to the same sentences', () async {
    const byStatus = {
      400: 'Use a short name. Leave out email addresses and web links.',
      404: 'This invite link is not valid.',
      410: 'This invite link has expired or was revoked.',
      409: 'This call already has 10 guests. Try again after someone leaves.',
      429: 'Too many join attempts. Wait a few minutes and try the link again.',
      403: 'This invite link is for a different call.',
      503: streamVideoUnconfiguredMessage,
      500: streamTokenUnavailableMessage,
    };

    for (final entry in byStatus.entries) {
      final guest = client(
        MockClient((request) async => http.Response('not-json', entry.key)),
        callId: null,
      );
      await expectLater(
        guest.join(displayName: 'Alex'),
        throwsA(
          isA<StreamTokenException>().having((error) => error.message, 'message', entry.value),
        ),
      );
      guest.close();
    }
  });

  test('a local name check runs before any request', () async {
    var called = false;
    final guest = client(
      MockClient((request) async {
        called = true;
        return http.Response('{}', 500);
      }),
    );
    await expectLater(
      guest.join(displayName: 'https://example.com/join'),
      throwsA(isA<StreamTokenException>()),
    );
    expect(called, isFalse);
    expect(guest, isA<GroupCallTokenSource>());
    guest.close();
  });
}
