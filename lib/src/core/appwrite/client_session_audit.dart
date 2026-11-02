import 'dart:async';

import 'package:appwrite/appwrite.dart' hide Locale;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logging/app_logger.dart';
import 'appwrite_client_factory.dart';
import 'appwrite_config.dart';
import 'client_session_audit_snapshot.dart';
import 'client_session_os_facts.dart';
import 'client_session_os_reader.dart';

/// Soft-launch default. Pass `--dart-define=CLIENT_SESSION_AUDIT=false` to skip.
const clientSessionAuditEnabled = bool.fromEnvironment('CLIENT_SESSION_AUDIT', defaultValue: true);

/// Writes one session row. Tests use a fake. Production uses TablesDB.
abstract class ClientSessionAuditSink {
  Future<String?> createSession(ClientSessionAuditSnapshot snapshot);

  Future<void> markEnded({required String rowId, required DateTime endedAt});
}

/// TablesDB writer for `client_session_audits` using the shared Appwrite client.
class AppwriteClientSessionAuditSink implements ClientSessionAuditSink {
  AppwriteClientSessionAuditSink({required this.services, required this.config});

  final AppwriteServices services;
  final AppwriteConfig config;

  @override
  Future<String?> createSession(ClientSessionAuditSnapshot snapshot) async {
    final row = await services.tables.createRow(
      databaseId: config.databaseId,
      tableId: AppwriteConfig.clientSessionAuditsTableId,
      rowId: ID.unique(),
      data: snapshot.toRowData(),
    );
    final id = row.$id.trim();
    return id.isEmpty ? null : id;
  }

  @override
  Future<void> markEnded({required String rowId, required DateTime endedAt}) =>
      services.tables.updateRow(
        databaseId: config.databaseId,
        tableId: AppwriteConfig.clientSessionAuditsTableId,
        rowId: rowId,
        data: {'sessionEndedAt': endedAt.toUtc().toIso8601String()},
      );
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

/// Schedules a fail-soft session row after bindings. Never blocks startup.
///
/// This is ops telemetry. It does not keep an Appwrite Free project active.
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
  final config = AppwriteConfig.fromEnvironment;
  final services = createAppwriteServices(config);
  if (services == null) return null;
  return ClientSessionAuditController(
    sink: AppwriteClientSessionAuditSink(services: services, config: config),
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
