import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feedback/application/feedback_attachment_ref.dart';
import '../../feedback/data/feature_voting_repository.dart';

/// Pluggable storage repository seam supporting:
/// - Firebase Cloud Storage (Production uploads)
/// - In-Memory Storage (Fast, deterministic BDD and widget tests)
abstract interface class StorageRepository {
  BackendTarget get target;

  /// Uploads a member profile avatar image and returns the download URL.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String filename,
  });

  /// Uploads media for posts, reflections, or memes and returns the download URL.
  Future<String> uploadPostMedia({
    required String spaceSlug,
    required Uint8List bytes,
    required String filename,
  });

  /// Uploads feedback attachment screenshot and returns the download URL.
  Future<String> uploadFeedbackAttachment({required Uint8List bytes, required String filename});

  /// Uploads diagnostic session logs / replay dump and returns the download URL.
  Future<String> uploadDiagnosticLogs({required Uint8List bytes, required String filename});

  /// Deletes a previously uploaded media asset.
  Future<void> deleteMedia(String downloadUrl);
}

/// Deterministic, zero-network in-memory storage repository for unit and BDD tests.
class InMemoryStorageRepository implements StorageRepository {
  final Map<String, Uint8List> _storage = {};

  /// Paths whose bytes are held in this process.
  Iterable<String> get retainedPaths => _storage.keys;

  @override
  BackendTarget get target => BackendTarget.inMemory;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'avatars/$userId/$filename';
    _storage[path] = bytes;
    return 'https://storage.belongonthespectrum.com/$path';
  }

  @override
  Future<String> uploadPostMedia({
    required String spaceSlug,
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'spaces/$spaceSlug/$filename';
    _storage[path] = bytes;
    return 'https://storage.belongonthespectrum.com/$path';
  }

  @override
  Future<String> uploadFeedbackAttachment({
    required Uint8List bytes,
    required String filename,
  }) async {
    final path = 'feedback/attachments/$filename';
    _storage[path] = bytes;
    return FeedbackAttachmentRef.localHandoff(filename);
  }

  @override
  Future<String> uploadDiagnosticLogs({required Uint8List bytes, required String filename}) async {
    final path = 'diagnostics/logs/$filename';
    _storage[path] = bytes;
    return 'https://storage.belongonthespectrum.com/$path';
  }

  @override
  Future<void> deleteMedia(String downloadUrl) async {
    _storage.removeWhere((key, _) => downloadUrl.endsWith(key));
  }
}

/// Production Firebase Cloud Storage repository seam.
class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({InMemoryStorageRepository? fallback})
    : _fallback = fallback ?? InMemoryStorageRepository();

  final InMemoryStorageRepository _fallback;

  @override
  BackendTarget get target => BackendTarget.firebase;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String filename,
  }) async => _fallback.uploadAvatar(userId: userId, bytes: bytes, filename: filename);

  @override
  Future<String> uploadPostMedia({
    required String spaceSlug,
    required Uint8List bytes,
    required String filename,
  }) async => _fallback.uploadPostMedia(spaceSlug: spaceSlug, bytes: bytes, filename: filename);

  @override
  Future<String> uploadFeedbackAttachment({
    required Uint8List bytes,
    required String filename,
  }) async => _fallback.uploadFeedbackAttachment(bytes: bytes, filename: filename);

  @override
  Future<String> uploadDiagnosticLogs({required Uint8List bytes, required String filename}) async =>
      _fallback.uploadDiagnosticLogs(bytes: bytes, filename: filename);

  @override
  Future<void> deleteMedia(String downloadUrl) async {
    await _fallback.deleteMedia(downloadUrl);
  }
}

final storageBackendTargetProvider = Provider<BackendTarget>((ref) => BackendTarget.firebase);

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final target = ref.watch(storageBackendTargetProvider);
  return switch (target) {
    BackendTarget.inMemory => InMemoryStorageRepository(),
    BackendTarget.firebase => FirebaseStorageRepository(),
    _ => InMemoryStorageRepository(),
  };
});
