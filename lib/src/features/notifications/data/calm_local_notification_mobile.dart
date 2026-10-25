import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/calm_push_constants.dart';
import 'calm_local_notification_service.dart';

class CalmLocalNotificationMobile implements CalmLocalNotificationService {
  CalmLocalNotificationMobile() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    const channel = AndroidNotificationChannel(
      kCalmDigestNotificationChannelId,
      'Calm digests',
      description: 'Silent digests for messages and community updates',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  @override
  Future<void> showCalmDigest({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      kCalmDigestNotificationChannelId,
      'Calm digests',
      channelDescription: 'Silent digests for messages and community updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }
}

CalmLocalNotificationService createCalmLocalNotificationService() =>
    CalmLocalNotificationMobile();
