import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/direct_message_email_policy.dart';

void main() {
  const address = 'member@belongonthespectrum.com';
  const body = 'Quiet hello from the fellowship.';

  test('a turned-off or muted member does not get an email', () {
    expect(
      shouldSendDirectMessageEmail(enabled: false, schedule: 'twiceDaily', email: address),
      isFalse,
    );
    expect(shouldSendDirectMessageEmail(enabled: true, schedule: 'muted', email: address), isFalse);
    expect(
      shouldSendDirectMessageEmail(enabled: true, schedule: 'twiceDaily', email: null),
      isFalse,
    );
  });

  test('an opted-in member with a sign-in address gets an email', () {
    expect(
      shouldSendDirectMessageEmail(enabled: true, schedule: 'twiceDaily', email: address),
      isTrue,
    );
    expect(
      shouldSendDirectMessageEmail(enabled: true, schedule: 'immediateGentle', email: address),
      isTrue,
    );
  });

  test('the subject names the sender and omits the body and any address', () {
    final subject = directMessageEmailSubject(senderName: 'Fellow Member', content: body);
    expect(subject, 'Fellow Member — a message is waiting');
    expect(subject.contains(body), isFalse);
    expect(subject.contains('@'), isFalse);
    expect(subject.contains(address), isFalse);

    expect(
      directMessageEmailSubject(senderName: address, content: body),
      'Fellow Member — a message is waiting',
    );
    expect(
      directMessageEmailSubject(senderName: body, content: body),
      'Fellow Member — a message is waiting',
    );
  });

  test('the text does not quote the message', () {
    final text = directMessageEmailText(senderName: 'Fellow Member', content: body);
    expect(text, 'Fellow Member sent you a message in Belong. Open the app when you are ready.');
    expect(text.contains(body), isFalse);
    expect(text.contains('@'), isFalse);
  });

  test('only a message Firestore accepted can be emailed', () {
    expect(directMessageOutcomeCreatesStoredDocument('delivered'), isTrue);
    expect(directMessageOutcomeCreatesStoredDocument('localOnly'), isFalse);
    expect(directMessageOutcomeCreatesStoredDocument('deviceOnly'), isFalse);
  });
}
