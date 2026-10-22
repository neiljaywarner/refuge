import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

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
        builder: (_) => SimpleAuthScreen(
          onAuthenticated: onAuthenticated,
          onSignedOut: onSignedOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];
    final effectiveAuth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

    if (effectiveAuth == null) {
      // In headless unit tests or when Firebase is uninitialized
      return Scaffold(
        appBar: AppBar(title: const Text('Sign In to Belong')),
        body: const Center(child: Text('Firebase Auth offline / test mode')),
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
          appBar: AppBar(
            title: const Text('Account Profile'),
          ),
        );
      },
    );
  }
}
