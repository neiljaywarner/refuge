// Admission server for `client_session_audits`.
//
// The Flutter app must not call TablesDB createRow for this table. This
// process checks the allowlist and the write budget, then writes with
// APPWRITE_API_KEY. Free tier allows two functions; dm-push and dm-mirror
// already use them. Do not deploy this as a third Appwrite function, and do
// not add the route to those functions.
//
//   # APPWRITE_API_KEY in the environment. Do not commit it or pass it as a flag.
//   dart run tool/client_session_audit_server.dart
//   dart run tool/client_session_audit_server.dart --public --host=0.0.0.0 --port=8787
//
// The default bind is 127.0.0.1. --public is required for any other host.
// The key stays in the environment. Do not pass it as a flag.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_admission.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_snapshot.dart';

const sessionAuditServerHelp = '''
Admit client session rows, then write them with the server API key.

  dart run tool/client_session_audit_server.dart [--port=8787]
  dart run tool/client_session_audit_server.dart --public --host=0.0.0.0

Reads APPWRITE_API_KEY from the environment. Do not commit that key, paste it
into an issue, or pass it as a flag. Endpoint, project, and database come from
AppwriteConfig.

Browser posts are limited to Belong web origins plus loopback. Set
SESSION_AUDIT_ALLOWED_ORIGINS to a comma-separated list to add more.

The rate-limit identity is the direct connection address. X-Forwarded-For
is ignored unless SESSION_AUDIT_TRUSTED_PROXIES lists that direct peer.
The proxy must append the client address it accepted, or replace the header
with that bare IP. Do not copy the client header through unchanged.
At most 8 requests are admitted at once. The rest get 503 immediately.
''';

/// How long a request may sit while its body is still arriving.
const sessionAuditBodyReadTimeout = Duration(seconds: 5);

const sessionAuditBrowserOrigins = <String>{
  'https://belongonthespectrum.web.app',
  'https://belongonthespectrum.firebaseapp.com',
  'https://dev-belongonthespectrum.web.app',
  'https://belongonthespectrum.com',
  'https://www.belongonthespectrum.com',
};

bool sessionAuditBindAllowed({required String host, required bool public}) {
  final normalized = host.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  if (public) return true;
  return normalized == '127.0.0.1' || normalized == 'localhost';
}

bool sessionAuditOriginAllowed(String? origin, Set<String> allowed) {
  if (origin == null || origin.trim().isEmpty) return true;
  final value = origin.trim();
  if (allowed.contains(value)) return true;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return false;
  final host = uri.host.toLowerCase();
  final loopback = host == 'localhost' || host == '127.0.0.1' || host == '::1';
  if (!loopback) return false;
  return uri.scheme == 'http' || uri.scheme == 'https';
}

/// HMAC of the peer address. The address is not stored and is not written.
String sessionAuditCallerKey(String? address, List<int> salt) {
  final material = (address == null || address.trim().isEmpty) ? 'missing' : address.trim();
  final hmac = Hmac(sha256, salt);
  return base64Url.encode(hmac.convert(utf8.encode(material)).bytes);
}

class HmacSessionAuditEndTokens implements SessionAuditEndTokens {
  HmacSessionAuditEndTokens(this.secret);

  final String secret;

  @override
  String issue(String rowId) => _mac(rowId);

  @override
  bool accepts({required String rowId, required String token}) => _constantTime(_mac(rowId), token);

