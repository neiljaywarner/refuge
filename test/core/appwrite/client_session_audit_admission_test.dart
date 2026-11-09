import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_admission.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 11, 8, 17);

  group('admitted start row', () {
    test('keeps a clean row and rejects smuggled fields', () {
      final row = admittedStartRow(_cleanRow(), now);
      expect(row, isNotNull);
      expect(row!.keys, everyElement(isIn(sessionAuditRowKeys)));
      expect(row['city'], 'US');
      expect(row.containsKey('uid'), isFalse);

      expect(admittedStartRow({..._cleanRow(), 'uid': 'member-1'}, now), isNull);
      expect(admittedStartRow({..._cleanRow(), 'city': 'tester@example.com'}, now), isNull);
      expect(admittedStartRow({..._cleanRow(), 'city': '203.0.113.10'}, now), isNull);
      expect(admittedStartRow({..._cleanRow(), 'city': '2001:db8::1'}, now), isNull);
      expect(admittedStartRow({..._cleanRow(), 'city': 'peer 2001:db8:0:0:0:0:0:1'}, now), isNull);
      expect(sessionAuditLooksLikeIpv6('peer 2001:db8:0:0:0:0:0:1'), isTrue);
      expect(sessionAuditLooksLikeIpv6('Chicago'), isFalse);
      expect(admittedStartRow({..._cleanRow(), 'platform': 'Android'}, now), isNull);
      expect(admittedStartRow({..._cleanRow(), 'appVersion': 'x' * 33}, now), isNull);
      expect(
        admittedStartRow({..._cleanRow(), 'sessionStartedAt': '2026-11-01T00:00:00.000Z'}, now),
        isNull,
      );
      expect(admittedStartRow({..._cleanRow(), 'timezone': 1}, now), isNull);
    });

    test('accepts a UTC offset label', () {
      final row = admittedStartRow({..._cleanRow(), 'timezone': 'UTC+00:00'}, now);
      expect(row?['timezone'], 'UTC+00:00');
    });
  });

  group('caller identity', () {
    test('uses the direct address unless that peer is an explicit trusted proxy', () {
      expect(
        sessionAuditCallerAddress(directAddress: '203.0.113.10', forwardedFor: '198.51.100.4'),
        '203.0.113.10',
      );
      expect(
        sessionAuditCallerAddress(
          directAddress: '10.0.0.2',
          forwardedFor: '198.51.100.1, 203.0.113.50',
          trustedProxies: {'10.0.0.2'},
        ),
        '203.0.113.50',
      );
      final first = sessionAuditCallerAddress(
        directAddress: '10.0.0.2',
        forwardedFor: '203.0.113.8',
        trustedProxies: {'10.0.0.2'},
      );
      final second = sessionAuditCallerAddress(
        directAddress: '10.0.0.2',
        forwardedFor: '203.0.113.9',
        trustedProxies: {'10.0.0.2'},
      );
      expect(first, isNot(second));
    });
  });

  group('admission slots', () {
    test('refuses another entry while the cap is held, then accepts after leave', () {
      expect(sessionAuditMaxInFlight, 8);
      final slots = SessionAuditInflight(maxInFlight: 2);
      expect(slots.tryEnter(), isTrue);
      expect(slots.tryEnter(), isTrue);
      expect(slots.tryEnter(), isFalse);
      expect(slots.active, 2);
      slots.leave();
      expect(slots.tryEnter(), isTrue);
      expect(slots.active, 2);
    });
  });

  group('rate gate', () {
    test('stops one caller without blocking a different caller', () {
      final gate = SessionAuditRateGate(
        perCallerLimit: 2,
        projectBurstLimit: 10,
        projectDailyLimit: 10,
      );
      expect(gate.tryConsume('a', now: now), isTrue);
      expect(gate.tryConsume('a', now: now), isTrue);
      expect(gate.tryConsume('a', now: now), isFalse);
      expect(gate.tryConsume('b', now: now), isTrue);
    });

    test('enforces the project burst and the rolling day', () {
      final burst = SessionAuditRateGate(
        perCallerLimit: 10,
        projectBurstLimit: 2,
        projectDailyLimit: 10,
      );
      expect(burst.tryConsume('a', now: now), isTrue);
      expect(burst.tryConsume('b', now: now), isTrue);
      expect(burst.tryConsume('c', now: now), isFalse);

      final daily = SessionAuditRateGate(
        perCallerLimit: 10,
        projectBurstLimit: 10,
        projectDailyLimit: 2,
      );
      expect(daily.tryConsume('a', now: now), isTrue);
      expect(daily.tryConsume('b', now: now), isTrue);
      expect(daily.tryConsume('c', now: now), isFalse);
    });

    test('forgets hits outside the caller window and caps distinct keys', () {
      final gate = SessionAuditRateGate(
        perCallerLimit: 1,
        perCallerWindow: const Duration(hours: 1),
        projectBurstLimit: 10,
        projectDailyLimit: 10,
        maxCallerKeys: 1,
      );
      expect(gate.tryConsume('a', now: now), isTrue);
      expect(gate.tryConsume('b', now: now), isFalse);
      final later = now.add(const Duration(hours: 1, seconds: 1));
      expect(gate.tryConsume('b', now: later), isTrue);
    });
  });

  group('admission', () {
    late _Writer writer;
    late SessionAuditAdmission admission;

    setUp(() {
      writer = _Writer();
      admission = SessionAuditAdmission(
        gate: SessionAuditRateGate(),
        tokens: _Tokens(),
        writer: writer,
        clock: () => now,
      );
    });

    test('writes only the sanitized row and returns an end token', () async {
      final reply = await admission.handle(
        body: {'action': 'start', 'row': _cleanRow()},
        callerKey: 'caller-a',
      );
      expect(reply.status, 200);
      expect(writer.creates, 1);
      expect(writer.last!.keys, everyElement(isIn(sessionAuditRowKeys)));
      expect(writer.last!.containsKey('email'), isFalse);
      expect(reply.body['rowId'], 'row1');
      expect(reply.body['endToken'], 'tok-row1');
    });

    test('does not write when the body is hostile or over budget', () async {
      final hostile = await admission.handle(
        body: {
          'action': 'start',
          'row': {..._cleanRow(), 'email': 'member@example.com'},
        },
        callerKey: 'caller-a',
      );
      expect(hostile.status, 400);
      expect(writer.creates, 0);

      final limited = SessionAuditAdmission(
        gate: SessionAuditRateGate(perCallerLimit: 1, projectBurstLimit: 1, projectDailyLimit: 1),
        tokens: _Tokens(),
        writer: writer,
        clock: () => now,
      );
      expect(
        (await limited.handle(
          body: {'action': 'start', 'row': _cleanRow()},
          callerKey: 'a',
        )).status,
        200,
      );
      final blocked = await limited.handle(
        body: {'action': 'start', 'row': _cleanRow()},
        callerKey: 'a',
      );
      expect(blocked.status, 429);
      expect(writer.creates, 1);
    });

    test('refuses to write when the server credential is absent', () async {
      final offline = SessionAuditAdmission(
        gate: SessionAuditRateGate(),
        tokens: _Tokens(),
        clock: () => now,
      );
      final reply = await offline.handle(
        body: {'action': 'start', 'row': _cleanRow()},
        callerKey: 'caller-a',
      );
      expect(reply.status, 503);
      expect(writer.creates, 0);
    });

    test('ends one row when the token matches and only sends the end time', () async {
      final started = await admission.handle(
        body: {'action': 'start', 'row': _cleanRow()},
        callerKey: 'caller-a',
      );
      final ended = await admission.handle(
        body: {
          'action': 'end',
          'rowId': started.body['rowId'],
          'endToken': started.body['endToken'],
          'sessionEndedAt': '2026-11-08T17:04:00.000Z',
          'city': 'secret',
        },
        callerKey: 'caller-a',
      );
      expect(ended.status, 400);
      expect(writer.ends, 0);

      final ok = await admission.handle(
        body: {
          'action': 'end',
          'rowId': 'row1',
          'endToken': 'tok-row1',
          'sessionEndedAt': '2026-11-08T17:04:00.000Z',
        },
        callerKey: 'caller-a',
      );
      expect(ok.status, 200);
      expect(writer.ends, 1);
      expect(writer.endedAt, '2026-11-08T17:04:00.000Z');

      final forged = await admission.handle(
        body: {
          'action': 'end',
          'rowId': 'row1',
          'endToken': 'tok-other',
          'sessionEndedAt': '2026-11-08T17:04:00.000Z',
        },
        callerKey: 'caller-a',
      );
      expect(forged.status, 400);
      expect(writer.ends, 1);
    });

    test('a failed write does not look like success', () async {
      writer.error = StateError('down');
      final reply = await admission.handle(
        body: {'action': 'start', 'row': _cleanRow()},
        callerKey: 'caller-a',
      );
      expect(reply.status, 502);
      expect(reply.body['rowId'], isNull);
    });
  });
}

Map<String, Object> _cleanRow() => {
  'timezone': 'UTC',
  'osName': 'ios',
  'appVersion': '0.9.2',
  'platform': 'ios',
  'sessionStartedAt': '2026-11-08T17:00:00.000Z',
  'city': 'US',
  'locale': 'en-US',
  'osVersion': '17',
  'appBuild': '2',
};

class _Tokens implements SessionAuditEndTokens {
  @override
  String issue(String rowId) => 'tok-$rowId';

  @override
  bool accepts({required String rowId, required String token}) => token == 'tok-$rowId';
}

class _Writer implements SessionAuditRowWriter {
  int creates = 0;
  int ends = 0;
  Map<String, Object>? last;
  String? endedAt;
  Object? error;

  @override
  Future<String> createRow(Map<String, Object> data) async {
    creates += 1;
    last = data;
    final failure = error;
    if (failure != null) throw failure;
    return 'row1';
  }

  @override
  Future<void> markEnded({required String rowId, required String sessionEndedAt}) async {
    ends += 1;
    endedAt = sessionEndedAt;
    final failure = error;
    if (failure != null) throw failure;
  }
}
