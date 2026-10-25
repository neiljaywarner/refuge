import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/appwrite/appwrite_client_factory.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../domain/calm_notification_preferences.dart';
import '../domain/direct_message_push_policy.dart';

/// Appwrite function that sends the silent card. Public id, not a secret.
const directMessagePushFunctionId = 'dm-push';

/// A delivered Firestore message is the only one that may ask for a card.
bool shouldRequestDirectMessagePush(String outcomeName) => outcomeName == 'delivered';

/// Tells the Appwrite function about this phone, then returns.
/// Failures stay on the device. The message itself is already stored.
Future<void> registerDirectMessagePush(CalmNotificationPreferences prefs) async {
  final token = prefs.fcmToken;
  final acceptable = shouldSendDirectMessagePush(
    enabled: prefs.enabled,
    schedule: prefs.schedule.name,
    fcmToken: token,
  );
  await _execute({
    'action': 'register',
    'enabled': prefs.enabled && prefs.schedule.name != 'muted',
    'schedule': prefs.schedule.name,
    'fcmToken': acceptable ? token : '',
  });
}

/// Asks the function to fan out a card for a message that Firestore accepted.
Future<void> requestDirectMessagePush(String messageId) async {
  if (messageId.trim().isEmpty) return;
  await _execute({'action': 'send', 'messageId': messageId});
}

Future<void> _execute(Map<String, Object?> body) async {
  try {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;
    final services = createAppwriteServices(AppwriteConfig.fromEnvironment);
    if (services == null) return;
    await Functions(services.client).createExecution(
      functionId: directMessagePushFunctionId,
      body: jsonEncode({...body, 'idToken': idToken}),
      xasync: true,
    );
  } catch (_) {
    // The message remains in Firestore. A later send can try the card again.
  }
}
