import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';

/// Stand-in project token for unit tests. It is not a live credential.
const _fakeCaptureKey = 'unit-test-capture-key';

void main() {
  group('PostHog capture gate', () {
    test(
      'an empty key records the event and does not call the network',
      () async {
        var networkCalls = 0;
        final client = MockClient((request) async {
          networkCalls += 1;
          return http.Response('unexpected', 500);
        });
        final service = CommunityAnalyticsService(
          flavor: AppFlavor.dev,
          httpClient: client,
          aptabaseKeyOverride: '',
          postHogKeyOverride: '',
        );

        await service.logSpaceViewed('quiet-gardens');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(networkCalls, 0);
        expect(service.effectivePostHogKey, isEmpty);
        expect(service.dispatchedEventsForTesting, hasLength(1));
        expect(
          service.dispatchedEventsForTesting.single['name'],
          'space_viewed',
        );
        expect(
          service.dispatchedEventsForTesting.single['space_slug'],
          'quiet-gardens',
        );
      },
    );

    test(
      'a fake test key builds a capture payload without a live token',
      () async {
        final captured = Completer<http.Request>();
        final client = MockClient((request) async {
          if (!captured.isCompleted) {
            captured.complete(request);
          }
          return http.Response('{"status":1}', 200);
        });
        final service = CommunityAnalyticsService(
          flavor: AppFlavor.dev,
          httpClient: client,
          aptabaseKeyOverride: '',
          postHogKeyOverride: _fakeCaptureKey,
          postHogHostOverride: 'https://example.test',
        );

        await service.logBottomTabSelected('Home');
        final request = await captured.future.timeout(
          const Duration(seconds: 2),
        );

        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://example.test/capture/');
        expect(request.headers['content-type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['api_key'], _fakeCaptureKey);
        expect(body['event'], 'bottom_tab_selected');

        final properties = body['properties'] as Map<String, dynamic>;
        expect(properties['distinct_id'], 'belong-anon-dev');
        expect(properties['tab'], 'Home');
        expect(properties['flavor'], 'dev');
        expect(properties['is_debug_mode'], isTrue);
        expect(properties['automation_tool'], isFalse);
        expect(properties[r'$set'], {
          'is_debug_mode': true,
          'automation_tool': false,
        });
        expect(properties.containsKey('email'), isFalse);
      },
    );

    test(
      'automation_tool override sets boolean event and user properties',
      () async {
        final captured = Completer<http.Request>();
        final client = MockClient((request) async {
          if (!captured.isCompleted) {
            captured.complete(request);
          }
          return http.Response('{"status":1}', 200);
        });
        final service = CommunityAnalyticsService(
          flavor: AppFlavor.dev,
          httpClient: client,
          aptabaseKeyOverride: '',
          postHogKeyOverride: _fakeCaptureKey,
          postHogHostOverride: 'https://example.test',
          automationToolOverride: 'maestro',
        );

        await service.logBottomTabSelected('Home');
        final request = await captured.future.timeout(
          const Duration(seconds: 2),
        );
        final properties =
            (jsonDecode(request.body) as Map<String, dynamic>)['properties']
                as Map<String, dynamic>;
        expect(properties['automation_tool'], isTrue);
        expect(properties['automation_tool_name'], 'maestro');
        expect(properties[r'$set'], {
          'is_debug_mode': true,
          'automation_tool': true,
        });
      },
    );

    test('space_viewed also sends an anonymous \$pageview companion', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"status":1}', 200);
      });
      final service = CommunityAnalyticsService(
        flavor: AppFlavor.dev,
        httpClient: client,
        aptabaseKeyOverride: '',
        postHogKeyOverride: _fakeCaptureKey,
        postHogHostOverride: 'https://example.test',
      );

      await service.logSpaceViewed('quiet-gardens');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(requests, hasLength(2));
      final events = requests
          .map((request) => jsonDecode(request.body) as Map<String, dynamic>)
          .toList();
      expect(events[0]['event'], 'space_viewed');
      expect(events[1]['event'], r'$pageview');
      final page = events[1]['properties'] as Map<String, dynamic>;
      expect(page['distinct_id'], 'belong-anon-dev');
      expect(page[r'$pathname'], '/spaces/quiet-gardens');
      expect(page[r'$current_url'], contains('/spaces/quiet-gardens'));
      expect(page['is_debug_mode'], isTrue);
      expect(page[r'$set'], {'is_debug_mode': true, 'automation_tool': false});
      expect(page.containsKey('email'), isFalse);
      expect(service.dispatchedEventsForTesting, hasLength(1));
    });
  });
}
