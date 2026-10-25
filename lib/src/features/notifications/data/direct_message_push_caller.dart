import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/appwrite/appwrite_config.dart';
import '../domain/calm_notification_preferences.dart';
import '../domain/direct_message_push_policy.dart';

/// Appwrite function that sends the notification. Public id, not a secret.
const directMessagePushFunctionId = 'dm-push';

/// A delivered Firestore message is the only one that may ask for a card.
bool shouldRequestDirectMessagePush(String outcomeName) =>
    outcomeName == 'delivered';

/// Tells the Appwrite function about this phone, then returns.
/// Failures stay on the device. The message itself is already stored.
Future<void> registerDirectMessagePush(
  CalmNotificationPreferences prefs,
) async {
  final token = prefs.fcmToken;
  final acceptable = shouldSendDirectMessagePush(
    enabled: prefs.enabled,
    schedule: prefs.schedule.name,
    fcmToken: token,
  );
  await _execute(
    {
      'action': 'register',
      'enabled': prefs.enabled && prefs.schedule.name != 'muted',
      'schedule': prefs.schedule.name,
      'fcmToken': acceptable ? token : '',
    },
    waitForResponse: true,
  );
}

/// Asks the function to fan out a card for a message that Firestore accepted.
Future<void> requestDirectMessagePush(String messageId) async {
  if (messageId.trim().isEmpty) return;
  await _execute({'action': 'send', 'messageId': messageId});
}

Future<void> _execute(
  Map<String, Object?> body, {
  bool waitForResponse = false,
}) async {
  try {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;

    final config = AppwriteConfig.fromEnvironment;
    if (!config.isConfigured) return;

    final url = Uri.parse(
      '${config.endpoint.trim()}/functions/$directMessagePushFunctionId/executions',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': config.projectId.trim(),
      },
      body: jsonEncode({
        'body': jsonEncode({...body, 'idToken': idToken}),
        'async': !waitForResponse,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('dm-push http ${response.statusCode}');
      return;
    }

    if (waitForResponse) {
      final outer = jsonDecode(response.body) as Map<String, dynamic>;
      final status = outer['responseStatusCode'];
      final responseBody = (outer['responseBody'] ?? '').toString().replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_\-.]+'),
        '[token]',
      );
      debugPrint('dm-push register $status $responseBody');
    } else {
      debugPrint('dm-push request accepted');
    }
  } catch (error) {
    // The message remains in Firestore. A later send can try the card again.
    final raw = error.toString().replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_\-.]+'),
      '[token]',
    );
    final brief = raw.length > 160 ? raw.substring(0, 160) : raw;
    debugPrint('dm-push request failed: ${error.runtimeType} $brief');
  }
}
