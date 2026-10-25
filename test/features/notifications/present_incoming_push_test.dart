import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/present_incoming_push.dart';

class MockCalmLocalNotificationService extends Mock implements CalmLocalNotificationService {}

void main() {
  late MockCalmLocalNotificationService notifications;

  setUp(() {
    notifications = MockCalmLocalNotificationService();
    when(
      () => notifications.showMessageNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => notifications.showCalmDigest(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  test('an ordinary direct message uses the sound notification', () async {
    await presentIncomingPush(
      notifications: notifications,
      data: const {'type': 'direct_message', 'quiet': 'false'},
      title: 'Belong',
      body: 'Fellow Member sent you a direct message: "hello"',
      payload: 'direct_message',
    );

    verify(
      () => notifications.showMessageNotification(
        title: 'Belong',
        body: 'Fellow Member sent you a direct message: "hello"',
        payload: 'direct_message',
      ),
    ).called(1);
    verifyNever(
      () => notifications.showCalmDigest(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('Immediate Gentle Cards stays on the quiet digest', () async {
    await presentIncomingPush(
      notifications: notifications,
      data: const {'category': 'direct_message', 'quiet': 'true'},
      title: 'Belong',
      body: 'Fellow Member sent you a direct message',
      payload: 'direct_message',
    );

    verify(
      () => notifications.showCalmDigest(
        title: 'Belong',
        body: 'Fellow Member sent you a direct message',
        payload: 'direct_message',
      ),
    ).called(1);
    verifyNever(
      () => notifications.showMessageNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });
}
