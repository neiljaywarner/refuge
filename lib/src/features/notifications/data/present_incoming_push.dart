import 'calm_local_notification_service.dart';

/// A direct message that is not marked quiet uses the sound channel.
/// Everything else stays on the quiet digest.
enum IncomingPushKind { standardMessage, quietDigest }

IncomingPushKind incomingPushKind(Map<String, dynamic> data) {
  final isDirectMessage =
      data['type'] == 'direct_message' || data['category'] == 'direct_message';
  final quiet = data['quiet'] == 'true';
  if (isDirectMessage && !quiet) return IncomingPushKind.standardMessage;
  return IncomingPushKind.quietDigest;
}

/// Shows one OS notification for an incoming push. Callers that already
/// received a notification payload should not call this.
Future<void> presentIncomingPush({
  required CalmLocalNotificationService notifications,
  required Map<String, dynamic> data,
  required String title,
  required String body,
  String? payload,
}) {
  if (incomingPushKind(data) == IncomingPushKind.standardMessage) {
    return notifications.showMessageNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
  return notifications.showCalmDigest(
    title: title,
    body: body,
    payload: payload,
  );
}
