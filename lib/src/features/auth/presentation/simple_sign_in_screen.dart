import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';

/// Minimal sign-in, essentially the firebase_ui_auth pub.dev example.
/// Theme comes from the app's [Theme]; [AuthGate] reacts to the auth stream.
/// Non-production flavors show a "[DEV] ... preview" title so they are obvious.
class SimpleSignInScreen extends ConsumerWidget {
  const SimpleSignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = ref.watch(appFlavorProvider).environmentTag;
    final title = tag == null
        ? 'Sign in to Belong on the Spectrum'
        : '[$tag] Sign in to Belong on the Spectrum PREVIEW';
    return SignInScreen(
      providers: [EmailAuthProvider()],
      subtitleBuilder: (context, action) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          key: const Key('sign_in_title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
