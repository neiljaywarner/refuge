import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/member_profile.dart';

/// Upper-right Member Profile & Stage 1 ("Any Auth") Sign-In Dialog/Sheet
/// built as a [HookConsumerWidget] (#23, #26, #35).
class MemberProfileDialog extends HookConsumerWidget {
  const MemberProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const MemberProfileDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider);
    final nameController = useTextEditingController(text: profile.displayName);
    final emailController = useTextEditingController(text: profile.email);
    final bioController = useTextEditingController(text: profile.bio);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(
              profile.initials,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Member Profile & Sign-In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile.isSignedIn
                      ? 'Signed in to Belong on the Spectrum'
                      : 'Sign in so your reflections carry your name',
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('profile_display_name_field'),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('profile_email_field'),
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Alpha Sign-In)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('profile_bio_field'),
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Short Bio / Special Interests',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (profile.isSignedIn)
          TextButton(
            onPressed: () {
              ref.read(memberProfileProvider.notifier).signOut();
              Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('profile_save_sign_in_button'),
          onPressed: () {
            ref.read(memberProfileProvider.notifier).signIn(
                  displayName: nameController.text,
                  email: emailController.text,
                  bio: bioController.text,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Save & Sign In'),
        ),
      ],
    );
  }
}
