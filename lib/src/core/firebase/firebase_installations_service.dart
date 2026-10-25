import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

/// Service responsible for querying and caching the unique Firebase Installation ID (FID).
///
/// Firebase Installation IDs provide an unauthenticated, privacy-preserving device identifier
/// used across Firebase In-App Messaging, Remote Config device targeting, and Crashlytics/FCM.
/// This enables troubleshooting and device-specific telemetry without requiring personal user accounts.
class FirebaseInstallationsService {
  FirebaseInstallationsService({FirebaseInstallations? installations})
    : _installations = installations;

  final FirebaseInstallations? _installations;
  String? _cachedId;

  FirebaseInstallations get _instance =>
      _installations ?? FirebaseInstallations.instance;

  /// Retrieves the unique Firebase Installation ID.
  ///
  /// Falls back to a deterministic fallback string if Firebase is uninitialized or in mock mode.
  Future<String> getInstallationsId() async {
    if (_cachedId != null) {
      return _cachedId!;
    }

    if (Firebase.apps.isEmpty) {
      _cachedId = 'fid_offline_mock_device';
      talker.debug(
        '🔥 [INSTALLATIONS] Firebase uninitialized. Using fallback ID: $_cachedId',
      );
      return _cachedId!;
    }

    try {
      final id = await _instance.getId();
      _cachedId = id;
      talker.info('🔥 [INSTALLATIONS] Fetched Firebase Installation ID: $id');
      return id;
    } catch (e, st) {
      talker.warning(
        '⚠️ [INSTALLATIONS] Failed to retrieve Firebase Installation ID: $e',
        e,
        st,
      );
      _cachedId = 'fid_fallback_${e.runtimeType.toString().toLowerCase()}';
      return _cachedId!;
    }
  }

  /// Deletes the current Firebase Installation ID and resets the cached state.
  Future<void> deleteInstallation() async {
    _cachedId = null;
    if (Firebase.apps.isNotEmpty) {
      try {
        await _instance.delete();
        talker.info('🔥 [INSTALLATIONS] Firebase Installation ID deleted.');
      } catch (e, st) {
        talker.warning(
          '⚠️ [INSTALLATIONS] Error deleting Firebase Installation ID: $e',
          e,
          st,
        );
      }
    }
  }
}

/// Global provider for [FirebaseInstallationsService].
final firebaseInstallationsServiceProvider =
    Provider<FirebaseInstallationsService>(
      (ref) => FirebaseInstallationsService(),
    );

/// Reactive provider for the active Firebase Installation ID string.
final firebaseInstallationsIdProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(firebaseInstallationsServiceProvider);
  return await service.getInstallationsId();
});
