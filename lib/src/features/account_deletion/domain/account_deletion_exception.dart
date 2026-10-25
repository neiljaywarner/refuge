/// Calm copy and errors for self-service account deletion.
abstract final class AccountDeletionMessages {
  static const confirmationPhrase = 'DELETE';

  static const confirmationRequired =
      'Type DELETE to confirm you want to delete your account.';

  static const notSignedIn = 'Sign in before deleting your account.';

  static const alreadyDeleted = 'This account is already deleted.';

  static const backendFailed =
      'We could not delete your account. You are still signed in. Please try again.';

  static const signInBlocked =
      'This account was deleted. Sign-in is turned off. Your posts are still here.';

  static const restorePhrase = 'RESTORE';

  static const restoreConfirmationRequired =
      'Type RESTORE to come back to this account.';

  static const nothingToRestore = 'This account is not deleted.';

  static const deleteExplanation =
      'This turns off sign-in and hides you from the member list. '
      'Your posts stay. This is not a full erase. '
      'Only you can come back later, by signing in and typing RESTORE. '
      'Permanent deletion is a later decision.';

  static const returnExplanation =
      'You deleted this account. Your posts are still here. '
      'Only you can come back, by typing RESTORE. '
      'An organizer cannot turn this back on for you.';
}

/// Failure while a member deletes their own account.
class AccountDeletionException implements Exception {
  const AccountDeletionException({
    required this.code,
    required this.message,
    this.backend,
    this.cause,
  });

  final String code;
  final String message;
  final String? backend;
  final Object? cause;

  @override
  String toString() => message;
}

/// A single backend could not record the soft delete.
class AccountDeletionSinkException implements Exception {
  const AccountDeletionSinkException(this.message);

  final String message;

  @override
  String toString() => message;
}
