import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_push_payload.dart';

void main() {
  group('calmPushDisplayFromParts', () {
    test('prefers notification title and body when present', () {
      final display = calmPushDisplayFromParts(
        notificationTitle: 'Belong',
        notificationBody: 'Quiet digest ready',
        data: const {'title': 'ignored', 'body': 'ignored'},
      );

      expect(display.title, 'Belong');
      expect(display.body, 'Quiet digest ready');
    });

    test('falls back to data payload fields', () {
      final display = calmPushDisplayFromParts(
        data: const {
          'title': 'Direct message',
          'snippet': 'Fellow Member: Thanks for joining',
          'category': 'dm',
        },
      );

      expect(display.title, 'Direct message');
      expect(display.body, 'Fellow Member: Thanks for joining');
      expect(display.category, 'dm');
    });

    test('uses calm defaults when payload is empty', () {
      final display = calmPushDisplayFromParts();

      expect(display.title, 'Belong');
      expect(display.body, contains('calm update'));
    });
  });
}
