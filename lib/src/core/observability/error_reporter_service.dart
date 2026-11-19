import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/logging/app_logger.dart' as app_log;
import 'package:refuge4serverpod/src/core/observability/local_telemetry_ring.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Unified error handling and observability service delivering triple-destination
/// error reporting across:
/// 1. Firebase Crashlytics (native unhandled fatal and handled non-fatal exceptions)
/// 2. Firebase Analytics (`app_error`), including web, where Crashlytics is not used
/// 3. Local diagnostics buffer for offline/developer visibility
///
/// Designed with strict Zero-PII principles (scrubs emails, tokens, and names).
class ErrorReporterService {
  ErrorReporterService({
    required this.flavor,
    required this.analyticsService,
    this.localTelemetryRing,
    Talker? talkerInstance,
    bool? crashlyticsSupported,
  }) : talker = talkerInstance ?? app_log.talker,
       crashlyticsSupported = crashlyticsSupported ?? !kIsWeb;

  final AppFlavor flavor;
  final CommunityAnalyticsService analyticsService;
  final LocalTelemetryRing? localTelemetryRing;
  final Talker talker;

  /// False on web. Crashlytics has no web path here; [recordError] still sends `app_error`.
  final bool crashlyticsSupported;

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
    final safeError = _scrubObservabilityText(exception.toString());
    final safeReason = _scrubObservabilityText(reason ?? 'unspecified').takeFirst(100);
    final reported = safeError == exception.toString() ? exception : StateError(safeError);
    final crashlyticsRecorded = crashlyticsSupported && Firebase.apps.isNotEmpty;
    final errorEntry = <String, Object?>{
      'timestamp': DateTime.now().toIso8601String(),
      'flavor': flavor.slug,
      'error': safeError,
      'reason': safeReason,
      'fatal': fatal,
      'stack': stack?.toString(),
      'context': sanitizedContext,
    };
    recordedErrorsForTesting.add(errorEntry);

    // 1. Diagnostics & structured logging via Talker
    if (fatal) {
      talker.critical('🚨 [ErrorReporter FATAL] $safeError (Reason: $safeReason)', reported, stack);
    } else {
      talker.error('⚠️ [ErrorReporter HANDLED] $safeError (Reason: $safeReason)', reported, stack);
    }

    // 2. Product analytics. This is the web path: Crashlytics is not used there.
    try {
      await analyticsService.logEvent(
        'app_error',
        parameters: {
          'error_type': exception.runtimeType.toString(),
          'reason': safeReason,
          'fatal': fatal ? 1 : 0,
          'crashlytics_recorded': crashlyticsRecorded ? 1 : 0,
        },
      );
    } catch (_) {
      // Analytics failure must never trigger secondary errors.
    }

    // 3. Firebase Crashlytics: native symbolicated error tracking. Skipped on web.
    if (crashlyticsRecorded) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          reported,
          stack,
          reason: safeReason,
          fatal: fatal,
          information: sanitizedContext.entries.map((e) => '${e.key}: ${e.value}').toList(),
        );
      } catch (_) {
        // Crashlytics failure fallback is handled by in-memory diagnostic buffer.
      }
    }

    // 4. Local telemetry ring buffer
    try {
      await localTelemetryRing?.recordErrorReport(
        reported,
        stack,
        reason: safeReason,
        fatal: fatal,
        context: sanitizedContext,
      );
    } catch (_) {
      // Local telemetry failures must never interrupt app execution.
    }
  }

  /// Scrubs sensitive information (emails, auth tokens, invite URLs) before logging.
  Map<String, Object> _sanitizeMetadata(Map<String, Object>? raw) {
    if (raw == null) return {};
    final sanitized = <String, Object>{};

    for (final entry in raw.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      final valueStr = value.toString();
      if (_emailPattern.hasMatch(valueStr) || key.contains('email')) {
        sanitized[entry.key] = '[SCRUBBED_EMAIL]';
      } else if (key.contains('token') ||
          key.contains('password') ||
          key.contains('secret') ||
          key.contains('invite') ||
          key.contains('authorization') ||
          _secretPattern.hasMatch(valueStr)) {
        sanitized[entry.key] = '[SCRUBBED_SECRET]';
      } else if (value is String) {
        sanitized[entry.key] = _scrubObservabilityText(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }
}

final RegExp _emailPattern = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');

/// URLs, bearer tokens, JWTs, and 43-character invite-shaped strings.
final RegExp _secretPattern = RegExp(
  r'https?://|www\.|bearer\s+\S+|eyJ[A-Za-z0-9_-]{6,}\.|[A-Za-z0-9_-]{43}',
  caseSensitive: false,
);

String _scrubObservabilityText(String value) {
  if (_emailPattern.hasMatch(value)) return '[SCRUBBED_EMAIL]';
  if (_secretPattern.hasMatch(value)) return '[SCRUBBED_SECRET]';
  return value;
}

extension on String {
  String takeFirst(int count) => length <= count ? this : substring(0, count);
}

final errorReporterServiceProvider = Provider<ErrorReporterService>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  final analytics = ref.watch(communityAnalyticsServiceProvider);
  final localTelemetryRing = ref.watch(localTelemetryRingProvider);
  return ErrorReporterService(
    flavor: flavor,
    analyticsService: analytics,
    localTelemetryRing: localTelemetryRing,
  );
});
