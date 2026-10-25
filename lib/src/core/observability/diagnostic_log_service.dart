import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/storage/data/storage_repository.dart';
import '../config/app_flavor.dart';
import '../firebase/firebase_installations_service.dart';
import '../logging/app_logger.dart';

/// Single chronological breadcrumb capturing a user or lifecycle event.
class BreadcrumbEvent {
  const BreadcrumbEvent({
    required this.timestamp,
    required this.category,
    required this.name,
    this.data,
  });

  final DateTime timestamp;
  final String category;
  final String name;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'name': name,
    if (data != null) 'data': data,
  };

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [$category] $name ${data != null ? jsonEncode(data) : ""}';
}

/// A structured, production-safe diagnostic session replay package.
///
/// Contains zero PII: captures app environment, Firebase Installation ID,
/// unhurried breadcrumbs, and sanitized Talker logs for instant developer triage.
class DiagnosticSessionReplay {
  DiagnosticSessionReplay({
    required this.sessionId,
    required this.startedAt,
    required this.installationsId,
    required this.appVersion,
    required this.platform,
    required this.flavor,
    required this.breadcrumbs,
    required this.logLines,
  });

  final String sessionId;
  final DateTime startedAt;
  final String installationsId;
  final String appVersion;
  final String platform;
  final String flavor;
  final List<BreadcrumbEvent> breadcrumbs;
  final List<String> logLines;

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'started_at': startedAt.toIso8601String(),
    'installations_id': installationsId,
    'app_version': appVersion,
    'platform': platform,
    'flavor': flavor,
    'breadcrumb_count': breadcrumbs.length,
    'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
    'log_count': logLines.length,
    'logs': logLines,
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toFormattedText() {
    final buffer = StringBuffer()
      ..writeln('========================================')
      ..writeln('  BELONG ON THE SPECTRUM - SESSION REPLAY')
      ..writeln('========================================')
      ..writeln('Session ID       : $sessionId')
      ..writeln('Started At       : ${startedAt.toIso8601String()}')
      ..writeln('Installation ID  : $installationsId')
      ..writeln('App Version      : $appVersion')
      ..writeln('Platform         : $platform')
      ..writeln('Flavor           : $flavor')
      ..writeln('----------------------------------------')
      ..writeln('BREADCRUMBS (${breadcrumbs.length}):')
      ..writeln('----------------------------------------');

    if (breadcrumbs.isEmpty) {
      buffer.writeln('(No breadcrumbs recorded in this session)');
    } else {
      for (final b in breadcrumbs) {
        buffer.writeln(b.toString());
      }
    }

    buffer
      ..writeln('----------------------------------------')
      ..writeln('RECENT DIAGNOSTIC LOGS (${logLines.length}):')
      ..writeln('----------------------------------------');

    if (logLines.isEmpty) {
      buffer.writeln('(No log entries available)');
    } else {
      for (final line in logLines) {
        buffer.writeln(line);
      }
    }

    buffer.writeln('========================================');
    return buffer.toString();
  }
}

/// Service that coordinates in-app diagnostic recording and log transmission.
class DiagnosticLogService {
  DiagnosticLogService({
    required this.storageRepository,
    required this.installationsService,
    this.flavor = AppFlavor.prod,
  }) : sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
       sessionStartedAt = DateTime.now();

  final StorageRepository storageRepository;
  final FirebaseInstallationsService installationsService;
  final AppFlavor flavor;
  final String sessionId;
  final DateTime sessionStartedAt;

  final List<BreadcrumbEvent> _breadcrumbs = [];
  static const int maxBreadcrumbs = 100;

  List<BreadcrumbEvent> get breadcrumbsForTesting => List.unmodifiable(_breadcrumbs);

  /// Records a chronological breadcrumb in the session timeline.
  void recordBreadcrumb(String name, {String category = 'action', Map<String, dynamic>? data}) {
    if (_breadcrumbs.length >= maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    final event = BreadcrumbEvent(
      timestamp: DateTime.now(),
      category: category,
      name: name,
      data: data != null ? _sanitizeData(data) : null,
    );
    _breadcrumbs.add(event);
    talker.debug('🧭 [BREADCRUMB] [$category] $name');
  }

  /// Compiles the full [DiagnosticSessionReplay] bundle.
  Future<DiagnosticSessionReplay> generateReplayBundle({String? overrideInstallationsId}) async {
    final fid = overrideInstallationsId ?? await installationsService.getInstallationsId();

    final logs = _collectSanitizedLogs();

    return DiagnosticSessionReplay(
      sessionId: sessionId,
      startedAt: sessionStartedAt,
      installationsId: fid,
      appVersion: '0.2.0+2',
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      flavor: flavor.slug,
      breadcrumbs: List.unmodifiable(_breadcrumbs),
      logLines: logs,
    );
  }

  /// Sends the formatted diagnostic session bundle to Cloud Storage and returns the public link.
  Future<String> sendLogsToCloudStorage({
    StorageRepository? customStorage,
    String? installationsId,
  }) async {
    final repo = customStorage ?? storageRepository;
    final replay = await generateReplayBundle(overrideInstallationsId: installationsId);

    final jsonPayload = replay.toPrettyJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonPayload));
    final filename = 'session_${replay.sessionId}_${DateTime.now().millisecondsSinceEpoch}.json';

    talker.info(
      '📦 [DIAGNOSTICS] Uploading session replay (${bytes.length} bytes) to Cloud Storage...',
    );

    final downloadUrl = await repo.uploadDiagnosticLogs(bytes: bytes, filename: filename);

    talker.info('🚀 [DIAGNOSTICS] Session logs successfully uploaded to: $downloadUrl');
    return downloadUrl;
  }

  List<String> _collectSanitizedLogs() {
    try {
      final history = talker.history;
      return history.map((entry) {
        final text = entry.generateTextMessage();
        return _sanitizeText(text);
      }).toList();
    } catch (_) {
      return ['(Unable to read Talker history buffer)'];
    }
  }

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) => data.map((key, value) {
    if (value is String) {
      return MapEntry(key, _sanitizeText(value));
    }
    return MapEntry(key, value);
  });

  String _sanitizeText(String text) {
    // Redact email addresses and sensitive auth tokens
    var sanitized = text.replaceAll(
      RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'),
      '[REDACTED_EMAIL]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(key|token|password|auth|secret)\s*[:=]\s*[^\s,]+', caseSensitive: false),
      r'$1=[REDACTED]',
    );
    return sanitized;
  }
}

/// Global provider for [DiagnosticLogService].
final diagnosticLogServiceProvider = Provider<DiagnosticLogService>((ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final installations = ref.watch(firebaseInstallationsServiceProvider);
  return DiagnosticLogService(
    storageRepository: storage,
    installationsService: installations,
    flavor: AppFlavor.prod,
  );
});
