import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';

void main() {
  group('CommunityAnalyticsService Multi-Vendor Telemetry Tests', () {
    test('Records in-memory events with flavor and environment when keys are absent', () async {
      final service = CommunityAnalyticsService(
        flavor: AppFlavor.dev,
        aptabaseKeyOverride: '',
        postHogKeyOverride: '',
      );

      await service.logSpaceViewed('quiet-gardens');

      expect(service.dispatchedEventsForTesting.length, 1);
      final event = service.dispatchedEventsForTesting.first;
      expect(event['name'], 'space_viewed');
      expect(event['flavor'], 'dev');
      expect(event['space_slug'], 'quiet-gardens');
      expect(event['is_debug_mode'], isNotNull);
      expect(event['automation_tool'], isNotNull);
    });

    test('Dispatches HTTP payload to Aptabase when Aptabase key is configured', () async {
      http.Request? capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{"ok": true}', 200);
      });

      final service = CommunityAnalyticsService(
        flavor: AppFlavor.prod,
        httpClient: mockClient,
        aptabaseKeyOverride: 'A-US-TEST-KEY',
        postHogKeyOverride: '',
      );

      await service.logSensoryModeChanged('sage');

      // Wait a tick for unawaited task
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.toString(), 'https://us.aptabase.com/api/v0/event');
      expect(capturedRequest!.headers['App-Key'], 'A-US-TEST-KEY');
      expect(capturedRequest!.headers['Content-Type'], 'application/json');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['eventName'], 'sensory_theme_changed');
      expect(body['props']['sensory_mode'], 'sage');
      expect(body['props']['flavor'], 'prod');
    });

    test('Dispatches HTTP payload to PostHog when PostHog key is configured', () async {
      final capturedRequests = <http.Request>[];

      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response('{"status": 1}', 200);
      });

      final service = CommunityAnalyticsService(
        flavor: AppFlavor.dev,
        httpClient: mockClient,
        aptabaseKeyOverride: '',
        postHogKeyOverride: 'phc_test_token_123',
        postHogHostOverride: 'https://us.i.posthog.com',
      );

      await service.logBottomTabSelected('Notifications');

      // Wait a tick for unawaited task
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(capturedRequests, isNotEmpty);
      expect(capturedRequests.first.url.toString(), 'https://us.i.posthog.com/capture/');
      expect(capturedRequests.first.headers['Content-Type'], 'application/json');

      final events = capturedRequests
          .map((request) => jsonDecode(request.body) as Map<String, dynamic>)
          .toList();
      expect(events.first['api_key'], 'phc_test_token_123');
      expect(events.first['event'], 'bottom_tab_selected');
      expect(events.first['properties']['tab'], 'Notifications');
      expect(events.first['properties']['flavor'], 'dev');
      expect(events.map((event) => event['event']), contains(r'$pageview'));
    });

    test('Handles HTTP non-200 or transport exceptions without throwing', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network down');
      });

      final service = CommunityAnalyticsService(
        flavor: AppFlavor.dev,
        httpClient: mockClient,
        aptabaseKeyOverride: 'A-US-TEST-KEY',
        postHogKeyOverride: 'phc_test_token_123',
      );

      // Must complete normally without throwing
      await expectLater(service.logVoteCast('feature-voice-rooms'), completes);

      expect(service.dispatchedEventsForTesting.length, 1);
      expect(service.dispatchedEventsForTesting.first['feature_id'], 'feature-voice-rooms');
    });
  });
}
