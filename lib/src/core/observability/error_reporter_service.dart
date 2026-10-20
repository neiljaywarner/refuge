import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/logging/app_logger.dart' as app_log;
import 'package:talker_flutter/talker_flutter.dart';

class ErrorReporterService {
  ErrorReporterService({
    required this.flavor,
    required this.analyticsService,
    Talker? talkerInstance,
  }) : talker = talkerInstance ?? app_log.talker;

  final AppFlavor flavor;
  final CommunityAnalyticsService analyticsService;
  final Talker talker;

  final List<Map<String, Object?>> recordedErrorsForTesting = [];

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

    if (fatal) {
      talker.critical('🚨 [ErrorReporter FATAL] $exception (Reason: $reason)', exception, stack);
    } else {
      talker.error('⚠️ [ErrorReporter HANDLED] $exception (Reason: $reason)', exception, stack);
    }

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
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
          information: sanitizedContext.entries.map((e) => '${e.key}: ${e.value}').toList(),
        );
      } catch (_) {
      }
    }
  }

  Map<String, Object> _sanitizeMetadata(Map<String, Object>? raw) {
    if (raw == null) return {};
    final sanitized = <String, Object>{};
    final emailRegex = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');

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
  return ErrorReporterService(flavor: flavor, analyticsService: analytics);
});
