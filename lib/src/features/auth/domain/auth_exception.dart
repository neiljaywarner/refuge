import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

/// Calm, neurodivergent-friendly authentication exception model.
///
/// Translates low-level Firebase error codes into reassuring,
/// literal, and actionable guidance without alarming error messages.
class AuthException implements Exception {
  const AuthException({
    required this.message,
    required this.code,
  });

  final String message;
  final String code;

  /// Translates Firebase errors or general exceptions into a calm [AuthException].
  factory AuthException.fromFirebase(Object error) {
    if (error is fb_auth.FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => const AuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email address (e.g. member@example.com).',
          ),
        'user-disabled' => const AuthException(
            code: 'user-disabled',
            message: 'This account is currently paused. Please reach out to an organizer.',
          ),
        'user-not-found' => const AuthException(
            code: 'user-not-found',
            message: 'No account was found with this email. Please check your email or create an account.',
          ),
        'wrong-password' || 'invalid-credential' => const AuthException(
            code: 'wrong-password',
            message: 'The password entered does not match our records. Please check and try again, or sign in with a magic link.',
          ),
        'email-already-in-use' => const AuthException(
            code: 'email-already-in-use',
            message: 'An account with this email already exists. Please sign in or request a magic link.',
          ),
        'weak-password' => const AuthException(
            code: 'weak-password',
            message: 'For your security, please choose a password with at least 6 characters.',
          ),
        'network-request-failed' => const AuthException(
            code: 'network-request-failed',
            message: 'Unable to connect to the authentication service. Please check your internet connection.',
          ),
        'expired-action-code' => const AuthException(
            code: 'expired-action-code',
            message: 'This magic link has expired. Please request a new sign-in link.',
          ),
        'invalid-action-code' => const AuthException(
            code: 'invalid-action-code',
            message: 'This magic link is invalid or has already been used. Please request a new one.',
          ),
        _ => AuthException(
            code: error.code,
            message: error.message ?? 'An unexpected sign-in issue occurred. Please try again.',
          ),
      };
    }

    if (error is AuthException) {
      return error;
    }

    return AuthException(
      code: 'generic',
      message: error.toString().replaceFirst('Exception: ', ''),
    );
  }

  @override
  String toString() => message;
}
