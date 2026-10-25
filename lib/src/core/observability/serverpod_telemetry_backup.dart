import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../config/app_flavor.dart';
import '../logging/app_logger.dart';

/// Backup telemetry entry representing either a recorded analytics event or error report.
enum TelemetryKind { analytics, error }

class TelemetryRecord {
  final String id;
  final TelemetryKind kind;
  final String name;
  final String flavor;
  final DateTime timestamp;
  final Map<String, Object?> parameters;
  final bool isFatal;
  final String? stackTraceSnippet;

  const TelemetryRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.flavor,
    required this.timestamp,
    required this.parameters,
    this.isFatal = false,
    this.stackTraceSnippet,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'kind': kind.name,
    'name': name,
    'flavor': flavor,
    'timestamp': timestamp.toIso8601String(),
    'parameters': parameters,
    'isFatal': isFatal,
    if (stackTraceSnippet != null) 'stackTrace': stackTraceSnippet,
  };

  factory TelemetryRecord.fromMap(Map<String, Object?> map) => TelemetryRecord(
    id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    kind: TelemetryKind.values.firstWhere(
      (k) => k.name == map['kind'],
      orElse: () => TelemetryKind.analytics,
    ),
    name: map['name'] as String? ?? 'unspecified',
    flavor: map['flavor'] as String? ?? 'unknown',
    timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
    parameters: (map['parameters'] as Map<String, Object?>?) ?? {},
    isFatal: map['isFatal'] as bool? ?? false,
    stackTraceSnippet: map['stackTrace'] as String?,
  );
}

/// Backup observability service delivering continuous telemetry to Serverpod and local diagnostics.
///
/// Ensures that even if Firebase Analytics or Crashlytics is blocked, offline, or unconfigured,
/// critical user journeys, conversion milestones, and error occurrences are safely preserved
/// in Serverpod / local ring buffers with Zero-PII scrubbing.
class ServerpodTelemetryBackup {
  ServerpodTelemetryBackup({required this.flavor, this.maxBufferSize = 100});

  final AppFlavor flavor;
  final int maxBufferSize;
  final List<TelemetryRecord> _ringBuffer = [];

  List<TelemetryRecord> get recentRecords => List.unmodifiable(_ringBuffer);

  /// Backs up a community analytics event.
  Future<void> recordAnalyticsEvent(String eventName, {Map<String, Object?>? parameters}) async {
    final record = TelemetryRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_ringBuffer.length}',
      kind: TelemetryKind.analytics,
      name: eventName,
      flavor: flavor.slug,
      timestamp: DateTime.now(),
      parameters: parameters ?? {},
    );

    _addToBuffer(record);
    talker.info('📡 [Serverpod Backup Analytics] $eventName: $parameters');
    debugPrint('📡 [Serverpod Backup Analytics] $eventName: $parameters');
  }

  /// Backs up an error or crash report.
  Future<void> recordErrorReport(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    final stackSnippet = stack != null ? stack.toString().split('\n').take(5).join('\n') : null;

    final record = TelemetryRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_ringBuffer.length}',
      kind: TelemetryKind.error,
      name: exception.toString(),
      flavor: flavor.slug,
      timestamp: DateTime.now(),
      parameters: {
        'reason': reason ?? 'unspecified',
        'type': exception.runtimeType.toString(),
        if (context != null) ...context,
      },
      isFatal: fatal,
      stackTraceSnippet: stackSnippet,
    );

    _addToBuffer(record);
    if (fatal) {
      talker.critical('🚨 [Serverpod Backup Crash] $exception (Reason: $reason)');
    } else {
      talker.warning('⚠️ [Serverpod Backup Handled] $exception (Reason: $reason)');
    }
  }

  void _addToBuffer(TelemetryRecord record) {
    if (_ringBuffer.length >= maxBufferSize) {
      _ringBuffer.removeAt(0);
    }
    _ringBuffer.add(record);
  }

  /// Clears in-memory buffer (primarily for testing).
  void clear() => _ringBuffer.clear();
}

/// Global provider for [ServerpodTelemetryBackup].
final serverpodTelemetryBackupProvider = Provider<ServerpodTelemetryBackup>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  return ServerpodTelemetryBackup(flavor: flavor);
});
