import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../branding/domain/community_brand_config.dart';
import '../../branding/presentation/brand_config_provider.dart';
import 'sign_in_recovery_panel.dart';

/// Title on the sign-in wall.
///
/// Register keeps the community name and drops "Sign in to", so the form
/// does not tell a new member they are signing in. The flavor tag stays.
String signInWallTitle(AppFlavor flavor, {bool registering = false, CommunityBrandConfig? brand}) {
  final community = brand?.fullName ?? 'Belong on the Spectrum';
  final sentence = registering ? community : 'Sign in to $community';
  if (brand?.isBema == true) return sentence;
  final tag = flavor.environmentTag;
  if (tag == null) return sentence;
  return '[$tag] $sentence PREVIEW';
}

Widget signInWallTitleText(BuildContext context, String title) {
  // Flutter web drops plain Text inside the FirebaseUI scroll view, so the
  // sentence is on screen and missing from the accessibility tree. An
  // explicit label is what Maestro and screen readers can see.
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      identifier: 'sign_in_title',
      label: title,
      header: true,
      container: true,
      excludeSemantics: true,
      child: Text(
        title,
        key: const Key('sign_in_title'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}

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
    final brand = ref.watch(communityBrandConfigProvider);
    final titleText = signInWallTitleText(context, signInWallTitle(flavor, brand: brand));

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
      subtitleBuilder: (context, action) => signInWallTitleText(
        context,
        signInWallTitle(flavor, registering: action == AuthAction.signUp, brand: brand),
      ),
      footerBuilder: (context, action) => SignInRecoveryPanel(
        canUseAppWhileWaiting: !flavor.isProduction,
        onForgotPassword: () => showForgotPasswordScreen(context: context),
      ),
    );
  }
}
