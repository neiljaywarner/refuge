import '../../logging/app_logger.dart';
import 'in_app_messaging_service.dart';

/// Web, desktop, and headless test stub implementation of [InAppMessagingService].
class StubInAppMessagingService implements InAppMessagingService {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    talker.debug(
      '🌐 [FIAM Stub] In-App Messaging is not supported on Web/Desktop. Stub initialized.',
    );
  }

  @override
  Future<void> triggerEvent(String eventName) async {
    talker.debug(
      '🌐 [FIAM Stub] triggerEvent("$eventName") ignored on unsupported platform.',
    );
  }

  @override
  Future<void> setMessagesSuppressed(bool suppress) async {
    talker.debug(
      '🌐 [FIAM Stub] setMessagesSuppressed($suppress) ignored on unsupported platform.',
    );
  }

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    talker.debug(
      '🌐 [FIAM Stub] setAutomaticDataCollectionEnabled($enabled) ignored on unsupported platform.',
    );
  }
}

/// Factory function called by `in_app_messaging_service.dart` on Web or non-io platforms.
InAppMessagingService createPlatformInAppMessagingService() =>
    StubInAppMessagingService();
