import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/logging/app_logger.dart';

void main() {
  group('AppLogger Unit Tests', () {
    test('Logs debug, info, warning without throwing', () {
      expect(() => AppLogger.debug('Test debug message'), returnsNormally);
      expect(() => AppLogger.info('Test info message'), returnsNormally);
      expect(() => AppLogger.warning('Test warning message'), returnsNormally);
    });

    test(
      'Logs handled error and critical crash without throwing when Firebase is uninitialized',
      () {
        expect(
          () => AppLogger.error(
            'Test handled non-fatal error',
            Exception('Simulated non-fatal exception'),
            StackTrace.current,
            {'screen': 'unit_test', 'action': 'test_error'},
          ),
          returnsNormally,
        );

        expect(
          () => AppLogger.critical(
            'Test fatal crash event',
            Exception('Simulated fatal exception'),
            StackTrace.current,
            {'screen': 'unit_test', 'action': 'test_critical'},
          ),
          returnsNormally,
        );
      },
    );

    test('Talker history records AppLogger messages', () {
      final initialCount = talker.history.length;
      AppLogger.info('Verifying history recording');
      expect(talker.history.length, greaterThan(initialCount));
      expect(
        talker.history.any(
          (entry) => entry.message?.contains('Verifying history recording') ?? false,
        ),
        isTrue,
      );
    });
  });
}
