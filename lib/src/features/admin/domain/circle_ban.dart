import '../data/admin_banning_repository.dart';
import '../../messages/data/direct_message_mailbox.dart';
import '../../reflections/data/comment_repository.dart';
import '../../reflections/data/post_repository.dart';

/// Shown when a banned identity tries to keep a session.
///
/// Circle answers that attempt with HTTP 401. Belong refuses the session
/// instead of blocking an IP address.
const circleBanSignInMessage = "This account can't sign in.";

/// Circle's ban, without the IP-address lock (#579, discussion #580).
///
/// The member's posts, comments, and direct messages are removed. The ban
/// record stays, so a matching sign-in does not open a session. There is no
/// Restore: deleted writing stays deleted.
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
  await bans.banUser(
    userId: userId,
    displayName: displayName,
    email: email,
    bannedByAdminEmail: bannedByAdminEmail,
    reason: 'Violating calm community guidelines',
    additionalData: additionalData,
  );
  await posts.deleteByAuthor(authorName: displayName);
  await comments.deleteByAuthor(authorName: displayName);
  await mailbox.deleteBySender(senderId: userId, senderName: displayName);
}
