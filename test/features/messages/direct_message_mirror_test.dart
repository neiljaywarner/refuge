import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mirror.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';
import 'package:refuge4serverpod/src/features/messages/domain/stored_direct_message.dart';

class MemoryDirectMessageMirror implements DirectMessageMirror {
  MemoryDirectMessageMirror({this.fail = false});

  final List<Map<String, Object?>> copies = [];
  bool fail;

  @override
  Future<void> copyMessage(StoredDirectMessage message) async {
    if (fail) throw StateError('mirror down');
    copies.add(directMessageMirrorFields(message));
  }
}

void main() {
  const body = 'Quiet hello from the fellowship.';
  const bob = MessageRecipient(id: 'uid-bob', name: 'Community Member', tagline: 'Quiet');

  test('the mirror is asked to copy a message after the Firestore write', () async {
    final firestore = FakeFirebaseFirestore();
    final mirror = MemoryDirectMessageMirror();
    final mailbox = FirestoreDirectMessageMailbox(firestore: firestore, mirror: mirror);

    final result = await mailbox.sendMessage(
      senderId: 'uid-alice',
      senderName: 'Fellow Member',
      recipients: const [bob],
      content: body,
      subject: 'Hello',
    );

    expect(result.outcome, DirectMessageSendOutcome.delivered);
    expect(result.message.content, body);
    final stored = await firestore.collection('direct_messages').doc(result.message.id).get();
    expect(stored.exists, isTrue);
    expect(stored.data()?['content'], body);
    expect(mirror.copies, hasLength(1));
    expect(mirror.copies.single, directMessageMirrorFields(result.message));
    expect(mirror.copies.single['senderId'], 'uid-alice');
    expect(mirror.copies.single['recipientIds'], ['uid-bob']);
    expect(mirror.copies.single['subject'], 'Hello');
  });

  test('a failed mirror still returns the Firestore message', () async {
    final firestore = FakeFirebaseFirestore();
    final mirror = MemoryDirectMessageMirror(fail: true);
    final mailbox = FirestoreDirectMessageMailbox(firestore: firestore, mirror: mirror);

    final result = await mailbox.sendMessage(
      senderId: 'uid-alice',
      senderName: 'Fellow Member',
      recipients: const [bob],
      content: body,
    );

    expect(result.outcome, DirectMessageSendOutcome.delivered);
    expect(result.message.content, body);
    expect(result.message.senderId, 'uid-alice');
    final stored = await firestore.collection('direct_messages').doc(result.message.id).get();
    expect(stored.exists, isTrue);
    expect(stored.data()?['content'], body);
    expect(mirror.copies, isEmpty);
  });

  test('sample threads and device-only sends do not ask the mirror', () async {
    final firestore = FakeFirebaseFirestore();
    final mirror = MemoryDirectMessageMirror();
    final mailbox = FirestoreDirectMessageMailbox(firestore: firestore, mirror: mirror);
    const sample = MessageRecipient(
      id: 'sample-Ada',
      name: 'Ada',
      tagline: 'Sample',
      isSample: true,
    );

    final local = await mailbox.sendMessage(
      senderId: 'uid-alice',
      senderName: 'Fellow Member',
      recipients: const [sample],
      content: body,
    );
    expect(local.outcome, DirectMessageSendOutcome.localOnly);
    expect(mirror.copies, isEmpty);
    expect((await firestore.collection('direct_messages').get()).docs, isEmpty);

    final offline = FirestoreDirectMessageMailbox(mirror: mirror);
    final device = await offline.sendMessage(
      senderId: 'uid-alice',
      senderName: 'Fellow Member',
      recipients: const [bob],
      content: body,
    );
    expect(device.outcome, DirectMessageSendOutcome.deviceOnly);
    expect(mirror.copies, isEmpty);
  });

  test('the function request carries no API key and no message text', () {
    final encoded = jsonEncode(
      directMessageMirrorExecutionBody(idToken: 'token', messageId: 'dm-1'),
    );
    expect(encoded.contains('apiKey'), isFalse);
    expect(encoded.contains('X-Appwrite-Key'), isFalse);
    expect(encoded.contains(body), isFalse);
    expect(encoded.contains('dm-1'), isTrue);
  });
}
