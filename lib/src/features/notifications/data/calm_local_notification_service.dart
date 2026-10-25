import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'calm_local_notification_stub.dart'
    if (dart.library.io) 'calm_local_notification_mobile.dart' as impl;

/// Shows silent calm notifications in the OS shade (Android / future iOS).
abstract class CalmLocalNotificationService {
  Future<void> showCalmDigest({
    required String title,
    required String body,
    String? payload,
  });

  /// Displays an immediate silent notification in the OS notification shade (#530).
  Future<void> showSilentNotification({
    required String title,
    required String body,
    String? payload,
  });

  /// Creates the Android 8+ channels before the first push arrives.
  Future<void> ensureChannels();

  /// An ordinary direct-message notification: sound, shade, and a named channel.
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  });
}

/// Debug / QA preview without sending FCM (#382).
Future<void> showCalmPreviewDirectMessage(CalmLocalNotificationService service) =>
    service.showCalmDigest(
      title: 'Belong',
      body: 'Fellow Member sent you a direct message',
      payload: 'dm_preview',
    );

CalmLocalNotificationService createCalmLocalNotificationService() =>
    impl.createCalmLocalNotificationService();

final calmLocalNotificationServiceProvider = Provider<CalmLocalNotificationService>((ref) {
  return createCalmLocalNotificationService();
});
