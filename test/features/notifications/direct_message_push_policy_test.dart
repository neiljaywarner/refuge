import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/direct_message_push_policy.dart';

void main() {
  test('a turned-off or muted member does not get a push', () {
    expect(
      shouldSendDirectMessagePush(
        enabled: false,
        schedule: 'twiceDaily',
        fcmToken: 'real-device-token',
      ),
      isFalse,
    );
    expect(
      shouldSendDirectMessagePush(
        enabled: true,
        schedule: 'muted',
        fcmToken: 'real-device-token',
      ),
      isFalse,
    );
  });

  test('a placeholder token is not a real device', () {
    expect(
      shouldSendDirectMessagePush(
        enabled: true,
        schedule: 'immediateGentle',
        fcmToken: 'fcm_token_calm_digest_alpha_preview',
      ),
      isFalse,
    );
  });

  test('an opted-in member with a real token gets a silent card', () {
    expect(
      shouldSendDirectMessagePush(
        enabled: true,
        schedule: 'twiceDaily',
        fcmToken: 'real-device-token',
      ),
      isTrue,
    );
  });

  test('the shade names the sender and the snippet', () {
    expect(
      directMessagePushBody(
        senderName: 'Fellow Member',
        content: 'Quiet hello from the fellowship.',
      ),
      'Fellow Member sent you a direct message: "Quiet hello from the fellowship."',
    );
  });
}
