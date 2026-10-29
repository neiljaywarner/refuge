import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/config/other_site_info_button.dart';
import '../../profile/presentation/member_profile_sheet.dart';

/// Pre-built, Google/Firebase team official authentication screens
/// powered by [firebase_ui_auth].
///
/// Features out-of-the-box:
/// 1. Email & Password Sign-In
/// 2. Account Registration / Sign-Up
/// 3. Forgot Password / Password Reset Email flow
/// 4. Firebase User Profile, Password Change & Account Deletion
class BelongFirebaseSignInScreen extends StatelessWidget {
  const BelongFirebaseSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _ensureProvidersConfigured();

    return SignInScreen(
      providers: [EmailAuthProvider()],
      showPasswordVisibilityToggle: true,
      actions: [
        ForgotPasswordAction((context, email) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ForgotPasswordScreen(email: email, headerMaxExtent: 160),
            ),
          );
        }),
        AuthStateChangeAction<SignedIn>((context, state) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }),
        AuthStateChangeAction<UserCreated>((context, state) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }),
      ],
      headerBuilder: (context, constraints, shrinkOffset) => Padding(
        padding: const .fromLTRB(20, 24, 20, 10),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Icon(
              Icons.diversity_3_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Belong on the Spectrum',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const OtherSiteInfoButton(),
          ],
        ),
      ),
    );
  }

  static void _ensureProvidersConfigured() {
    if (Firebase.apps.isNotEmpty &&
        !FirebaseUIAuth.isAppConfigured(Firebase.app())) {
      try {
        FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
      } catch (_) {
        // Ignored if already configured or in test mode.
      }
    }
  }
}

/// Official Firebase User Profile & Account Management screen.
class BelongFirebaseProfileScreen extends StatelessWidget {
  const BelongFirebaseProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ProfileScreen(
    providers: [EmailAuthProvider()],
    avatar: const Center(child: BelongEditableAvatar(radius: 36)),
    showDeleteConfirmationDialog: true,
    actions: [
      AccountDeletedAction((context, _) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }),
      SignedOutAction((context) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }),
    ],
    appBar: AppBar(title: const Text('Account Profile')),
  );
}