  String _mac(String rowId) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode('session-audit-end:$rowId'));
    return base64Url.encode(digest.bytes);
  }

  bool _constantTime(String left, String right) {
    final a = utf8.encode(left);
    final b = utf8.encode(right);
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

typedef SessionAuditTransport = Future<({int status, Map<String, Object?> json})> Function({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, Object?> body,
});

class SessionAuditWriteException implements Exception {
  SessionAuditWriteException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'session audit write failed ($statusCode)';
}

/// TablesDB writer. Sends an empty permission list so the row grants no client role.
class AppwriteSessionAuditWriter implements SessionAuditRowWriter {
  AppwriteSessionAuditWriter({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.apiKey,
    this.transport,
    this.tableId = AppwriteConfig.clientSessionAuditsTableId,
  });

  final String endpoint;
  final String projectId;
  final String databaseId;
  final String apiKey;
  final String tableId;
  final SessionAuditTransport? transport;

  @override
  Future<String> createRow(Map<String, Object> data) async {
    _requireAllowed(data);
    final response = await _send('POST', _rows(), {
      'rowId': 'unique()',
      'data': data,
      'permissions': <String>[],
    });
    final id = response[r'$id'];
    if (id is! String || !sessionAuditRowIdOk(id)) {
      throw SessionAuditWriteException(502);
    }
    return id;
  }

  @override
  Future<void> markEnded({required String rowId, required String sessionEndedAt}) async {
    if (!sessionAuditRowIdOk(rowId)) throw SessionAuditWriteException(400);
    await _send('PATCH', _row(rowId), {
      'data': {'sessionEndedAt': sessionEndedAt},
    });
  }

  void _requireAllowed(Map<String, Object> data) {
    for (final key in data.keys) {
      if (!sessionAuditRowKeys.contains(key)) throw SessionAuditWriteException(400);
    }
  }

  Future<Map<String, Object?>> _send(String method, Uri uri, Map<String, Object?> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    };
    final send = transport;
    final result = send == null
        ? await _http(method: method, uri: uri, headers: headers, body: body)
        : await send(method: method, uri: uri, headers: headers, body: body);
    if (result.status < 200 || result.status >= 300) {
      throw SessionAuditWriteException(result.status);
    }
    return result.json;
  }

  Future<({int status, Map<String, Object?> json})> _http({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = sessionAuditConnectTimeout;
      final request = await sessionAuditWithin(client.openUrl(method, uri));
      headers.forEach(request.headers.set);
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(const Duration(seconds: 20));
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SessionAuditWriteException(response.statusCode);
      }
      if (text.trim().isEmpty) return (status: response.statusCode, json: <String, Object?>{});
      final decoded = jsonDecode(text);
      if (decoded is! Map) throw SessionAuditWriteException(response.statusCode);
      return (status: response.statusCode, json: Map<String, Object?>.from(decoded));
    } finally {
      client.close(force: true);
    }
  }

  Uri _rows() => Uri.parse('${_root()}/tablesdb/$databaseId/tables/$tableId/rows');

  Uri _row(String rowId) => Uri.parse(
    '${_root()}/tablesdb/$databaseId/tables/$tableId/rows/${Uri.encodeComponent(rowId)}',
  );

  String _root() {
    final trimmed = endpoint.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }
}

class SessionAuditSocketReply {
  const SessionAuditSocketReply({required this.status, required this.body, this.allowOrigin});

  final int status;
  final Map<String, Object?> body;
  final String? allowOrigin;
}

/// HTTP policy in front of [SessionAuditAdmission]. Does not log the caller address.
Future<SessionAuditSocketReply> serveSessionAuditRequest({
  required String method,
  required Map<String, String> headers,
  required String body,
  required String? remoteAddress,
  required List<int> callerSalt,
  required SessionAuditAdmission admission,
  required Set<String> allowedOrigins,
}) async {
  final origin = _header(headers, 'origin');
  final allowed = sessionAuditOriginAllowed(origin, allowedOrigins);
  final echo = allowed && origin != null && origin.trim().isNotEmpty ? origin.trim() : null;
  final normalized = method.toUpperCase();
  if (normalized == 'OPTIONS') {
    if (!allowed) {
      return const SessionAuditSocketReply(status: 403, body: {'error': 'rejected'});
    }
    return SessionAuditSocketReply(status: 204, body: const {}, allowOrigin: echo);
  }
  if (!allowed) {
    return const SessionAuditSocketReply(status: 403, body: {'error': 'rejected'});
  }
  if (normalized != 'POST') {
    return SessionAuditSocketReply(
      status: 405,
      body: const {'error': 'rejected'},
      allowOrigin: echo,
    );
  }
  if (body.length > sessionAuditMaxBodyBytes) {
    return SessionAuditSocketReply(
      status: 400,
      body: const {'error': 'rejected'},
      allowOrigin: echo,
    );
  }
  final type = _header(headers, 'content-type');
  if (type == null || type.split(';').first.trim().toLowerCase() != 'application/json') {
    return SessionAuditSocketReply(
      status: 400,
      body: const {'error': 'rejected'},
      allowOrigin: echo,
    );
  }
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return SessionAuditSocketReply(
      status: 400,
      body: const {'error': 'rejected'},
      allowOrigin: echo,
    );
  }
  final reply = await admission.handle(
    body: decoded,
    callerKey: sessionAuditCallerKey(remoteAddress, callerSalt),
  );
  return SessionAuditSocketReply(status: reply.status, body: reply.body, allowOrigin: echo);
}

