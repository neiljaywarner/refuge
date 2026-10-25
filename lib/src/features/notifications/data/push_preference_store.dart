import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/calm_notification_preferences.dart';
import '../domain/direct_message_push_policy.dart';
import 'direct_message_push_caller.dart';

const calmPushEnabledKey = 'calm_push_enabled';
const calmPushScheduleKey = 'calm_push_schedule';
const calmPushTokenKey = 'calm_push_token';

/// Owner-only Firestore doc the message function reads before sending FCM.
const pushPreferenceDocPath = 'notification_settings/push';

/// Remembers the switch on this phone, then writes the private cloud doc
/// when a member is signed in.
Future<void> savePushPreference(CalmNotificationPreferences prefs) async {
  await _saveLocal(prefs);
  if (Firebase.apps.isEmpty) return;
  User? user;
  try {
    user = FirebaseAuth.instance.currentUser;
  } catch (_) {
    return;
  }
  if (user == null) return;

  final token = shouldSendDirectMessagePush(
    enabled: true,
    schedule: prefs.schedule.name,
    fcmToken: prefs.fcmToken,
  )
      ? prefs.fcmToken
      : null;

  await FirebaseFirestore.instance
      .doc('users/${user.uid}/$pushPreferenceDocPath')
      .set({
    'enabled': prefs.enabled && prefs.schedule.name != 'muted',
    'schedule': prefs.schedule.name,
    'fcmToken': token,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  }, SetOptions(merge: true));
  await registerDirectMessagePush(prefs);
}

/// Reads the last switch position. Returns null when this phone has no
/// saved choice, including widget tests that have no preferences plugin.
Future<CalmNotificationPreferences?> readStoredPushPreference() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(calmPushEnabledKey)) return null;
    final scheduleName = prefs.getString(calmPushScheduleKey);
    var schedule = CalmDigestSchedule.twiceDaily;
    for (final item in CalmDigestSchedule.values) {
      if (item.name == scheduleName) schedule = item;
    }
    return CalmNotificationPreferences(
      enabled: prefs.getBool(calmPushEnabledKey) ?? false,
      schedule: schedule,
      fcmToken: prefs.getString(calmPushTokenKey),
    );
  } catch (_) {
    return null;
  }
}

Future<void> _saveLocal(CalmNotificationPreferences prefs) async {
  try {
    final stored = await SharedPreferences.getInstance();
    await stored.setBool(calmPushEnabledKey, prefs.enabled);
    await stored.setString(calmPushScheduleKey, prefs.schedule.name);
    final token = prefs.fcmToken;
    if (token == null || token.isEmpty) {
      await stored.remove(calmPushTokenKey);
    } else {
      await stored.setString(calmPushTokenKey, token);
    }
  } catch (_) {
    // Widget tests have no preferences plugin. The in-memory switch still works.
  }
}
