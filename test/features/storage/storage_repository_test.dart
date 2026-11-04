import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('FirebaseStorageRepository guards', () {
    test('isStorageEnabled defaults to false without dart define', () {
      expect(FirebaseStorageRepository.isStorageEnabled, isFalse);
    });

    test('uploadDiagnosticLogs throws UnsupportedError when storage is disabled', () async {
      final repo = FirebaseStorageRepository();
      expect(
        () => repo.uploadDiagnosticLogs(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'diagnostic.log',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Diagnostic log upload is paused'),
          ),
        ),
      );
    });

    test('uploadAvatar throws UnsupportedError when storage is disabled', () async {
      final repo = FirebaseStorageRepository();
      expect(
        () => repo.uploadAvatar(
          userId: 'user_123',
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'avatar.png',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Custom photo uploads are paused'),
          ),
        ),
      );
    });

    test('uploadPostMedia throws UnsupportedError when storage is disabled', () async {
      final repo = FirebaseStorageRepository();
      expect(
        () => repo.uploadPostMedia(
          spaceSlug: 'general_chat',
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'post.png',
        ),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            contains('Media upload is temporarily paused'),
          ),
        ),
      );
    });
  });
}
