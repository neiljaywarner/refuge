import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import 'sign_in_recovery_panel.dart';

/// Minimal sign-in, essentially the firebase_ui_auth pub.dev example.
///
/// This is the whole route: no wrapper, no logo. Theme comes from the app's
/// [Theme]; [AuthGate] swaps to home (or the prod verify-email wall) when the
/// Firebase auth stream signs in. Non-production flavors show a
/// "[DEV] ... PREVIEW" title so they are obvious.
class SimpleSignInScreen extends ConsumerWidget {
  const SimpleSignInScreen({super.key, this.firebaseReady = true});

  /// False in widget tests / offline builds where Firebase is not initialized.
  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(appFlavorProvider);
    final tag = flavor.environmentTag;
    final title = tag == null
        ? 'Sign in to Belong on the Spectrum'
        : '[$tag] Sign in to Belong on the Spectrum PREVIEW';
    final titleText = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        key: const Key('sign_in_title'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );

    if (!firebaseReady) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleText,
                      const Text(
                        'Sign-in requires a connection to our authentication service.',
                        key: Key('sign_in_unavailable'),
                        textAlign: TextAlign.center,
                      ),
                      SignInRecoveryPanel(canUseAppWhileWaiting: !flavor.isProduction),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SignInScreen(
      providers: [EmailAuthProvider()],
      showPasswordVisibilityToggle: true,
      subtitleBuilder: (context, action) => titleText,
      footerBuilder: (context, action) => SignInRecoveryPanel(
        canUseAppWhileWaiting: !flavor.isProduction,
        onForgotPassword: () => showForgotPasswordScreen(context: context),
      ),
    );
  }
}
