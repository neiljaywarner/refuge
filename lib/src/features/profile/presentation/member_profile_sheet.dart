import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/presentation/belong_auth_sheet.dart';
import '../../auth/presentation/belong_firebase_auth_screen.dart';
import '../../auth/presentation/simple_auth.dart';
import '../../branding/presentation/brand_config_provider.dart';
import '../../../core/config/preview_mode_provider.dart';
import '../domain/member_profile.dart';
import 'avatar_picker_sheet.dart';

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
    final churchAffiliationController = useTextEditingController(
      text: profile.icocChurchAffiliation ?? '',
    );
    final selectedAffiliation = useState<String?>(profile.icocChurchAffiliation);
    final validationError = useState<String?>(null);

    final allAffiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Tooltip(
            message: 'Change profile avatar',
            child: InkWell(
              key: const Key('edit_avatar_button'),
              borderRadius: BorderRadius.circular(999),
              onTap: () => AvatarPickerSheet.show(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    onBackgroundImageError: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                        ? (_, __) {}
                        : null,
                    child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                        ? Text(
                            profile.initials,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.isSignedIn ? profile.displayName : 'Member Profile & Sign-In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile.isSignedIn
                      ? '${profile.email} · ${profile.authMethod}'
                      : 'Stage 1 ("Any Auth") · No password required',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (validationError.value != null) ...[
                Container(
                  key: const Key('profile_validation_error_banner'),
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validationError.value!,
                          key: const Key('profile_affiliation_error_text'),
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Text(
                'Stage 1 ("Any Auth"): Enter your name and email to participate in discussions and vote on features. Your account persists across sessions on this device.',
                style: TextStyle(fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile_display_name_field'),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Preferred Display Name',
                  helperText: 'What should other members call you?',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile_email_field'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  helperText: 'For notifications and account recovery',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('profile_bio_field'),
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Bio / Note to Fellowship',
                  helperText: 'A quiet sentence about yourself',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (brand.enableFellowshipAffiliationField) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      brand.fellowshipAffiliationPrompt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                TextFormField(
                  key: const Key('profile_church_affiliation_dropdown'),
                  controller: churchAffiliationController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: const OutlineInputBorder(),
                    hintText: 'Select or enter your church affiliation...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                    suffixIcon: PopupMenuButton<String>(
                      key: const Key('profile_church_dropdown_trigger_button'),
                      tooltip: 'Select church affiliation',
                      icon: const Icon(Icons.arrow_drop_down, size: 24),
                      onSelected: (val) {
                        churchAffiliationController.text = val;
                        selectedAffiliation.value = val;
                        validationError.value = null;
                      },
                      itemBuilder: (context) => allAffiliationOptions.map((opt) {
                        final isNonMember = opt == brand.fellowshipNonMemberOption;
                        return PopupMenuItem<String>(
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
                    ),
                  ),
                  onTap: () async {
                    final RenderBox? box = context.findRenderObject() as RenderBox?;
                    final offset = box != null ? box.localToToGlobal(Offset.zero) : Offset.zero;
                    final size = box?.size ?? Size.zero;
                    final selected = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        offset.dx,
                        offset.dy + size.height,
                        offset.dx + size.width,
                        offset.dy + size.height + 250,
                      ),
                      items: allAffiliationOptions.map((opt) {
                        final isNonMember = opt == brand.fellowshipNonMemberOption;
                        return PopupMenuItem<String>(
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
                    );
                    if (selected != null) {
                      churchAffiliationController.text = selected;
                      selectedAffiliation.value = selected;
                      validationError.value = null;
                    }
                  },
                  onChanged: (val) {
                    selectedAffiliation.value = val;
                    if (val.trim().isNotEmpty) {
                      validationError.value = null;
                    }
                  },
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Official Firebase Auth UI (Google / Firebase Team)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('profile_open_firebase_auth_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  SimpleAuthScreen.show(context);
                },
                icon: Icon(
                  profile.isSignedIn ? Icons.account_circle_outlined : Icons.lock_outline_rounded,
                  size: 16,
                ),
                label: Text(
                  profile.isSignedIn
                      ? 'Open Firebase Account Profile & Security'
                      : 'Firebase SimpleAuth (Sign-In / Register)',
                  style: const TextStyle(fontSize: 11.5),
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
            final affiliation = churchAffiliationController.text.trim();
            if (brand.enableFellowshipAffiliationField && affiliation.isEmpty) {
              validationError.value =
                  'Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".';
              return;
            }

            ref
                .read(memberProfileProvider.notifier)
                .signIn(
                  displayName: nameController.text,
                  email: emailController.text,
                  bio: bioController.text,
                  icocChurchAffiliation: affiliation,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Save & Sign In'),
        ),
      ],
    );
  }
}
