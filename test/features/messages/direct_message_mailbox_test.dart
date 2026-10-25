import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';

void main() {
  group('InMemoryDirectMessageMailbox', () {
    late InMemoryDirectMessageMailbox mailbox;

    setUp(() {
      mailbox = InMemoryDirectMessageMailbox(
        seedUsers: {
          'uid-alice': {
            'displayName': 'Fellow Member',
            'email': 'member@belongonthespectrum.com',
            'bio': 'Quiet fellowship',
          },
          'uid-bob': {
            'displayName': 'Community Member',
            'email': 'grokbot2@example.com',
            'bio': 'Test peer',
          },
          'uid-carol': {
            'displayName': 'Third Member',
            'email': 'third@example.com',
            'bio': 'Elsewhere',
          },
        },
      );
    });

    test('send delivers thread to recipient and notification includes body', () async {
      const body = 'Quiet hello from the fellowship.';
      final bob = MessageRecipient.fromFirestoreUser(
        'uid-bob',
        {
          'displayName': 'Community Member',
          'email': 'grokbot2@example.com',
        },
      );

      await mailbox.sendMessage(
        senderId: 'uid-alice',
        senderName: 'Fellow Member',
        recipients: [bob],
        content: body,
      );

      final bobThreads = await mailbox.loadThreads('uid-bob');
      expect(bobThreads, isNotEmpty);
      expect(bobThreads.first.messages.last.content, body);

      final merged = mailbox.notificationsForUser(
        currentUserId: 'uid-bob',
        existing: const [],
      );
      expect(merged, isNotEmpty);
      final dm = merged.firstWhere(
        (n) => n.type == BelongNotificationType.directMessage,
      );
      expect(dm.displayMessage, contains('sent you a direct message'));
      expect(dm.displayMessage, contains(body));
    });

    test('third member cannot see the thread', () async {
      final bob = MessageRecipient.fromFirestoreUser(
        'uid-bob',
        {'displayName': 'Peer', 'email': 'grokbot2@example.com'},
      );

      await mailbox.sendMessage(
        senderId: 'uid-alice',
        senderName: 'Fellow Member',
        recipients: [bob],
        content: 'Private note',
      );

      final carolThreads = await mailbox.loadThreads('uid-carol');
      expect(carolThreads, isEmpty);
    });
  });
}
