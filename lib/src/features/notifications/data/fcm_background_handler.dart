import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../domain/calm_push_payload.dart';
import 'calm_local_notification_service.dart';
import 'present_incoming_push.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  final notification = message.notification;
  // A notification payload is already posted by Android on the message channel.
  if (notification != null) return;

  final display = calmPushDisplayFromParts(
    notificationTitle: notification?.title,
    notificationBody: notification?.body,
    data: message.data,
  );

  await presentIncomingPush(
    notifications: createCalmLocalNotificationService(),
    data: message.data,
    title: display.title,
    body: display.body,
    payload: display.category,
  );
}
