import '../../../core/logging/app_logger.dart';
import '../../messages/data/direct_message_mailbox.dart';
import '../../reflections/data/comment_repository.dart';
import '../../reflections/data/post_repository.dart';
import '../data/admin_banning_repository.dart';

/// Shown when a banned identity tries to keep a session.
///
/// Circle answers that attempt with HTTP 401. Belong refuses the session
/// instead of blocking an IP address.
const circleBanSignInMessage = "This account can't sign in.";

/// The ban record is saved, and at least one erase step still needs a retry.
class CircleBanEraseException implements Exception {
  CircleBanEraseException(this.failedSteps);

  final List<String> failedSteps;

  @override
  String toString() => 'Ban saved. Erase still needs a retry for: ${failedSteps.join(', ')}.';
}

/// Circle's ban, without the IP-address lock (#579, discussion #580).
///
/// The member's posts, comments, and direct messages are removed. The ban
/// record stays, so a matching sign-in does not open a session. There is no
/// Restore: deleted writing stays deleted.
///
/// Erase runs after the ban record so security rules can allow the deletes.
/// A failed step is recorded and [retryCircleBanErase] can run it again.
/// Every step is attempted even when an earlier one throws.
Future<void> applyCircleBan({
  required AdminBanningRepository bans,
  required PostRepository posts,
  required CommentRepository comments,
  required DirectMessageMailbox mailbox,
  required String userId,
  required String displayName,
  String? email,
  required String bannedByAdminEmail,
  Map<String, dynamic>? additionalData,
}) async {
  final effectiveId = await _effectiveBanId(bans: bans, userId: userId, displayName: displayName);
  await bans.banUser(
    userId: effectiveId,
    displayName: displayName,
    email: email,
    bannedByAdminEmail: bannedByAdminEmail,
    reason: 'Violating calm community guidelines',
    additionalData: additionalData,
  );
  await _eraseBannedWriting(
    bans: bans,
    posts: posts,
    comments: comments,
    mailbox: mailbox,
    userId: effectiveId,
    displayName: displayName,
  );
}

/// Runs the content erase again for a ban that is already recorded.
Future<void> retryCircleBanErase({
  required AdminBanningRepository bans,
  required PostRepository posts,
  required CommentRepository comments,
  required DirectMessageMailbox mailbox,
  required String userId,
  required String displayName,
}) async {
  final effectiveId = await _effectiveBanId(bans: bans, userId: userId, displayName: displayName);
  await _eraseBannedWriting(
    bans: bans,
    posts: posts,
    comments: comments,
    mailbox: mailbox,
    userId: effectiveId,
    displayName: displayName,
  );
}

Future<String> _effectiveBanId({
  required AdminBanningRepository bans,
  required String userId,
  required String displayName,
}) async {
  final resolved = await bans.resolveAccountUid(userId: userId, displayName: displayName);
  if (resolved != null && resolved.trim().isNotEmpty) return resolved.trim();
  final fallback = userId.trim();
  return fallback.isNotEmpty ? fallback : displayName.trim();
}

Future<void> _eraseBannedWriting({
  required AdminBanningRepository bans,
  required PostRepository posts,
  required CommentRepository comments,
  required DirectMessageMailbox mailbox,
  required String userId,
  required String displayName,
}) async {
  final failures = <String>[];
  Future<void> step(String name, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      talker.handle(error, stack, 'Circle ban erase failed: $name');
      failures.add(name);
    }
  }

  await step('posts', () => posts.deleteByAuthor(authorName: displayName, authorId: userId));
  await step('comments', () => comments.deleteByAuthor(authorName: displayName, authorId: userId));
  await step('messages', () => mailbox.deleteBySender(senderId: userId, senderName: displayName));

  if (failures.isNotEmpty) {
    await bans.markErasePending(userId: userId, displayName: displayName, failedSteps: failures);
    throw CircleBanEraseException(failures);
  }
  await bans.clearErasePending(userId: userId, displayName: displayName);
}
