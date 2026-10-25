import 'dart:async';
import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/logging/app_logger.dart';
import 'package:refuge4serverpod/src/core/observability/serverpod_telemetry_backup.dart';

/// Privacy-safe, zero-PII multi-vendor telemetry engine backing:
/// 1. Firebase Analytics (Google Analytics 4 & DebugView)
/// 2. Aptabase (Open-source privacy-first analytics)
/// 3. PostHog (Product analytics, event funnels, and session insights)
/// 4. Serverpod Diagnostics ring buffer
///
/// Dispatches via fire-and-forget [unawaited] tasks so UI rendering is NEVER
/// blocked by network transport latency.
///
/// Ingests runtime keys strictly via build-time `--dart-define` (`APTABASE_KEY`,
/// `POSTHOG_KEY`, `POSTHOG_HOST`) or environment variables, eliminating
/// any hardcoded secrets in the repository. Operates in safe in-memory mock mode
/// during headless test execution.
class CommunityAnalyticsService {
  CommunityAnalyticsService({
    required this.flavor,
    this.serverpodBackup,
    http.Client? httpClient,
    this.aptabaseKeyOverride,
    this.postHogKeyOverride,
    this.postHogHostOverride,
    this.automationToolOverride,
  }) : _httpClient = httpClient ?? http.Client();

  final AppFlavor flavor;
  final ServerpodTelemetryBackup? serverpodBackup;
  final http.Client _httpClient;
  final String? aptabaseKeyOverride;
  final String? postHogKeyOverride;
  final String? postHogHostOverride;

  /// Test-only stand-in for `--dart-define=AUTOMATION_TOOL=...`.
  final String? automationToolOverride;

  /// Default Aptabase App-Key read from build-time `--dart-define`.
  static const String kDefaultAptabaseKey = String.fromEnvironment(
    'APTABASE_KEY',
    defaultValue: String.fromEnvironment('APTABASE_BELONG_KEY', defaultValue: ''),
  );

  /// Default PostHog API Key / Project Token read from `--dart-define`.
  static const String kDefaultPostHogKey = String.fromEnvironment(
    'POSTHOG_KEY',
    defaultValue: String.fromEnvironment('POSTHOG_BELONG_PROJECT_TOKEN', defaultValue: ''),
  );

  /// Default PostHog Ingestion Host (defaults to US Cloud).
  static const String kDefaultPostHogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  String get effectiveAptabaseKey => aptabaseKeyOverride ?? kDefaultAptabaseKey;
  String get effectivePostHogKey => postHogKeyOverride ?? kDefaultPostHogKey;
  String get effectivePostHogHost => postHogHostOverride ?? kDefaultPostHogHost;

  final List<Map<String, Object>> recordedEventsForTesting = [];

  /// In-memory testing hook alias for verifying dispatched analytics events.
  List<Map<String, Object>> get dispatchedEventsForTesting => recordedEventsForTesting;

  /// Dispatches a telemetry event across all configured analytics destinations.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    const automationToolEnv = String.fromEnvironment('AUTOMATION_TOOL', defaultValue: '');
    final automationToolName = (automationToolOverride ?? automationToolEnv).trim();
    final isAutomationTool = automationToolName.isNotEmpty;

    final enriched = <String, Object>{
      'flavor': flavor.slug,
      'environment': kReleaseMode ? 'release' : 'debug',
      'platform': defaultTargetPlatform.name,
      'is_debug_mode': kDebugMode,
      'automation_tool': isAutomationTool,
      if (isAutomationTool) 'automation_tool_name': automationToolName,
      ...?parameters,
    };
    recordedEventsForTesting.add({'name': name, ...enriched});

    talker.info(
      '📊 [ANALYTICS] Event "$name" triggered (flavor: ${flavor.slug}) | Parameters: $enriched',
    );

    // 1. Dual-dispatch to Serverpod backup ring buffer (fire-and-forget)
    if (serverpodBackup != null) {
      unawaited(
        serverpodBackup!.recordAnalyticsEvent(name, parameters: enriched).catchError((_) {}),
      );
    }

    // 2. Dispatch to Firebase Analytics (fire-and-forget).
    // FA event params must be String or num; PostHog keeps native booleans.
    if (Firebase.apps.isNotEmpty) {
      unawaited(
        FirebaseAnalytics.instance
            .logEvent(name: name, parameters: _firebaseEventParameters(enriched))
            .then((_) {
              talker.debug('🔥 [FIREBASE ANALYTICS] Event "$name" logged to Firebase.');
            })
            .catchError((e) {
              talker.warning('⚠️ [FIREBASE ANALYTICS] Failed to log event "$name": $e');
            }),
      );
    } else {
      talker.debug(
        '🔥 [FIREBASE ANALYTICS] Firebase apps empty / uninitialized. In-memory mock mode.',
      );
    }

    // 3. Dispatch to Aptabase Privacy-First Analytics (fire-and-forget unawaited)
    unawaited(_dispatchAptabase(name, enriched));

