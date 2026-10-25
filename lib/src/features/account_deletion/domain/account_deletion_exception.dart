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
