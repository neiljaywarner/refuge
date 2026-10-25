import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../logging/app_logger.dart';
import 'in_app_messaging_service.dart';
import 'in_app_messaging_stub.dart';

/// Native mobile (Android & iOS) implementation of [InAppMessagingService]
/// backed by official [FirebaseInAppMessaging].
class MobileInAppMessagingService implements InAppMessagingService {
  MobileInAppMessagingService({FirebaseInAppMessaging? instance}) : _fiam = instance;

  FirebaseInAppMessaging? _fiam;

  FirebaseInAppMessaging get fiam => _fiam ??= FirebaseInAppMessaging.instance;

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<void> initialize() async {
    if (!isSupported) {
      talker.debug('📱 [FIAM Mobile] Platform not supported for native FIAM.');
      return;
    }
    if (Firebase.apps.isEmpty) {
      talker.debug('📱 [FIAM Mobile] Firebase uninitialized. Skipping FIAM activation.');
      return;
    }
    try {
      await fiam.setAutomaticDataCollectionEnabled(true);
      talker.info('🔥 [FIAM Mobile] Firebase In-App Messaging enabled successfully.');
    } catch (e, st) {
      talker.warning('⚠️ [FIAM Mobile] Failed to initialize FIAM: $e', e, st);
    }
  }

  @override
  Future<void> triggerEvent(String eventName) async {
    if (!isSupported || Firebase.apps.isEmpty) {
      talker.debug(
        '📱 [FIAM Mobile] triggerEvent("$eventName") skipped (unsupported/uninitialized).',
      );
      return;
    }
    try {
      await fiam.triggerEvent(eventName);
      talker.info('🔥 [FIAM Mobile] Triggered in-app message event: "$eventName"');
    } catch (e, st) {
      talker.warning('⚠️ [FIAM Mobile] Error triggering FIAM event "$eventName": $e', e, st);
    }
  }

  @override
  Future<void> setMessagesSuppressed(bool suppress) async {
    if (!isSupported || Firebase.apps.isEmpty) return;
    try {
      await fiam.setMessagesSuppressed(suppress);
      talker.info('🔥 [FIAM Mobile] Messages suppressed: $suppress');
    } catch (e, st) {
      talker.warning('⚠️ [FIAM Mobile] Error setting messages suppressed: $e', e, st);
    }
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    if (!isSupported || Firebase.apps.isEmpty) return;
    try {
      await fiam.setAutomaticDataCollectionEnabled(enabled);
      talker.info('🔥 [FIAM Mobile] Automatic data collection: $enabled');
    } catch (e, st) {
      talker.warning('⚠️ [FIAM Mobile] Error setting data collection: $e', e, st);
    }
  }
}

/// Factory function called by `in_app_messaging_service.dart` on io platforms.
InAppMessagingService createPlatformInAppMessagingService() {
  if (kIsWeb) {
    return StubInAppMessagingService();
  }
  return MobileInAppMessagingService();
}
