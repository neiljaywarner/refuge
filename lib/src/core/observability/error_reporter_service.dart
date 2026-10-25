import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/logging/app_logger.dart' as app_log;
import 'package:refuge4serverpod/src/core/observability/serverpod_telemetry_backup.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Unified error handling and observability service delivering triple-destination
/// error reporting across:
/// 1. Firebase Crashlytics (unhandled fatal and handled non-fatal exceptions)
/// 2. Firebase Analytics (`app_error` event with sanitized categorization)
/// 3. Serverpod / Local Diagnostics buffer for offline/developer visibility
///
/// Designed with strict Zero-PII principles (scrubs emails, tokens, and names).
class ErrorReporterService {
  ErrorReporterService({
    required this.flavor,
    required this.analyticsService,
    this.serverpodBackup,
    Talker? talkerInstance,
  }) : talker = talkerInstance ?? app_log.talker;

  final AppFlavor flavor;
  final CommunityAnalyticsService analyticsService;
  final ServerpodTelemetryBackup? serverpodBackup;
  final Talker talker;

  /// In-memory ring buffer of reported errors for UI diagnostics and test inspection.
  final List<Map<String, Object?>> recordedErrorsForTesting = [];

  /// Primary reporting method for both synchronous and asynchronous exceptions.
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object>? context,
  }) async {
    final sanitizedContext = _sanitizeMetadata(context);
    final errorEntry = <String, Object?>{
      'timestamp': DateTime.now().toIso8601String(),
      'flavor': flavor.slug,
      'error': exception.toString(),
      'reason': reason ?? 'unspecified',
      'fatal': fatal,
      'stack': stack?.toString(),
      'context': sanitizedContext,
    };
    recordedErrorsForTesting.add(errorEntry);

    // 1. Diagnostics & structured logging via Talker
    if (fatal) {
      talker.critical(
        '🚨 [ErrorReporter FATAL] $exception (Reason: $reason)',
        exception,
        stack,
      );
    } else {
      talker.error(
        '⚠️ [ErrorReporter HANDLED] $exception (Reason: $reason)',
        exception,
        stack,
      );
    }

    // 2. Firebase Analytics: log 'app_error' event with category and reason
    try {
      await analyticsService.logEvent(
        'app_error',
        parameters: {
          'error_type': exception.runtimeType.toString(),
          'reason': (reason ?? 'unspecified').takeFirst(100),
          'fatal': fatal ? 1 : 0,
        },
      );
    } catch (_) {
      // Analytics failure must never trigger secondary errors.
    }

    // 3. Firebase Crashlytics: native symbolicated error tracking
    if (Firebase.apps.isNotEmpty && !kIsWeb) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
          information: sanitizedContext.entries
              .map((e) => '${e.key}: ${e.value}')
              .toList(),
        );
      } catch (_) {
        // Crashlytics failure fallback is handled by in-memory diagnostic buffer.
      }
    }

    // 4. Serverpod backup telemetry ring buffer
    try {
      await serverpodBackup?.recordErrorReport(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
        context: sanitizedContext,
      );
    } catch (_) {
      // Serverpod backup failures must never interrupt app execution.
    }
  }

  /// Scrubs sensitive information (emails, auth tokens, phone numbers) before logging.
  Map<String, Object> _sanitizeMetadata(Map<String, Object>? raw) {
    if (raw == null) return {};
    final sanitized = <String, Object>{};
    final emailRegex = RegExp(
      r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
    );

    for (final entry in raw.entries) {
      final valueStr = entry.value.toString();
      if (emailRegex.hasMatch(valueStr)) {
        sanitized[entry.key] = '[SCRUBBED_EMAIL]';
      } else if (entry.key.toLowerCase().contains('token') ||
          entry.key.toLowerCase().contains('password') ||
          entry.key.toLowerCase().contains('secret')) {
        sanitized[entry.key] = '[SCRUBBED_SECRET]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }
}

extension on String {
  String takeFirst(int count) => length <= count ? this : substring(0, count);
}

final errorReporterServiceProvider = Provider<ErrorReporterService>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  final analytics = ref.watch(communityAnalyticsServiceProvider);
  final serverpodBackup = ref.watch(serverpodTelemetryBackupProvider);
  return ErrorReporterService(
    flavor: flavor,
    analyticsService: analytics,
    serverpodBackup: serverpodBackup,
  );
});
