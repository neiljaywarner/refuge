import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mirror.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';
import 'package:refuge4serverpod/src/features/messages/domain/stored_direct_message.dart';

class _NoopMirror implements DirectMessageMirror {
  @override
  Future<void> copyMessage(StoredDirectMessage message) async {}
}

void main() {
  group('DirectMessageMailbox directory filtering, group names & replies (#818)', () {
    test('loadDirectory excludes listedInDirectory=false, banned, and deleted users', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-listed').set({
        'displayName': 'Hannah Morales',
        'handle': 'hannah',
        'tagline': 'Botanical watercolors',
        'listedInDirectory': true,
      });
      await firestore.collection('users').doc('uid-unlisted').set({
        'displayName': 'Hidden Member',
        'listedInDirectory': false,
      });
      await firestore.collection('users').doc('uid-banned').set({
        'displayName': 'Banned Account',
        'listedInDirectory': true,
      });
      await firestore.collection('banned_uids').doc('uid-banned').set({'banned': true});
      await firestore.collection('users').doc('uid-deleted').set({
        'displayName': 'Deleted Account',
        'listedInDirectory': true,
      });
      await firestore.collection('self_deleted_accounts').doc('uid-deleted').set({'deleted': true});

      final mailbox = FirestoreDirectMessageMailbox(firestore: firestore, mirror: _NoopMirror());

      final prodDir = await mailbox.loadDirectory(includeSamples: true, isProduction: true);
      expect(prodDir.map((m) => m.id).toList(), ['uid-listed']);
      expect(prodDir.any((m) => m.isSample), isFalse);
    });

    test('named group message and reply persist threadId, participantIds, and groupName', () async {
      final firestore = FakeFirebaseFirestore();
      final mailbox = FirestoreDirectMessageMailbox(firestore: firestore, mirror: _NoopMirror());

      const bob = MessageRecipient(id: 'uid-bob', name: 'Bob Stone', tagline: 'Calm audio');
      const carol = MessageRecipient(id: 'uid-carol', name: 'Carol Chen', tagline: 'Greek studies');

      final initial = await mailbox.sendMessage(
        senderId: 'uid-alice',
        senderName: 'Alice Founder',
        recipients: const [bob, carol],
        subject: 'Friday Check-In',
        content: 'Welcome to our Friday group!',
        groupName: 'Friday Wingspan Circle',
      );

      expect(initial.outcome, DirectMessageSendOutcome.delivered);
      expect(initial.thread.groupName, 'Friday Wingspan Circle');
      expect(initial.thread.displayTitle, 'Friday Wingspan Circle');
      expect(initial.thread.isGroup, isTrue);
      expect(
        initial.thread.participantIds,
        containsAll(<String>['uid-alice', 'uid-bob', 'uid-carol']),
      );

      // Reply from Bob in the same thread
      final reply = await mailbox.sendMessage(
        senderId: 'uid-bob',
        senderName: 'Bob Stone',
        recipients: const [
          MessageRecipient(id: 'uid-alice', name: 'Alice Founder', tagline: ''),
          carol,
        ],
        subject: initial.thread.subject,
        content: 'Count me in for Friday!',
        groupName: initial.thread.groupName,
        existingThreadId: initial.thread.id,
        existingMessages: initial.thread.messages,
      );

      expect(reply.outcome, DirectMessageSendOutcome.delivered);
      expect(reply.thread.id, initial.thread.id);
      expect(reply.thread.messages, hasLength(2));

      // Verify Carol loads the full 2-message group thread from Firestore
      final carolThreads = await mailbox.loadThreads('uid-carol');
      expect(carolThreads, hasLength(1));
      final loaded = carolThreads.single;
      expect(loaded.id, initial.thread.id);
      expect(loaded.groupName, 'Friday Wingspan Circle');
      expect(loaded.displayTitle, 'Friday Wingspan Circle');
      expect(loaded.messages, hasLength(2));
      expect(loaded.messages.first.senderName, 'Alice Founder');
      expect(loaded.messages.last.senderName, 'Bob Stone');
      expect(loaded.messages.last.content, 'Count me in for Friday!');
    });
  });
}
