import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';

class CommunityAnalyticsService {
  CommunityAnalyticsService({required this.flavor});

  final AppFlavor flavor;
  final List<Map<String, Object>> recordedEventsForTesting = [];

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final enriched = <String, Object>{'flavor': flavor.slug, ...?parameters};
    recordedEventsForTesting.add({'name': name, ...enriched});

    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: enriched);
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
  return CommunityAnalyticsService(flavor: flavor);
});
