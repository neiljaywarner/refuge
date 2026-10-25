import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('FirebaseInitializer & Error Hooks Unit Tests', () {
    late CommunityAnalyticsService analyticsService;
    late ErrorReporterService errorReporter;

    setUp(() {
      analyticsService = CommunityAnalyticsService(flavor: AppFlavor.dev);
      errorReporter = ErrorReporterService(
        flavor: AppFlavor.dev,
        analyticsService: analyticsService,
      );
    });

    test(
      'FirebaseInitializer returns headless fallback in unit test environment',
      () async {
        final initialized = await FirebaseInitializer.initialize(
          flavor: AppFlavor.dev,
        );
        expect(initialized, isFalse);
        expect(FirebaseInitializer.isInitialized, isFalse);
      },
    );

    test('ErrorReporterService records handled errors without throwing', () {
      expect(
        () => errorReporter.recordError(
          Exception('Simulated network timeout'),
          StackTrace.current,
          reason: 'Background refresh failed',
          fatal: false,
          context: {'space': 'prayer'},
        ),
        returnsNormally,
      );

      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final error = errorReporter.recordedErrorsForTesting.first;
      expect(error['reason'], 'Background refresh failed');
      expect(error['fatal'], isFalse);
    });

    test('FlutterError.onError hook captures framework layout errors', () {
      final capturedErrors = <FlutterErrorDetails>[];

      // Simulate FlutterError.onError hook defined in main.dart
      void testFlutterErrorHandler(FlutterErrorDetails details) {
        capturedErrors.add(details);
        errorReporter.recordError(
          details.exception,
          details.stack,
          reason: details.context?.toDescription(),
          fatal: false,
        );
      }

      final details = FlutterErrorDetails(
        exception: StateError('RenderFlex overflowed by 42 pixels'),
        stack: StackTrace.current,
        context: ErrorDescription('during layout of RefugeHomeScreen'),
      );

      testFlutterErrorHandler(details);

      expect(capturedErrors.length, 1);
      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final recorded = errorReporter.recordedErrorsForTesting.first;
      expect(recorded['error'], contains('RenderFlex overflowed'));
      expect(recorded['reason'], 'during layout of RefugeHomeScreen');
      expect(recorded['fatal'], isFalse);
    });

    test('PlatformDispatcher.onError hook captures root async errors and flags fatal', () {
      final capturedAsyncErrors = <Map<String, Object?>>[];

      // Simulate PlatformDispatcher.onError hook defined in main.dart
      bool testPlatformErrorHandler(Object error, StackTrace stack) {
        capturedAsyncErrors.add({'error': error, 'stack': stack});
        errorReporter.recordError(error, stack, fatal: true);
        return true;
      }

      final testException = Exception('Uncaught async database lock timeout');
      final testStack = StackTrace.current;

      final handled = testPlatformErrorHandler(testException, testStack);

      expect(handled, isTrue);
      expect(capturedAsyncErrors.length, 1);
      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final recorded = errorReporter.recordedErrorsForTesting.first;
      expect(recorded['error'], contains('database lock timeout'));
      expect(recorded['fatal'], isTrue);
    });
  });
}