/// Fails if [future] is still pending when [limit] elapses.
Future<T> sessionAuditWithin<T>(Future<T> future, {Duration? limit}) =>
    future.timeout(limit ?? sessionAuditConnectTimeout);

String? _header(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name) return entry.value;
  }
  return null;
}

Future<({HttpServer server, Future<void> closed})> startSessionAuditServer({
  required InternetAddress address,
  required int port,
  required SessionAuditAdmission admission,
  required List<int> callerSalt,
  Set<String>? allowedOrigins,
  Set<String> trustedProxies = const {},
  SessionAuditInflight? inflight,
}) async {
  final origins = allowedOrigins ?? sessionAuditBrowserOrigins;
  final slots = inflight ?? SessionAuditInflight();
  final server = await HttpServer.bind(address, port);
  final closed = Completer<void>();
  server.listen(
    (request) {
      if (!slots.tryEnter()) {
        unawaited(_rejectBusy(request));
        return;
      }
      unawaited(
        _dispatch(
          request,
          admission,
          callerSalt,
          origins,
          trustedProxies,
        ).whenComplete(slots.leave).catchError((Object _) {
          stderr.writeln('session audit request failed');
        }),
      );
    },
    onDone: () {
      if (!closed.isCompleted) closed.complete();
    },
    onError: (Object _) {
      stderr.writeln('session audit request failed');
    },
  );
  return (server: server, closed: closed.future);
}

Future<void> _rejectBusy(HttpRequest request) async {
  try {
    request.response.statusCode = 503;
    request.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    request.response.write(jsonEncode(const {'error': 'unavailable'}));
    await request.response.close();
  } catch (_) {
    stderr.writeln('session audit request failed');
  }
}

Future<void> _dispatch(
  HttpRequest request,
  SessionAuditAdmission admission,
  List<int> callerSalt,
  Set<String> allowedOrigins,
  Set<String> trustedProxies,
) async {
  SessionAuditSocketReply reply;
  try {
    final declared = request.contentLength;
    if (declared > sessionAuditMaxBodyBytes) {
      reply = const SessionAuditSocketReply(status: 400, body: {'error': 'rejected'});
    } else {
      final bytes = await _readLimited(request);
      reply = await serveSessionAuditRequest(
        method: request.method,
        headers: {
          'content-type': request.headers.value(HttpHeaders.contentTypeHeader) ?? '',
          'origin': request.headers.value('origin') ?? '',
        },
        body: utf8.decode(bytes),
        remoteAddress: sessionAuditCallerAddress(
          directAddress: request.connectionInfo?.remoteAddress.address,
          forwardedFor: request.headers.value('x-forwarded-for'),
          trustedProxies: trustedProxies,
        ),
        callerSalt: callerSalt,
        admission: admission,
        allowedOrigins: allowedOrigins,
      );
    }
  } on _BodyTooLarge {
    reply = const SessionAuditSocketReply(status: 400, body: {'error': 'rejected'});
  } catch (_) {
    reply = const SessionAuditSocketReply(status: 400, body: {'error': 'rejected'});
  }
  request.response.statusCode = reply.status;
  request.response.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
  if (reply.allowOrigin != null) {
    request.response.headers.set('Access-Control-Allow-Origin', reply.allowOrigin!);
    request.response.headers.set('Vary', 'Origin');
    request.response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'content-type, accept');
    request.response.headers.set('Access-Control-Max-Age', '600');
  }
  if (reply.status != 204) request.response.write(jsonEncode(reply.body));
  try {
    await request.response.close().timeout(sessionAuditBodyReadTimeout);
  } catch (_) {
    stderr.writeln('session audit request failed');
  }
}

