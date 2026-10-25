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

    const quietChannel = AndroidNotificationChannel(
      kCalmDigestNotificationChannelId,
      'Calm digests',
      description: 'Quiet updates with no sound',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );
    const messageChannel = AndroidNotificationChannel(
      kDirectMessageChannelId,
      'Direct messages',
      description: 'Notifications when someone messages you',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(quietChannel);
    await androidPlugin?.createNotificationChannel(messageChannel);

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

  @override
  Future<void> showSilentNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      kCalmDigestNotificationChannelId,
      'Calm digests',
      channelDescription: 'Silent digests for messages and community updates',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      showWhen: true,
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

  @override
  Future<void> ensureChannels() => _ensureInitialized();

  @override
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      kDirectMessageChannelId,
      'Direct messages',
      channelDescription: 'Notifications when someone messages you',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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
