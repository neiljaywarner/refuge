import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_service.dart';
import 'package:refuge4serverpod/src/features/notifications/data/calm_local_notification_stub.dart';

void main() {
  test('stub records calm digest shows for tests', () async {
    final stub = CalmLocalNotificationStub();
    await showCalmPreviewDirectMessage(stub);

    expect(stub.showCount, 1);
    expect(stub.lastTitle, 'Belong');
    expect(stub.lastBody, contains('direct message'));
  });
}
