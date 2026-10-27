import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

/// Minimal sign-in, essentially the firebase_ui_auth pub.dev example.
/// Theme comes from the app's [Theme]; [AuthGate] reacts to the auth stream.
class SimpleSignInScreen extends StatelessWidget {
  const SimpleSignInScreen({super.key});

  @override
  Widget build(BuildContext context) => SignInScreen(providers: [EmailAuthProvider()]);
}
