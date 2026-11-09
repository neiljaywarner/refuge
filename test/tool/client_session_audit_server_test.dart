import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_admission.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_snapshot.dart';

import '../../tool/client_session_audit_server.dart';

void main() {
  const salt = [1, 2, 3, 4];
  const secret = 'test-key-not-a-real-secret';

  group('server policy', () {
    test('a trusted proxy splits budgets and an untrusted peer does not', () {
      const proxies = {'10.0.0.2'};
      final first = sessionAuditCallerKey(
        sessionAuditCallerAddress(
          directAddress: '10.0.0.2',
          forwardedFor: '203.0.113.8',
          trustedProxies: proxies,
        ),
        salt,
      );
      final second = sessionAuditCallerKey(
        sessionAuditCallerAddress(
          directAddress: '10.0.0.2',
          forwardedFor: '203.0.113.9',
          trustedProxies: proxies,
        ),
        salt,
      );
      final ignored = sessionAuditCallerAddress(
        directAddress: '203.0.113.10',
        forwardedFor: '198.51.100.4',
        trustedProxies: proxies,
      );
      expect(first, isNot(second));
      expect(first.contains('203.0.113.8'), isFalse);
      expect(ignored, '203.0.113.10');
      expect(sessionAuditTrustedProxiesFromEnvironment(const {}), isEmpty);
      expect(
        sessionAuditTrustedProxiesFromEnvironment({
          'SESSION_AUDIT_TRUSTED_PROXIES': '10.0.0.2, not-an-ip',
        }),
        {'10.0.0.2'},
      );
    });

    test('opening Appwrite is bounded when the connect never finishes', () {
      expect(sessionAuditConnectTimeout, const Duration(seconds: 5));
      return expect(
        sessionAuditWithin(Completer<int>().future, limit: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('hashes the caller address and keeps the raw address out of the key', () {
      final key = sessionAuditCallerKey('203.0.113.10', salt);
      expect(key.contains('203.0.113.10'), isFalse);
      expect(sessionAuditCallerKey('203.0.113.10', salt), key);
      expect(sessionAuditCallerKey('203.0.113.11', salt), isNot(key));
      expect(sessionAuditCallerKey(null, salt), sessionAuditCallerKey('  ', salt));
    });

    test('allows Belong web origins and loopback, and rejects other sites', () {
      expect(
        sessionAuditOriginAllowed(
          'https://belongonthespectrum.web.app',
          sessionAuditBrowserOrigins,
        ),
        isTrue,
      );
      expect(
        sessionAuditOriginAllowed('http://127.0.0.1:1234', sessionAuditBrowserOrigins),
        isTrue,
      );
      expect(sessionAuditOriginAllowed(null, sessionAuditBrowserOrigins), isTrue);
      expect(
        sessionAuditOriginAllowed('https://evil.example', sessionAuditBrowserOrigins),
        isFalse,
      );
    });

    test('loopback bind is the default and other hosts need --public', () {
      expect(sessionAuditBindAllowed(host: '127.0.0.1', public: false), isTrue);
      expect(sessionAuditBindAllowed(host: 'localhost', public: false), isTrue);
      expect(sessionAuditBindAllowed(host: '0.0.0.0', public: false), isFalse);
      expect(sessionAuditBindAllowed(host: '0.0.0.0', public: true), isTrue);
      expect(sessionAuditServerHelp, contains('Do not commit'));
    });

    test('end tokens match one row and fail closed on a different row', () {
      final tokens = HmacSessionAuditEndTokens(secret);
      final token = tokens.issue('row1');
      expect(tokens.accepts(rowId: 'row1', token: token), isTrue);
      expect(tokens.accepts(rowId: 'row2', token: token), isFalse);
      expect(token.contains(secret), isFalse);
    });

    test('a browser origin that is not allowed never reaches the writer', () async {
      final writer = _Writer();
      final reply = await serveSessionAuditRequest(
        method: 'POST',
        headers: const {'content-type': 'application/json', 'origin': 'https://evil.example'},
        body: jsonEncode({'action': 'start', 'row': _cleanRow()}),
        remoteAddress: '203.0.113.10',
        callerSalt: salt,
        admission: _admission(writer),
        allowedOrigins: sessionAuditBrowserOrigins,
      );
      expect(reply.status, 403);
      expect(writer.creates, 0);
    });
  });

  group('Appwrite writer', () {
    test('creates with an empty permission list and the server key', () async {
      final captured = _Capture();
      final writer = AppwriteSessionAuditWriter(
        endpoint: 'https://nyc.cloud.appwrite.io/v1/',
        projectId: 'proj',
        databaseId: 'belong_community_db',
        apiKey: secret,
        transport: captured.send,
      );

      final id = await writer.createRow({
        'timezone': 'UTC',
        'osName': 'ios',
        'appVersion': '0.9.2',
        'platform': 'ios',
        'sessionStartedAt': '2026-11-08T17:00:00.000Z',
      });
      expect(id, 'abc123');
      expect(captured.method, 'POST');
      expect(
        captured.uri.toString(),
        'https://nyc.cloud.appwrite.io/v1/tablesdb/belong_community_db/tables/client_session_audits/rows',
      );
      expect(captured.headers['X-Appwrite-Key'], secret);
      final body = captured.body;
      expect(body['permissions'], isEmpty);
      expect(body['rowId'], 'unique()');
      final data = body['data'] as Map<String, Object?>;
      expect(data.keys, everyElement(isIn(sessionAuditRowKeys)));

      await writer.markEnded(rowId: 'abc123', sessionEndedAt: '2026-11-08T17:30:00.000Z');
      expect(captured.method, 'PATCH');
      expect(captured.body['data'], {'sessionEndedAt': '2026-11-08T17:30:00.000Z'});
    });

    test('refuses an unexpected column before any request', () async {
      final captured = _Capture();
      final writer = AppwriteSessionAuditWriter(
        endpoint: 'https://nyc.cloud.appwrite.io/v1',
        projectId: 'proj',
        databaseId: 'belong_community_db',
        apiKey: secret,
        transport: captured.send,
      );
      await expectLater(
        writer.createRow({'email': 'member@example.com'}),
        throwsA(
          isA<SessionAuditWriteException>().having(
            (error) => error.toString(),
            'message',
            isNot(contains(secret)),
          ),
        ),
      );
      expect(captured.method, isNull);
    });

    test('a failed Appwrite status does not include the key', () async {
      final writer = AppwriteSessionAuditWriter(
        endpoint: 'https://nyc.cloud.appwrite.io/v1',
        projectId: 'proj',
        databaseId: 'belong_community_db',
        apiKey: secret,
        transport: ({required method, required uri, required headers, required body}) async =>
            (status: 401, json: {'message': secret}),
      );
      await expectLater(
        writer.createRow({
          'timezone': 'UTC',
          'osName': 'ios',
          'appVersion': '0.9.2',
          'platform': 'ios',
          'sessionStartedAt': '2026-11-08T17:00:00.000Z',
        }),
        throwsA(
          isA<SessionAuditWriteException>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('401'), isNot(contains(secret))),
          ),
        ),
      );
    });
  });

  test('a loopback server admits one row and rejects a foreign origin', () async {
    final writer = _Writer();
    final bound = await startSessionAuditServer(
      address: InternetAddress.loopbackIPv4,
      port: 0,
      admission: _admission(writer),
      callerSalt: salt,
      allowedOrigins: sessionAuditBrowserOrigins,
    );
    final server = bound.server;
    addTearDown(() => server.close(force: true));

    final ok = await _post(server, origin: null);
    expect(ok.status, 200);
    expect(ok.json['rowId'], 'row1');
    expect(writer.creates, 1);
    expect(writer.last!.keys, everyElement(isIn(sessionAuditRowKeys)));

    final blocked = await _post(server, origin: 'https://evil.example');
    expect(blocked.status, 403);
    expect(writer.creates, 1);
  });

  test('a busy admission slot refuses the next caller without waiting', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final writer = _BlockingWriter(entered: entered, release: release);
    final bound = await startSessionAuditServer(
      address: InternetAddress.loopbackIPv4,
      port: 0,
      admission: _admission(writer),
      callerSalt: salt,
      allowedOrigins: sessionAuditBrowserOrigins,
      inflight: SessionAuditInflight(maxInFlight: 1),
    );
    addTearDown(() async {
      if (!release.isCompleted) release.complete();
      await bound.server.close(force: true);
    });

    final first = _post(bound.server, origin: null);
    await entered.future.timeout(const Duration(seconds: 5));
    final second = await _post(bound.server, origin: null);
    expect(second.status, 503);
    expect(writer.creates, 1);
    release.complete();
    expect((await first).status, 200);
  });
}

SessionAuditAdmission _admission(SessionAuditRowWriter writer) => SessionAuditAdmission(
  gate: SessionAuditRateGate(),
  tokens: _Tokens(),
  writer: writer,
  clock: () => DateTime.utc(2026, 11, 8, 17),
);

Map<String, Object> _cleanRow() => {
  'timezone': 'UTC',
  'osName': 'ios',
  'appVersion': '0.9.2',
  'platform': 'ios',
  'sessionStartedAt': '2026-11-08T17:00:00.000Z',
  'city': 'US',
};

class _Tokens implements SessionAuditEndTokens {
  @override
  String issue(String rowId) => 'tok-$rowId';

  @override
  bool accepts({required String rowId, required String token}) => token == issue(rowId);
}

class _BlockingWriter implements SessionAuditRowWriter {
  _BlockingWriter({required this.entered, required this.release});

  final Completer<void> entered;
  final Completer<void> release;
  int creates = 0;

  @override
  Future<String> createRow(Map<String, Object> data) async {
    creates += 1;
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return 'row1';
  }

  @override
  Future<void> markEnded({required String rowId, required String sessionEndedAt}) async {}
}

class _Writer implements SessionAuditRowWriter {
  int creates = 0;
  Map<String, Object>? last;

  @override
  Future<String> createRow(Map<String, Object> data) async {
    creates += 1;
    last = data;
    return 'row1';
  }

  @override
  Future<void> markEnded({required String rowId, required String sessionEndedAt}) async {}
}

class _Capture {
  String? method;
  late Uri uri;
  Map<String, String> headers = const {};
  Map<String, Object?> body = const {};

  Future<({int status, Map<String, Object?> json})> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    this.method = method;
    this.uri = uri;
    this.headers = headers;
    this.body = body;
    return (status: 201, json: {'\$id': 'abc123'});
  }
}

Future<({int status, Map<String, Object?> json})> _post(
  HttpServer server, {
  required String? origin,
}) async {
  final client = HttpClient();
  try {
    final request = await client.post(server.address.address, server.port, '/');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (origin != null) request.headers.set('Origin', origin);
    request.add(utf8.encode(jsonEncode({'action': 'start', 'row': _cleanRow()})));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(text);
    return (
      status: response.statusCode,
      json: decoded is Map ? Map<String, Object?>.from(decoded) : <String, Object?>{},
    );
  } finally {
    client.close(force: true);
  }
}
