import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/firebase/in_app_messaging/in_app_messaging_service.dart';
import 'package:refuge4serverpod/src/core/firebase/in_app_messaging/in_app_messaging_stub.dart';

void main() {
  group('InAppMessagingService Unit Tests', () {
    test(
      'StubInAppMessagingService reports unsupported and completes gracefully',
      () async {
        final service = StubInAppMessagingService();

        expect(service.isSupported, isFalse);

        // Verify all methods complete without throwing exceptions
        await expectLater(service.initialize(), completes);
        await expectLater(
          service.triggerEvent('new_member_orientation'),
          completes,
        );
        await expectLater(service.setMessagesSuppressed(true), completes);
        await expectLater(
          service.setAutomaticDataCollectionEnabled(false),
          completes,
        );
      },
    );

    test('createInAppMessagingService provides a valid service instance', () {
      final service = createInAppMessagingService();
      expect(service, isA<InAppMessagingService>());
    });
  });
}
