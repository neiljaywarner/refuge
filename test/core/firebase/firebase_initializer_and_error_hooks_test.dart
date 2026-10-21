import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/firebase/firebase_initializer.dart';
import 'package:refuge4serverpod/src/core/observability/error_reporter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseInitializer Unit Tests', () {
    test('defines valid public webOptions for belongonthespectrum project', () {
      expect(FirebaseInitializer.webOptions.projectId, 'belongonthespectrum');
      expect(FirebaseInitializer.webOptions.messagingSenderId, '1056581413812');
      expect(FirebaseInitializer.webOptions.authDomain, 'belongonthespectrum.firebaseapp.com');
      expect(FirebaseInitializer.webOptions.storageBucket, 'belongonthespectrum.appspot.com');
    });

    test('initialize runs resiliently and reports initialization state', () async {
      // In headless test environments where native Firebase C++ bindings are mockable or unlinked,
      // initialize() must never throw unhandled exceptions and should report state.
      final result = await FirebaseInitializer.initialize(flavor: AppFlavor.dev);
      expect(result, isA<bool>());
    });
  });

  group('Main Global Error Hooks Unit Tests', () {
    late CommunityAnalyticsService analytics;
    late ErrorReporterService errorReporter;

    setUp(() {
      analytics = CommunityAnalyticsService(flavor: AppFlavor.dev);
      errorReporter = ErrorReporterService(
        flavor: AppFlavor.dev,
        analyticsService: analytics,
      );
    });

    test('FlutterError.onError hook captures framework exceptions and records them', () {
      final capturedErrors = <FlutterErrorDetails>[];

      // Simulate the FlutterError.onError hook defined in main.dart
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
        context: ErrorDescription('during layout of SanctuaryHomeScreen'),
      );

      testFlutterErrorHandler(details);

      expect(capturedErrors.length, 1);
      expect(errorReporter.recordedErrorsForTesting.length, 1);
      final recorded = errorReporter.recordedErrorsForTesting.first;
      expect(recorded['error'], contains('RenderFlex overflowed'));
      expect(recorded['reason'], 'during layout of SanctuaryHomeScreen');
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
