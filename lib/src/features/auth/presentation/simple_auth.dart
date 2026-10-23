import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/presentation/system_insets.dart';

/// Minimal, plain-vanilla wrapper around the official [firebase_ui_auth] example.
///
/// Provides out-of-the-box:
/// 1. [SignInScreen] with [EmailAuthProvider], register toggle, and forgot password.
/// 2. [ProfileScreen] showing account email, change password, and sign out.
/// 3. Zero custom forms or state overhead — plain vanilla Firebase Auth.
class SimpleAuthScreen extends StatelessWidget {
  const SimpleAuthScreen({
    super.key,
    this.auth,
    this.onAuthenticated,
    this.onSignedOut,
  });

  final FirebaseAuth? auth;
  final VoidCallback? onAuthenticated;
  final VoidCallback? onSignedOut;

  /// Opens the SimpleAuth screen directly via Navigator.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAuthenticated,
    VoidCallback? onSignedOut,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SystemBottomInset(
          child: SimpleAuthScreen(
            onAuthenticated: onAuthenticated,
            onSignedOut: onSignedOut,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];
    final effectiveAuth =
        auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

    if (effectiveAuth == null) {
      // In headless unit tests or when Firebase is uninitialized
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sign In to Belong'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belong on the Spectrum',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unhurried Christian fellowship',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('auth_offline_sign_in_button'),
                        onPressed: () {
                          onAuthenticated?.call();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text(
                          'Enter Community (Offline / Test Mode)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: effectiveAuth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? effectiveAuth.currentUser;
        if (user == null) {
          return SignInScreen(
            auth: effectiveAuth,
            providers: providers,
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belong on the Spectrum',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  action == AuthAction.signIn
                      ? 'Sign in to access your reflections, spaces, and private saved items.'
                      : 'Join our calm Christian fellowship. No algorithmic rush.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
            footerBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Safe, sensory-friendly & private',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
            actions: [
              AuthStateChangeAction<UserCreated>((context, state) {
                onAuthenticated?.call();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }),
              AuthStateChangeAction<SignedIn>((context, state) {
                onAuthenticated?.call();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }),
            ],
          );
        }

        return ProfileScreen(
          auth: effectiveAuth,
          providers: providers,
          actions: [
            SignedOutAction((context) {
              onSignedOut?.call();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }),
          ],
          appBar: AppBar(title: const Text('Account Profile')),
        );
      },
    );
  }
}
