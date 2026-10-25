import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/data/member_notification_store.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/profile/data/member_directory_store.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  test('public handle is the plus-tag and never the full address', () {
    expect(publicHandleFromEmail('member+sampletag@example.com'), 'sampletag');
    expect(publicHandleFromEmail('tester@example.com'), isNull);
    expect(publicHandleFromEmail(''), isNull);
    expect(
      publicDisplayName(displayName: 'Fellowship Member', email: 'member+sampletag@example.com'),
      'sampletag',
    );
    expect(
      publicDisplayName(displayName: 'David M.', email: 'member+sampletag@example.com'),
      'David M.',
    );
  });

  test('mention parser keeps the handle and drops the @', () {
    expect(extractMentionHandles('Quiet hello grokbot-mention-token @sampletag'), {'sampletag'});
    expect(extractMentionHandles('no mention here'), isEmpty);
  });

  test('public DM notice drops the message body', () {
    const message = 'Quiet hello from the fellowship';
    final notice = publicOutboundNotice(
      id: 'n1',
      recipientUid: 'recipient',
      authorUid: 'author',
      authorName: 'sampletag',
      type: BelongNotificationType.directMessage,
      postTitle: message,
      commentSnippet: message,
      createdAtMillis: 1,
    );
    expect(notice['postTitle'], 'Direct message');
    expect(notice.containsKey('commentSnippet'), isFalse);
    expect(notice.values.contains(message), isFalse);
  });

  test('public mention notice keeps the post text', () {
    final notice = publicOutboundNotice(
      id: 'n2',
      recipientUid: 'recipient',
      authorUid: 'author',
      authorName: 'sampletag',
      type: BelongNotificationType.mention,
      postTitle: 'Quiet hello grokbot-mention-token @sampletag',
      commentSnippet: 'Quiet hello grokbot-mention-token @sampletag',
      createdAtMillis: 2,
    );
    expect(notice['postTitle'], contains('grokbot-mention-token'));
    expect(notice['commentSnippet'], contains('@sampletag'));
  });

  test('picker matches a real account by handle', () {
    const member = DevFellowshipMember(
      name: 'sampletag',
      role: '@sampletag',
      bio: '',
      churchAffiliation: '',
      isIcocMember: false,
      comfortBadges: [],
      handle: 'sampletag',
      accountId: 'uid-1',
    );
    expect(memberMatchesPickerQuery(member, 'sampletag'), isTrue);
    expect(memberMatchesPickerQuery(member, '@sampletag'), isTrue);
    expect(memberMatchesPickerQuery(member, 'nobody'), isFalse);
  });
}
