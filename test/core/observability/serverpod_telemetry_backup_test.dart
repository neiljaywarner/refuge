import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/community_analytics_service.dart';
import 'package:refuge4serverpod/src/core/observability/error_reporter_service.dart';
import 'package:refuge4serverpod/src/core/observability/serverpod_telemetry_backup.dart';

void main() {
  group('ServerpodTelemetryBackup Unit Tests', () {
    late ServerpodTelemetryBackup backup;

    setUp(() {
      backup = ServerpodTelemetryBackup(
        flavor: AppFlavor.dev,
        maxBufferSize: 5,
      );
    });

    test(
      'records analytics events into ring buffer with timestamp and flavor',
      () async {
        await backup.recordAnalyticsEvent(
          'space_viewed',
          parameters: {'space_slug': 'memes'},
        );

        expect(backup.recentRecords.length, 1);
        final record = backup.recentRecords.first;
        expect(record.name, 'space_viewed');
        expect(record.kind, TelemetryKind.analytics);
        expect(record.flavor, 'dev');
        expect(record.parameters['space_slug'], 'memes');
        expect(record.isFatal, isFalse);
      },
    );

    test('records handled errors and fatal crashes into ring buffer', () async {
      await backup.recordErrorReport(
        Exception('Network timed out'),
        StackTrace.current,
        reason: 'Serverpod connection reset',
        fatal: false,
      );

      expect(backup.recentRecords.length, 1);
      final handledRecord = backup.recentRecords.first;
      expect(handledRecord.kind, TelemetryKind.error);
      expect(handledRecord.name, contains('Network timed out'));
      expect(handledRecord.isFatal, isFalse);
      expect(handledRecord.parameters['reason'], 'Serverpod connection reset');

      await backup.recordErrorReport(
        StateError('Critical crash'),
        StackTrace.current,
        reason: 'Out of memory',
        fatal: true,
      );

      expect(backup.recentRecords.length, 2);
      final fatalRecord = backup.recentRecords.last;
      expect(fatalRecord.isFatal, isTrue);
      expect(fatalRecord.name, contains('Critical crash'));
    });

    test(
      'enforces maxBufferSize and evicts oldest items in FIFO order',
      () async {
        for (var i = 1; i <= 7; i++) {
          await backup.recordAnalyticsEvent(
            'event_$i',
            parameters: {'index': i},
          );
        }

        expect(backup.recentRecords.length, 5);
        expect(backup.recentRecords.first.name, 'event_3');
        expect(backup.recentRecords.last.name, 'event_7');
      },
    );

    test('serializes and deserializes TelemetryRecord cleanly', () {
      final record = TelemetryRecord(
        id: 'test_123',
        kind: TelemetryKind.error,
        name: 'DatabaseLocked',
        flavor: 'prod',
        timestamp: DateTime(2026, 10, 20, 20, 30),
        parameters: {'code': 500},
        isFatal: true,
        stackTraceSnippet: '#0 main.dart:42',
      );

      final map = record.toMap();
      final revived = TelemetryRecord.fromMap(map);

      expect(revived.id, 'test_123');
      expect(revived.kind, TelemetryKind.error);
      expect(revived.name, 'DatabaseLocked');
      expect(revived.flavor, 'prod');
      expect(revived.isFatal, isTrue);
      expect(revived.stackTraceSnippet, '#0 main.dart:42');
    });
  });

  group(
    'Dual-Dispatch Integration Tests with ErrorReporter & CommunityAnalytics',
    () {
      late ServerpodTelemetryBackup backup;
      late CommunityAnalyticsService analytics;
      late ErrorReporterService errorReporter;

      setUp(() {
        backup = ServerpodTelemetryBackup(flavor: AppFlavor.dev);
        analytics = CommunityAnalyticsService(
          flavor: AppFlavor.dev,
          serverpodBackup: backup,
        );
        errorReporter = ErrorReporterService(
          flavor: AppFlavor.dev,
          analyticsService: analytics,
          serverpodBackup: backup,
        );
      });

      test('logging an analytics event automatically populates Serverpod backup buffer', () async {
        await analytics.logVoteCast('custom_soundscapes');

        expect(backup.recentRecords.length, 1);
        final record = backup.recentRecords.first;
        expect(record.name, 'vote_cast');
        expect(record.parameters['feature_id'], 'custom_soundscapes');
      });

      test('recording an error automatically dual-dispatches to Serverpod backup buffer', () async {
        await errorReporter.recordError(
          Exception('Sync failure'),
          StackTrace.current,
          reason: 'Sync loop paused',
          fatal: false,
        );

        // Both the error and the 'app_error' analytics event are recorded in backup!
        expect(backup.recentRecords.length, greaterThanOrEqualTo(1));
        final errorRecord = backup.recentRecords.firstWhere(
          (r) => r.kind == TelemetryKind.error,
        );
        expect(errorRecord.name, contains('Sync failure'));
        expect(errorRecord.parameters['reason'], 'Sync loop paused');
      });
    },
  );
}
