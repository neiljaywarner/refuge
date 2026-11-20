import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/data/member_notification_store.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/profile/data/member_directory_store.dart';

void main() {
  test('mention handles drop the @ and ignore duplicates', () {
    expect(extractMentionHandles('Hi @Sam_1, @sam_1, and @Alex'), {'sam_1', 'alex'});
    expect(extractMentionHandles('no mention here'), isEmpty);
  });

  test('a public notice hides a direct-message body and keeps a mention', () {
    final direct = publicOutboundNotice(
      id: 'n1',
      recipientUid: 'member-b',
      authorUid: 'member-a',
      authorName: 'David M.',
      type: BelongNotificationType.directMessage,
      postTitle: 'private words',
      commentSnippet: '  hello  ',
      spaceKey: '   ',
      createdAtMillis: 10,
    );
    expect(direct['postTitle'], 'Direct message');
    expect(direct.containsKey('commentSnippet'), isFalse);
    expect(direct.containsKey('spaceKey'), isFalse);

    final mention = publicOutboundNotice(
      id: 'n2',
      recipientUid: 'member-b',
      authorUid: 'member-a',
      authorName: 'David M.',
      type: BelongNotificationType.mention,
      postTitle: 'Hello @sam',
      commentSnippet: 'Hello @sam',
      spaceKey: 'prayer',
      createdAtMillis: 11,
    );
    expect(mention['postTitle'], 'Hello @sam');
    expect(mention['commentSnippet'], 'Hello @sam');
    expect(mention['spaceKey'], 'prayer');
    expect(mention['type'], 'mention');
  });

  test('a guest or an empty id watches an empty bell', () async {
    final store = MemberNotificationStore();
    expect(await store.watchForRecipient('').first, isEmpty);
    expect(await store.watchForRecipient('guest').first, isEmpty);
    await store.notifyRecipient(
      recipientUid: 'member-b',
      authorUid: 'guest',
      authorName: 'David M.',
      type: BelongNotificationType.mention,
      postTitle: 'Hi',
    );
    await store.notifyMentionsInContent(content: 'Hi @sam', authorUid: '', authorName: 'David M.');
  });

  test('a mention writes a bell item the recipient can watch', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection(MemberDirectoryStore.collectionPath).doc('member-b').set({
      'uid': 'member-b',
      'handle': 'sam',
      'displayName': 'Sarah K.',
    });
    final store = MemberNotificationStore(customFirestore: firestore);

    await store.notifyMentionsInContent(
      content: 'Hi @sam',
      authorUid: 'member-a',
      authorName: 'David M.',
      spaceKey: 'prayer',
    );
    await store.notifyRecipient(
      recipientUid: 'member-a',
      authorUid: 'member-a',
      authorName: 'David M.',
      type: BelongNotificationType.reply,
      postTitle: 'Same person',
    );

    final written = await firestore.collection(MemberNotificationStore.collectionPath).get();
    expect(written.docs, hasLength(1));
    expect(written.docs.single.data()['recipientUid'], 'member-b');
    expect(written.docs.single.data()['type'], 'mention');

    await firestore.collection(MemberNotificationStore.collectionPath).add({
      'recipientUid': 'member-b',
      'authorName': '',
      'type': 'not-a-type',
      'postTitle': 'Skipped',
      'createdAt': 1,
    });
    await firestore.collection(MemberNotificationStore.collectionPath).add({
      'recipientUid': 'member-b',
      'authorName': 'Sarah K.',
      'type': 'reply',
      'postTitle': 'A reply',
      'isRead': true,
      'spaceKey': 'prayer',
      'commentSnippet': 'Thanks',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 3)),
    });

    final items = await store.watchForRecipient('member-b').first;
    expect(items.map((item) => item.postTitle), containsAll(['Hi @sam', 'A reply']));
    expect(items.map((item) => item.postTitle), isNot(contains('Skipped')));
    final reply = items.singleWhere((item) => item.postTitle == 'A reply');
    expect(reply.isRead, isTrue);
    expect(reply.spaceKey, 'prayer');
    expect(reply.commentSnippet, 'Thanks');
    expect(reply.type, BelongNotificationType.reply);
  });
}
