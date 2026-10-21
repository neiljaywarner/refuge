import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/presentation/belong_auth_sheet.dart';
import '../../branding/presentation/brand_config_provider.dart';
import '../../../core/config/preview_mode_provider.dart';
import '../domain/member_profile.dart';

/// Upper-right Member Profile & Stage 1 ("Any Auth") Sign-In Dialog/Sheet
/// built as a [HookConsumerWidget] (#23, #26, #35, ADR-0009).
class MemberProfileDialog extends HookConsumerWidget {
  const MemberProfileDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const MemberProfileDialog());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);
    final nameController = useTextEditingController(text: profile.displayName);
    final emailController = useTextEditingController(text: profile.email);
    final bioController = useTextEditingController(text: profile.bio);
    final selectedAffiliation = useState<String?>(profile.icocChurchAffiliation);
    final validationError = useState<String?>(null);

    final allAffiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

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
                      ? 'Signed in to ${brand.fullName} (${profile.displayName})'
                      : 'Sign in so your reflections carry your name',
                  style: const TextStyle(fontSize: 11.5),
                ),
                if (profile.isSignedIn && profile.icocChurchAffiliation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      profile.isIcocMember
                          ? '⛪ ${profile.icocChurchAffiliation}'
                          : '🌱 ${profile.icocChurchAffiliation}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('profile_sheet_close_button'),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (validationError.value != null) ...[
                Container(
                  key: const Key('profile_validation_error_banner'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validationError.value!,
                          key: const Key('profile_affiliation_error_text'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TextField(
                key: const Key('profile_display_name_field'),
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name', isDense: true),
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
              if (brand.enableFellowshipAffiliationField) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      brand.fellowshipAffiliationPrompt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Required: Confirms whether you are part of our church fellowship or a welcoming visitor.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: const Key('profile_church_affiliation_dropdown'),
                  initialValue: allAffiliationOptions.contains(selectedAffiliation.value)
                      ? selectedAffiliation.value
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                    hintText: 'Select your church affiliation...',
                  ),
                  items: allAffiliationOptions.map((opt) {
                    final isNonMember = opt == brand.fellowshipNonMemberOption;
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: isNonMember ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedAffiliation.value = val;
                    if (val != null && val.isNotEmpty) {
                      validationError.value = null;
                    }
                  },
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Firebase Auth & Magic Link (ADR-0009 / Issue #119)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('profile_open_firebase_auth_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  BelongAuthSheet.show(context);
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: const Text(
                  'Password or Magic Link Sign-In / Register',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '1-Tap Sign-In (Appwrite OAuth2 Ready · ADR-0009)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    key: const Key('oauth_google_sign_in_button'),
                    onPressed: () {
                      ref.read(memberProfileProvider.notifier).signInWithOAuth('google');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 18),
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 11.5)),
                  ),
                  OutlinedButton.icon(
                    key: const Key('oauth_apple_sign_in_button'),
                    onPressed: () {
                      ref.read(memberProfileProvider.notifier).signInWithOAuth('apple');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.apple_rounded, size: 16),
                    label: const Text('Continue with Apple', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final isPreview = ref.watch(previewFeaturesEnabledProvider);
                  return SwitchListTile.adaptive(
                    key: const Key('preview_mode_switch'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      '🧪 Experimental Preview Features',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Show early, experimental features still being tested.',
                      style: TextStyle(fontSize: 10.5),
                    ),
                    value: isPreview,
                    onChanged: (val) {
                      ref.read(previewModeUserOverrideProvider.notifier).state = val;
                      ref.read(previewFeaturesEnabledProvider.notifier).setEnabled(val);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (profile.isSignedIn)
          TextButton(
            key: const Key('profile_sign_out_button'),
            onPressed: () {
              ref.read(memberProfileProvider.notifier).signOut();
              Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('profile_save_sign_in_button'),
          onPressed: () {
            if (brand.enableFellowshipAffiliationField &&
                (selectedAffiliation.value == null || selectedAffiliation.value!.trim().isEmpty)) {
              validationError.value = 'Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".';
              return;
            }

            ref
                .read(memberProfileProvider.notifier)
                .signIn(
                  displayName: nameController.text,
                  email: emailController.text,
                  bio: bioController.text,
                  icocChurchAffiliation: selectedAffiliation.value,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Save & Sign In'),
        ),
      ],
    );
  }
}