Future<List<int>> _readLimited(HttpRequest request) {
  final builder = BytesBuilder(copy: false);
  final completer = Completer<List<int>>();
  late final StreamSubscription<Uint8List> subscription;
  final timer = Timer(sessionAuditBodyReadTimeout, () {
    unawaited(subscription.cancel());
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('session audit body'));
    }
  });
  subscription = request.listen(
    (chunk) {
      if (completer.isCompleted) return;
      if (builder.length + chunk.length > sessionAuditMaxBodyBytes) {
        timer.cancel();
        unawaited(subscription.cancel());
        completer.completeError(const _BodyTooLarge());
        return;
      }
      builder.add(chunk);
    },
    onError: (Object error, StackTrace stack) {
      timer.cancel();
      if (!completer.isCompleted) completer.completeError(error, stack);
    },
    onDone: () {
      timer.cancel();
      if (!completer.isCompleted) completer.complete(builder.takeBytes());
    },
    cancelOnError: true,
  );
  return completer.future;
}

class _BodyTooLarge implements Exception {
  const _BodyTooLarge();
}

Set<String> sessionAuditTrustedProxiesFromEnvironment(Map<String, String> environment) {
  final raw = environment['SESSION_AUDIT_TRUSTED_PROXIES'] ?? '';
  final proxies = <String>{};
  for (final item in raw.split(',')) {
    final ip = sessionAuditNormalizeIp(item);
    if (ip != null) proxies.add(ip);
  }
  return proxies;
}

Set<String> sessionAuditOriginsFromEnvironment(Map<String, String> environment) {
  final extra = environment['SESSION_AUDIT_ALLOWED_ORIGINS'] ?? '';
  return {
    ...sessionAuditBrowserOrigins,
    for (final item in extra.split(','))
      if (item.trim().isNotEmpty) item.trim(),
  };
}

List<int> sessionAuditCallerSalt() {
  final random = Random.secure();
  return List<int>.generate(32, (_) => random.nextInt(256));
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(sessionAuditServerHelp);
    exit(0);
  }
  final apiKey = Platform.environment['APPWRITE_API_KEY']?.trim() ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
      'Missing APPWRITE_API_KEY. Export a server API key that can read and '
      'write rows in belong_community_db. Do not commit the key.',
    );
    exit(2);
  }
  final host = _flag(args, '--host') ?? '127.0.0.1';
  final port = int.tryParse(_flag(args, '--port') ?? '') ?? 8787;
  final public = args.contains('--public');
  if (!sessionAuditBindAllowed(host: host, public: public) || port <= 0 || port > 65535) {
    stderr.writeln('Refusing to bind $host:$port. Pass --public to bind a non-loopback host.');
    exit(2);
  }
  final config = AppwriteConfig.fromEnvironment;
  if (!config.isConfigured) {
    stderr.writeln('Appwrite endpoint or project id is not configured.');
    exit(2);
  }
  final admission = SessionAuditAdmission(
    gate: SessionAuditRateGate(),
    tokens: HmacSessionAuditEndTokens(apiKey),
    writer: AppwriteSessionAuditWriter(
      endpoint: config.endpoint,
      projectId: config.projectId,
      databaseId: config.databaseId,
      apiKey: apiKey,
    ),
  );
  final address = host == 'localhost'
      ? InternetAddress.loopbackIPv4
      : InternetAddress.tryParse(host) ?? InternetAddress.loopbackIPv4;
  final bound = await startSessionAuditServer(
    address: address,
    port: port,
    admission: admission,
    callerSalt: sessionAuditCallerSalt(),
    allowedOrigins: sessionAuditOriginsFromEnvironment(Platform.environment),
    trustedProxies: sessionAuditTrustedProxiesFromEnvironment(Platform.environment),
  );
  stdout.writeln(
    'session audit admission listening on ${bound.server.address.address}:${bound.server.port}',
  );
  await bound.closed;
}

String? _flag(List<String> args, String name) {
  final prefix = '$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length).trim();
  }
  return null;
}
