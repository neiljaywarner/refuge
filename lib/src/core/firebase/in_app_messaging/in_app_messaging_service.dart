import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'in_app_messaging_stub.dart' if (dart.library.io) 'in_app_messaging_mobile.dart' as impl;

/// Contract for Firebase In-App Messaging (FIAM) operations.
///
/// Firebase In-App Messaging is supported natively on Android and iOS.
/// On Web and desktop targets where FIAM is not supported by FlutterFire,
/// the service transparently falls back to a calm, no-op stub implementation
/// that prevents runtime crashes and allows headless testing.
abstract class InAppMessagingService {
  /// Whether In-App Messaging is active and supported on the current platform.
  bool get isSupported;

  /// Initializes the In-App Messaging runtime if supported.
  Future<void> initialize();

  /// Triggers a named contextual campaign event (e.g. 'new_member_welcome', 'quiet_room_opened').
  Future<void> triggerEvent(String eventName);

  /// Temporarily suppresses or unsuppresses display of in-app messages.
  Future<void> setMessagesSuppressed(bool suppress);

  /// Enables or disables automatic data collection for In-App Messaging.
  Future<void> setAutomaticDataCollectionEnabled(bool enabled);
}

/// Creates a platform-appropriate [InAppMessagingService] instance.
InAppMessagingService createInAppMessagingService() => impl.createPlatformInAppMessagingService();

/// Global Riverpod provider for [InAppMessagingService].
final inAppMessagingServiceProvider = Provider<InAppMessagingService>(
  (ref) => createInAppMessagingService(),
);
