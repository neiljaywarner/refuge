import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Central Talker logging service for visual debugging, RPC interception, and diagnostics.
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 1000,
    useConsoleLogs: true,
  ),
);

/// Thin static wrapper around [Talker] and [FirebaseCrashlytics] delivering
/// unified developer diagnostics and remote error tracking.
class AppLogger {
  const AppLogger._();

  /// Logs debug/trace message to Talker.
  static void debug(dynamic message, [Object? exception, StackTrace? stack]) {
    talker.debug(message, exception, stack);
  }

  /// Logs informative lifecycle event to Talker.
  static void info(dynamic message, [Object? exception, StackTrace? stack]) {
    talker.info(message, exception, stack);
  }

  /// Logs warning message to Talker.
  static void warning(dynamic message, [Object? exception, StackTrace? stack]) {
    talker.warning(message, exception, stack);
  }

  /// Logs handled non-fatal error to Talker and forwards to Firebase Crashlytics if available.
  static void error(
    dynamic message, [
    Object? exception,
    StackTrace? stack,
    Map<String, Object>? context,
  ]) {
    talker.error(message, exception, stack);

    // Forward non-fatal handled exception to Crashlytics if Firebase is initialized
    if (Firebase.apps.isNotEmpty) {
      try {
        final err = exception ?? Exception(message.toString());
        FirebaseCrashlytics.instance.recordError(
          err,
          stack,
          reason: message.toString(),
          fatal: false,
          information: context != null
              ? context.entries.map((e) => '${e.key}: ${e.value}').toList()
              : const [],
        );
      } catch (_) {
        // Crashlytics failure must never crash the logger
      }
    }
  }

  /// Logs critical fatal crash to Talker and forwards as fatal to Firebase Crashlytics.
  static void critical(
    dynamic message, [
    Object? exception,
    StackTrace? stack,
    Map<String, Object>? context,
  ]) {
    talker.critical(message, exception, stack);

    if (Firebase.apps.isNotEmpty) {
      try {
        final err = exception ?? Exception(message.toString());
        FirebaseCrashlytics.instance.recordError(
          err,
          stack,
          reason: message.toString(),
          fatal: true,
          information: context != null
              ? context.entries.map((e) => '${e.key}: ${e.value}').toList()
              : const [],
        );
      } catch (_) {
        // Crashlytics failure must never crash the logger
      }
    }
  }
}
