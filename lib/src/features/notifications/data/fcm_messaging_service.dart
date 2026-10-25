import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/community_analytics_service.dart';
import '../domain/calm_push_payload.dart';
import 'calm_local_notification_service.dart';

/// Wires FCM foreground/background handlers to calm local shade notifications (#382).
class FcmMessagingService {
  FcmMessagingService({
    FirebaseMessaging? messaging,
    CalmLocalNotificationService? localNotifications,
    CommunityAnalyticsService? analytics,
    this.onPayloadReceived,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? createCalmLocalNotificationService(),
        _analytics = analytics;

  final FirebaseMessaging _messaging;
  final CalmLocalNotificationService _localNotifications;
  final CommunityAnalyticsService? _analytics;
  final Future<void> Function(Map<String, dynamic> data)? onPayloadReceived;

  /// Registered after startup so the Riverpod [NotificationSyncService] can
  /// receive foreground payloads from the process-wide FCM listener (#530).
  static Future<void> Function(Map<String, dynamic> data)? cloudPayloadHandler;

  static bool _handlersRegistered = false;

  static Future<void> ensureInitialized({
    CommunityAnalyticsService? analytics,
  }) async {
    if (kIsWeb) return;
    if (_handlersRegistered) return;
    _handlersRegistered = true;

    final service = FcmMessagingService(analytics: analytics);
    await service._wireHandlers();
  }

  Future<void> _wireHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_logOpenedFromBackground);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _logOpenedFromBackground(initial);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final display = calmPushDisplayFromParts(
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
      data: message.data,
    );

    await _localNotifications.showCalmDigest(
      title: display.title,
      body: display.body,
      payload: display.category,
    );

    final handler = onPayloadReceived ?? cloudPayloadHandler;
    if (handler != null) {
      await handler(message.data);
    }

    await _analytics?.logEvent(
      'fcm_message_received',
      parameters: {
        'app_state': 'foreground',
        'category': display.category ?? 'unknown',
      },
    );
  }

  void _logOpenedFromBackground(RemoteMessage message) {
    final category = message.data['category']?.toString() ?? 'unknown';
    _analytics?.logEvent(
      'fcm_message_opened',
      parameters: {
        'category': category,
      },
    );
  }
}
