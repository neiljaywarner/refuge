import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/firebase_installations_service.dart';
import 'package:refuge4serverpod/src/core/observability/diagnostic_log_service.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('DiagnosticLogService & Session Replay Unit Tests', () {
    late InMemoryStorageRepository storage;
    late FirebaseInstallationsService installations;
    late DiagnosticLogService service;

    setUp(() {
      storage = InMemoryStorageRepository();
      installations = FirebaseInstallationsService();
      service = DiagnosticLogService(
        storageRepository: storage,
        installationsService: installations,
        flavor: AppFlavor.dev,
      );
    });

    test('records breadcrumbs and respects maximum buffer limit', () {
      expect(service.breadcrumbsForTesting, isEmpty);

      service.recordBreadcrumb(
        'opened_app',
        category: 'lifecycle',
        data: {'source': 'push'},
      );
      service.recordBreadcrumb('tapped_space', category: 'navigation');

      expect(service.breadcrumbsForTesting.length, equals(2));
      expect(service.breadcrumbsForTesting.first.name, equals('opened_app'));
      expect(service.breadcrumbsForTesting.first.category, equals('lifecycle'));

      // Test maximum capacity limit
      for (int i = 0; i < 110; i++) {
        service.recordBreadcrumb('action_$i');
      }
      expect(
        service.breadcrumbsForTesting.length,
        equals(DiagnosticLogService.maxBreadcrumbs),
      );
    });

    test('scrubs PII such as email addresses and secret keys from breadcrumbs',
        () {
      service.recordBreadcrumb(
        'user_login_attempt',
        category: 'auth',
        data: {
          'email': 'sensitive_pastor@example.com',
          'token_value': 'token: secret1234567890',
        },
      );

      final breadcrumb = service.breadcrumbsForTesting.last;
      expect(breadcrumb.data!['email'], equals('[REDACTED_EMAIL]'));
      expect(breadcrumb.data!['token_value'], contains('[REDACTED]'));
      expect(
        breadcrumb.data!['token_value'],
        isNot(contains('secret1234567890')),
      );
    });

    test('generates valid DiagnosticSessionReplay with JSON and formatted text',
        () async {
      service.recordBreadcrumb('entered_quiet_room', category: 'action');

      final replay = await service.generateReplayBundle(
        overrideInstallationsId: 'test_fid_12345',
      );

      expect(replay.sessionId, isNotEmpty);
      expect(replay.installationsId, equals('test_fid_12345'));
      expect(replay.flavor, equals('dev'));
      expect(replay.breadcrumbs.length, equals(1));

      final json = replay.toJson();
      expect(json['session_id'], equals(replay.sessionId));
      expect(json['installations_id'], equals('test_fid_12345'));
      expect(json['breadcrumbs'], isNotEmpty);

      final text = replay.toFormattedText();
      expect(text, contains('BELONG ON THE SPECTRUM - SESSION REPLAY'));
      expect(text, contains('Installation ID  : test_fid_12345'));
      expect(text, contains('entered_quiet_room'));
    });

    test('sendLogsToCloudStorage uploads session payload and returns download URL',
        () async {
      service.recordBreadcrumb('test_step_before_upload');

      final url = await service.sendLogsToCloudStorage(
        customStorage: storage,
        installationsId: 'mock_test_device_fid',
      );

      expect(url, isNotEmpty);
      expect(url, contains('storage.belongonthespectrum.com'));
      expect(url, contains('diagnostics/logs/session_'));
      expect(url, endsWith('.json'));
    });
  });
}