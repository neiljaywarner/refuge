import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';

/// Privacy-safe, zero-PII analytics service backed by [FirebaseAnalytics].
///
/// Automatically prefixes or tags events with the active [AppFlavor] (`dev` vs
/// `prod`) so developer testing never skews production community insights, and
/// operates as a safe no-op with in-memory event recording during unit/BDD tests.
class CommunityAnalyticsService {
  CommunityAnalyticsService({required this.flavor});

  final AppFlavor flavor;
  final List<Map<String, Object>> recordedEventsForTesting = [];

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    final enriched = <String, Object>{
      'flavor': flavor.slug,
      ...?parameters,
    };
    recordedEventsForTesting.add({'name': name, ...enriched});

    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: enriched,
      );
    } catch (_) {
      // Never surface analytics transport errors to community members.
    }
  }

  Future<void> logSpaceViewed(String spaceSlug) =>
      logEvent('space_viewed', parameters: {'space_slug': spaceSlug});

  Future<void> logSensoryModeChanged(String modeName) =>
      logEvent('sensory_theme_changed', parameters: {'sensory_mode': modeName});

  Future<void> logBottomTabSelected(String tabName) =>
      logEvent('bottom_tab_selected', parameters: {'tab': tabName});
}

final communityAnalyticsServiceProvider = Provider<CommunityAnalyticsService>((
  ref,
) {
  final flavor = ref.watch(appFlavorProvider);
  return CommunityAnalyticsService(flavor: flavor);
});
