import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/firebase/firebase_installations_service.dart';

void main() {
  group('FirebaseInstallationsService Unit Tests', () {
    test('returns fallback installation ID when Firebase is uninitialized',
        () async {
      final service = FirebaseInstallationsService();

      final id1 = await service.getInstallationsId();
      expect(id1, isNotEmpty);
      expect(id1, contains('fid_offline_mock_device'));

      // Verify cached value is returned on subsequent calls
      final id2 = await service.getInstallationsId();
      expect(id2, equals(id1));
    });

    test('deleteInstallation resets cached installation ID', () async {
      final service = FirebaseInstallationsService();

      final id1 = await service.getInstallationsId();
      expect(id1, isNotEmpty);

      await service.deleteInstallation();

      // Fetches new fallback after deletion
      final id2 = await service.getInstallationsId();
      expect(id2, isNotEmpty);
    });
  });
}
