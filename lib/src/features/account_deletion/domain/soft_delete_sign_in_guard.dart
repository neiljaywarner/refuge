import 'account_deletion_exception.dart';

/// Decides whether a FirebaseUI sign-in has to be undone.
///
/// FirebaseUI talks to Firebase Auth directly, so the repository sign-in
/// methods are not on that path. Callers sign the member out when this
/// returns a message.
Future<String?> softDeleteSignInBlockMessage({
  required String userId,
  required Future<bool> Function(String userId) isBlocked,
}) async {
  final id = userId.trim();
  if (id.isEmpty) return null;
  if (await isBlocked(id)) return AccountDeletionMessages.signInBlocked;
  return null;
}
