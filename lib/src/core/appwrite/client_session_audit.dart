import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../logging/app_logger.dart';
import 'client_session_audit_snapshot.dart';
import 'client_session_os_facts.dart';
import 'client_session_os_reader.dart';

/// Soft-launch default. Pass `--dart-define=CLIENT_SESSION_AUDIT=false` to skip.
const clientSessionAuditEnabled = bool.fromEnvironment('CLIENT_SESSION_AUDIT', defaultValue: true);

/// Admission server. Empty skips the write. This is not an Appwrite function URL.
const clientSessionAuditUrl = String.fromEnvironment('CLIENT_SESSION_AUDIT_URL', defaultValue: '');

/// Writes one session row. Tests use a fake. Production posts to the admission server.
abstract class ClientSessionAuditSink {
  Future<String?> createSession(ClientSessionAuditSnapshot snapshot);

  Future<void> markEnded({required String rowId, required DateTime endedAt});
}

/// HTTPS admission URL, or loopback HTTP for a local server. Anything else is ignored.
Uri? clientSessionAuditEndpoint(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty || uri.host.contains('@')) return null;
  if (uri.scheme == 'https') return uri;
  final host = uri.host.toLowerCase();
  final loopback = host == 'localhost' || host == '127.0.0.1' || host == '::1';
  if (uri.scheme == 'http' && loopback) return uri;
  return null;
}

typedef SessionAuditPost = Future<({int status, Object? json})> Function(Map<String, Object?> body);

/// Posts a sanitized snapshot to the admission server. No Appwrite API key.
class HttpClientSessionAuditSink implements ClientSessionAuditSink {
  HttpClientSessionAuditSink({
    required this.endpoint,
    this.client,
    this.post,
    this.timeout = const Duration(seconds: 8),
  });

  final Uri endpoint;
  final http.Client? client;
  final SessionAuditPost? post;
  final Duration timeout;

  http.Client? _owned;
  String? _rowId;
  String? _endToken;

  @override
  Future<String?> createSession(ClientSessionAuditSnapshot snapshot) async {
    final result = await _send({'action': 'start', 'row': snapshot.toRowData()});
    if (result == null || result.status < 200 || result.status >= 300) return null;
    final json = result.json;
    if (json is! Map) return null;
    final rowId = json['rowId'];
    final token = json['endToken'];
    if (rowId is! String || rowId.isEmpty || token is! String || token.isEmpty) return null;
    _rowId = rowId;
    _endToken = token;
    return rowId;
  }

  @override
  Future<void> markEnded({required String rowId, required DateTime endedAt}) async {
    final token = _endToken;
    if (token == null || token.isEmpty || _rowId != rowId) {
      throw StateError('session audit end token missing');
    }
    final result = await _send({
      'action': 'end',
      'rowId': rowId,
      'endToken': token,
      'sessionEndedAt': endedAt.toUtc().toIso8601String(),
    });
    if (result == null || result.status < 200 || result.status >= 300) {
      throw StateError('session audit end was refused');
    }
  }

  Future<({int status, Object? json})?> _send(Map<String, Object?> body) async {
    final send = post;
    if (send != null) return send(body);
    final httpClient = client ?? (_owned ??= http.Client());
    try {
      final response = await httpClient
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
      Object? decoded;
      try {
        if (response.body.trim().isNotEmpty) decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      return (status: response.statusCode, json: decoded);
    } catch (error, stack) {
      AppLogger.warning('client session audit request failed', error, stack);
      return null;
    }
  }
}

/// One cold start writes one row. Later calls in the same process do nothing.
class ClientSessionAuditController {
  ClientSessionAuditController({
    required this.sink,
    required this.loadSnapshot,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ClientSessionAuditSink sink;
  final Future<ClientSessionAuditSnapshot> Function() loadSnapshot;
  final DateTime Function() _clock;

  bool _startRequested = false;
  bool _endRequested = false;
  bool _endWritten = false;
  String? _rowId;

  Future<void> recordStart() async {
    if (_startRequested) return;
    _startRequested = true;
    try {
      final snapshot = await loadSnapshot();
      final rowId = await sink.createSession(snapshot);
      if (rowId == null || rowId.isEmpty) {
        AppLogger.warning('client session audit write returned no row id');
        return;
      }
      _rowId = rowId;
      AppLogger.info('client session audit recorded');
      if (_endRequested) await _writeEnd();
    } catch (error, stack) {
      AppLogger.warning('client session audit write failed', error, stack);
    }
  }

  Future<void> recordEnd() async {
    _endRequested = true;
    await _writeEnd();
  }

  Future<void> _writeEnd() async {
    final rowId = _rowId;
    if (_endWritten || rowId == null) return;
    _endWritten = true;
    try {
      await sink.markEnded(rowId: rowId, endedAt: _clock().toUtc());
      AppLogger.info('client session audit end recorded');
    } catch (error, stack) {
      _endWritten = false;
      AppLogger.warning('client session audit end update failed', error, stack);
    }
  }
}

/// Updates `sessionEndedAt` once when the app pauses or detaches.
class ClientSessionAuditBinding extends WidgetsBindingObserver {
  ClientSessionAuditBinding(this.controller);

  final ClientSessionAuditController controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(controller.recordEnd());
    }
  }
}

/// Schedules a fail-soft session post after bindings. Never blocks startup.
///
/// The phone does not write `client_session_audits`. An empty
/// [clientSessionAuditUrl] skips the post. This does not keep Free active.
/// See `docs/wiki/Appwrite-Free-Tier-Inactivity-and-Session-Audit.md`.
ClientSessionAuditBinding? startClientSessionAudit({
  ClientSessionAuditController? controller,
  bool enabled = clientSessionAuditEnabled,
}) {
  if (!enabled) return null;
  final active = controller ?? _liveController();
  if (active == null) return null;
  final binding = ClientSessionAuditBinding(active);
  WidgetsBinding.instance.addObserver(binding);
  unawaited(active.recordStart());
  return binding;
}

ClientSessionAuditController? _liveController() {
  final endpoint = clientSessionAuditEndpoint(clientSessionAuditUrl);
  if (endpoint == null) {
    AppLogger.info('client session audit skipped; admission URL is not configured');
    return null;
  }
  return ClientSessionAuditController(
    sink: HttpClientSessionAuditSink(endpoint: endpoint),
    loadSnapshot: loadClientSessionAuditSnapshot,
  );
}

Future<ClientSessionAuditSnapshot> loadClientSessionAuditSnapshot({
  DateTime Function()? now,
  Future<({String version, String? build})> Function()? loadVersion,
  ClientSessionOsFacts Function()? readOs,
  Locale? locale,
  bool? isWeb,
}) async {
  final clock = now ?? DateTime.now;
  final instant = clock().toUtc();
  final version = await (loadVersion ?? _packageVersion)();
  final os = (readOs ?? readClientSessionOsFacts)();
  final web = isWeb ?? kIsWeb;
  final resolved = locale ?? WidgetsBinding.instance.platformDispatcher.locale;
  return buildClientSessionAuditSnapshot(
    now: instant,
    osName: os.osName,
    osVersion: os.osVersion,
    appVersion: version.version,
    appBuild: version.build,
    isWeb: web,
    countryCode: resolved.countryCode,
    localeTag: resolved.toLanguageTag(),
  );
}

Future<({String version, String? build})> _packageVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final build = info.buildNumber.trim();
    return (version: version.isEmpty ? 'unknown' : version, build: build.isEmpty ? null : build);
  } catch (error, stack) {
    AppLogger.warning('client session audit package version unavailable', error, stack);
    return (version: 'unknown', build: null);
  }
}
