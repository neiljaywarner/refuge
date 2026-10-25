import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/observability/error_reporter_service.dart';

void main() {
  group('ErrorReporterService Triple-Observability Unit Tests', () {
    late CommunityAnalyticsService analytics;
    late ErrorReporterService errorReporter;

    setUp(() {
      analytics = CommunityAnalyticsService(flavor: AppFlavor.dev);
      errorReporter = ErrorReporterService(flavor: AppFlavor.dev, analyticsService: analytics);
    });

    test('records handled non-fatal error and logs to analytics and diagnostic buffer', () async {
      final exception = FormatException('Invalid JSON payload');
      final stack = StackTrace.current;

      await errorReporter.recordError(
        exception,
        stack,
        reason: 'Failed to parse circle cache',
        fatal: false,
        context: {'screen': 'home_feed', 'itemCount': 5},
      );

      // Verify diagnostic in-memory buffer
      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final recorded = errorReporter.recordedErrorsForTesting.first;
      expect(recorded['error'], contains('FormatException'));
      expect(recorded['reason'], 'Failed to parse circle cache');
      expect(recorded['fatal'], isFalse);

      // Verify analytics event logged
      expect(analytics.recordedEventsForTesting.length, 1);
      final event = analytics.recordedEventsForTesting.first;
      expect(event['name'], 'app_error');
      expect(event['error_type'], 'FormatException');
      expect(event['fatal'], 0);
    });

    test('scrubs PII such as email addresses and secret tokens before recording', () async {
      final exception = StateError('Authentication failed');

      await errorReporter.recordError(
        exception,
        StackTrace.empty,
        reason: 'User sign in failed',
        fatal: true,
        context: {
          'user_email': 'sensitive.member@example.org',
          'access_token': 'secret-token-xyz-123',
          'screen': 'profile_sheet',
        },
      );

      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final recorded = errorReporter.recordedErrorsForTesting.first;
      final context = recorded['context'] as Map<String, Object>;

      expect(context['user_email'], '[SCRUBBED_EMAIL]');
      expect(context['access_token'], '[SCRUBBED_SECRET]');
      expect(context['screen'], 'profile_sheet');
    });

    test('handles unhandled fatal errors gracefully with reason default', () async {
      await errorReporter.recordError('Critical out of memory', null, fatal: true);

      final recorded = errorReporter.recordedErrorsForTesting.first;
      expect(recorded['fatal'], isTrue);
      expect(recorded['reason'], 'unspecified');
    });
  });

  group('CommunityAnalyticsService v0.8.1 Event Suite Tests', () {
    late CommunityAnalyticsService analytics;

    setUp(() {
      analytics = CommunityAnalyticsService(flavor: AppFlavor.prod);
    });

    test('records domain-level screen views, voting, feedback, and RSVPs', () async {
      await analytics.logScreenView('actually_autistic_events');
      await analytics.logVoteCast('direct_messages_v1');
      await analytics.logFeedbackIntent('Works Great');
      await analytics.logReflectionPublished(tag: 'Prayer Request', lengthBucket: 120);
      await analytics.logEventRsvp(eventId: 'dfw_meetup_01', status: 'attending');

      expect(analytics.recordedEventsForTesting.length, 5);

      final names = analytics.recordedEventsForTesting.map((e) => e['name']).toList();
      expect(
        names,
        containsAll([
          'screen_view',
          'vote_cast',
          'feedback_intent_selected',
          'reflection_published',
          'event_rsvp',
        ]),
      );
    });
  });
}
