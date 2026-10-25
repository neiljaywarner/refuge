import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/circle_ban.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/domain/stored_direct_message.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

void main() {
  test('a Circle ban removes writing and keeps the ban record', () async {
    final bans = InMemoryAdminBanningRepository();
    final posts = LocalPostRepository(isDevMode: false);
    final comments = LocalCommentRepository(isDevMode: false);
    final mailbox = InMemoryDirectMessageMailbox();
    addTearDown(bans.dispose);

    await posts.createPost(
      Post(
        id: 'post-1',
        authorName: 'Caleb Stone',
        content: 'A note',
        timestamp: DateTime.utc(2026, 10, 24),
        spaceKey: 'prayer',
        reactions: const {},
        toneTag: '[Prayer Request]',
      ),
    );
    await comments.addComment(
      Comment(
        id: 'comment-1',
        postId: 'post-1',
        authorName: 'Caleb Stone',
        content: 'A reply',
        timestamp: DateTime.utc(2026, 10, 24),
      ),
    );
    mailbox.cacheMessage(
      StoredDirectMessage(
        id: 'message-1',
        threadId: 'caleb-123_elena-1',
        senderId: 'caleb-123',
        senderName: 'Caleb Stone',
        recipientIds: const ['elena-1'],
        recipientNames: const ['Elena R.'],
        participantIds: const ['caleb-123', 'elena-1'],
        content: 'Hello',
        sentAt: DateTime.utc(2026, 10, 24),
      ),
    );

    await applyCircleBan(
      bans: bans,
      posts: posts,
      comments: comments,
      mailbox: mailbox,
      userId: 'caleb-123',
      displayName: 'Caleb Stone',
      email: 'caleb@example.com',
      bannedByAdminEmail: 'organizer@belongonthespectrum.com',
    );

    expect(await posts.getPostsByAuthor(authorName: 'Caleb Stone'), isEmpty);
    expect(
      await comments.getCommentsByAuthor(authorName: 'Caleb Stone'),
      isEmpty,
    );
    expect(await mailbox.loadThreads('elena-1'), isEmpty);
    expect(await bans.isUserBanned('caleb-123'), isTrue);
    expect(await bans.isUserBanned('Caleb Stone'), isTrue);
  });
}