    // 4. Dispatch to PostHog Product Analytics (fire-and-forget unawaited)
    unawaited(_dispatchPostHog(name, enriched));
  }

  Future<void> _dispatchAptabase(String name, Map<String, Object> props) async {
    final key = effectiveAptabaseKey;
    if (key.isEmpty) {
      talker.debug(
        '📈 [APTABASE] Key not configured (--dart-define=APTABASE_KEY). Safe mock mode.',
      );
      return;
    }

    try {
      final url = Uri.parse('https://us.aptabase.com/api/v0/event');
      final payload = {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'sessionId': 'session-belong-${flavor.slug}',
        'eventName': name,
        'systemProps': {
          'isDebug': kDebugMode,
          'osName': defaultTargetPlatform.name,
          'locale': 'en-US',
          'appVersion': '0.8.0',
          'appBuildNumber': '1',
          'sdkVersion': 'aptabase_flutter@0.5.0',
        },
        'props': props,
      };

      final response = await _httpClient.post(
        url,
        headers: {'App-Key': key, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        talker.info('📈 [APTABASE] Event "$name" sent successfully (HTTP ${response.statusCode})');
      } else {
        talker.warning('⚠️ [APTABASE] Non-2xx response (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      talker.warning('⚠️ [APTABASE] Network transport error: $e');
    }
  }

  Future<void> _dispatchPostHog(String name, Map<String, Object> props) async {
    final key = effectivePostHogKey;
    if (key.isEmpty) {
      talker.debug(
        '🦔 [POSTHOG] Token not configured (--dart-define=POSTHOG_KEY). Safe mock mode.',
      );
      return;
    }

    try {
      final host = effectivePostHogHost.endsWith('/')
          ? effectivePostHogHost.substring(0, effectivePostHogHost.length - 1)
          : effectivePostHogHost;
      final url = Uri.parse('$host/capture/');

      final payloads = <Map<String, Object>>[
        {'api_key': key, 'event': name, 'properties': _postHogProperties(props)},
      ];
      final pathname = _pageviewPathname(name, props);
      if (pathname != null) {
        payloads.add({
          'api_key': key,
          'event': r'$pageview',
          'properties': _postHogProperties({
            ...props,
            r'$pathname': pathname,
            r'$current_url': _pageviewUrl(pathname),
            r'$host': _pageviewHost,
          }),
        });
      }

      for (final payload in payloads) {
        final eventName = payload['event'] as String;
        final response = await _httpClient.post(
          url,
          headers: {'Content-Type': 'application/json', 'User-Agent': 'RefugeAnalytics/1.0.0'},
          body: jsonEncode(payload),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          talker.info(
            '🦔 [POSTHOG] Event "$eventName" sent successfully '
            '(HTTP ${response.statusCode})',
          );
        } else {
          talker.warning(
            '⚠️ [POSTHOG] Non-2xx response (${response.statusCode}): '
            '${response.body}',
          );
        }
      }
    } catch (e) {
      talker.warning('⚠️ [POSTHOG] Network transport error: $e');
    }
  }

  /// Firebase Analytics event parameters accept only String or num.
  static Map<String, Object> _firebaseEventParameters(Map<String, Object> props) => {
    for (final entry in props.entries)
      entry.key: switch (entry.value) {
        final bool flag => flag.toString(),
        final value => value,
      },
  };

  /// Anonymous distinct id plus `$set` user properties. No emails or names.
  Map<String, Object> _postHogProperties(Map<String, Object> props) {
    final isDebugMode = props['is_debug_mode'] == true;
    final isAutomationTool = props['automation_tool'] == true;
    return {
      'distinct_id': 'belong-anon-${flavor.slug}',
      r'$set': <String, Object>{'is_debug_mode': isDebugMode, 'automation_tool': isAutomationTool},
      ...props,
    };
  }

  /// Anonymous path for PostHog web analytics. No member ids or emails.
  static String? _pageviewPathname(String name, Map<String, Object> props) {
    switch (name) {
      case 'space_viewed':
        return '/spaces/${props['space_slug'] ?? 'unknown'}';
      case 'bottom_tab_selected':
        return '/tab/${props['tab'] ?? 'unknown'}';
      case 'screen_view':
        return '/screen/${props['screen_name'] ?? 'unknown'}';
      default:
        return null;
    }
  }

  static String get _pageviewHost {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return host;
    }
    return 'belongonthespectrum.web.app';
  }

  static String _pageviewUrl(String pathname) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return '$origin$pathname';
      }
    }
    return 'https://belongonthespectrum.web.app$pathname';
  }

  Future<void> logSpaceViewed(String spaceSlug) =>
      logEvent('space_viewed', parameters: {'space_slug': spaceSlug});

  Future<void> logSensoryModeChanged(String modeName) =>
      logEvent('sensory_theme_changed', parameters: {'sensory_mode': modeName});

  Future<void> logBottomTabSelected(String tabName) =>
      logEvent('bottom_tab_selected', parameters: {'tab': tabName});

  Future<void> logScreenView(String screenName) =>
      logEvent('screen_view', parameters: {'screen_name': screenName});

  Future<void> logVoteCast(String featureId) =>
      logEvent('vote_cast', parameters: {'feature_id': featureId});

  Future<void> logFeedbackIntent(String sentimentLabel) =>
      logEvent('feedback_intent_selected', parameters: {'sentiment': sentimentLabel});

  Future<void> logReflectionPublished({required String tag, required int lengthBucket}) =>
      logEvent('reflection_published', parameters: {'tag': tag, 'length_bucket': lengthBucket});

  Future<void> logEventRsvp({required String eventId, required String status}) =>
      logEvent('event_rsvp', parameters: {'event_id': eventId, 'status': status});
}

final communityAnalyticsServiceProvider = Provider<CommunityAnalyticsService>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  final serverpodBackup = ref.watch(serverpodTelemetryBackupProvider);
  return CommunityAnalyticsService(flavor: flavor, serverpodBackup: serverpodBackup);
});
