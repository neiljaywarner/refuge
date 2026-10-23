import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../domain/calm_push_payload.dart';
import 'calm_local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  final notification = message.notification;
  final display = calmPushDisplayFromParts(
    notificationTitle: notification?.title,
    notificationBody: notification?.body,
    data: message.data,
  );

  await createCalmLocalNotificationService().showCalmDigest(
    title: display.title,
    body: display.body,
    payload: display.category,
  );
}
