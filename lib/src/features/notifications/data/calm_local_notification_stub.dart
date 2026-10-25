import 'calm_local_notification_service.dart';

class CalmLocalNotificationStub implements CalmLocalNotificationService {
  CalmLocalNotificationStub({this.onShow});

  final void Function({required String title, required String body, String? payload})? onShow;

  int showCount = 0;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> showCalmDigest({
    required String title,
    required String body,
    String? payload,
  }) async {
    showCount++;
    lastTitle = title;
    lastBody = body;
    onShow?.call(title: title, body: body, payload: payload);
  }

  @override
  Future<void> showSilentNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    showCount++;
    lastTitle = title;
    lastBody = body;
    onShow?.call(title: title, body: body, payload: payload);
  }

  @override
  Future<void> ensureChannels() async {}

  @override
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    showCount++;
    lastTitle = title;
    lastBody = body;
    onShow?.call(title: title, body: body, payload: payload);
  }
}

CalmLocalNotificationService createCalmLocalNotificationService() =>
    CalmLocalNotificationStub();
