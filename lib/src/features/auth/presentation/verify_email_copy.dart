import '../domain/auth_exception.dart';

/// Plain-language email verification copy.
///
/// Production still waits on the check-email screen. Other flavors let the
/// member into Home and say so. Neither path should look like a blank wait.
final class VerifyEmailCopy {
  const VerifyEmailCopy._();

  static const forgotPasswordButton = 'Forgot your password?';

  static const forgotPasswordHelp = 'We email you a link to choose a new password.';

  static const resendButton = 'Send the verification email again';

  static const checkingAccount = 'Checking your account...';

  static const wallSending = 'Sending your verification email now.';

  static const wallSent = 'Sent a verification link. Check your inbox and your spam folder.';

  static const wallResent =
      'Sent a fresh verification link. Check your inbox and your spam folder.';

  static const notVerifiedYet =
      'Not verified yet. Open the link in your email first, then tap I verified my email.';

  static const couldNotSend = 'Could not send right now. Please wait a minute and try again.';

  static const softBannerSending = 'Sending the verification email. You can keep using the app.';

  static const softBannerSent =
      'The verification email is on its way. You can keep using the app while you wait. Check your inbox and your spam folder.';

  static const softBannerResent =
      'Sent a fresh verification link. You can keep using the app. Check your inbox and your spam folder.';

  static String signInVerifyHelp({required bool canUseAppWhileWaiting}) {
    if (canUseAppWhileWaiting) {
      return 'No verification email yet? Sign in with the address you registered. '
          'You can use the app while you wait, then send the verification email again.';
    }
    return 'No verification email yet? Sign in with the address you registered. '
        'The next screen lets you send the verification email again.';
  }

  static String softBannerBody(String email) {
    final where = email.trim().isEmpty ? 'your email address' : email.trim();
    return 'You can use the app while you wait for a verification email at $where. '
        'Check your inbox and your spam folder. If it does not arrive, send it again.';
  }

  static String wallBody(String email) {
    final where = email.trim().isEmpty ? 'your email address' : email.trim();
    return 'A verification link goes to $where. Open it, then tap I verified my email. '
        'Check your inbox and your spam folder. If it does not arrive, send it again. '
        'These buttons stay here while you wait.';
  }
}

/// Calm status line for a failed verification or password-reset send.
String friendlyVerifyEmailError(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  try {
    final authEx = AuthException.fromFirebase(error);
    const mappedCodes = {
      'invalid-email',
      'user-disabled',
      'user-not-found',
      'wrong-password',
      'invalid-credential',
      'email-already-in-use',
      'weak-password',
      'network-request-failed',
      'expired-action-code',
      'invalid-action-code',
      'no-current-user',
    };
    if (mappedCodes.contains(authEx.code)) {
      return authEx.message;
    }
  } catch (_) {}
  return VerifyEmailCopy.couldNotSend;
}
