import 'package:flutter/material.dart';

import 'verify_email_copy.dart';

/// Forgot-password and resend-verification guidance on the sign-in wall.
///
/// The Firebase form still has its own "Forgotten password?" control. This
/// panel states the same path in plain language, plus what to do when the
/// verification email has not arrived.
class SignInRecoveryPanel extends StatelessWidget {
  const SignInRecoveryPanel({
    super.key,
    required this.canUseAppWhileWaiting,
    this.onForgotPassword,
  });

  /// True when this flavor lets an unverified member into Home.
  final bool canUseAppWhileWaiting;

  /// Opens the password-reset screen. Null when Firebase is not ready.
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      key: const Key('sign_in_recovery_panel'),
      padding: const .only(top: 12),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          TextButton(
            key: const Key('sign_in_forgot_password'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: onForgotPassword,
            child: const Text(VerifyEmailCopy.forgotPasswordButton),
          ),
          Text(
            VerifyEmailCopy.forgotPasswordHelp,
            key: const Key('sign_in_forgot_password_help'),
            textAlign: TextAlign.center,
            style: style,
          ),
          const SizedBox(height: 12),
          Text(
            VerifyEmailCopy.signInVerifyHelp(canUseAppWhileWaiting: canUseAppWhileWaiting),
            key: const Key('sign_in_resend_verification_help'),
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }
}
