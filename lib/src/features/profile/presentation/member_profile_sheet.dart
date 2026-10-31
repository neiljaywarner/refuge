import 'package:firebase_auth/firebase_auth.dart' as fb_auth hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/preview_mode_provider.dart';
import '../../account_deletion/presentation/delete_my_account_dialog.dart';
import '../../branding/presentation/brand_config_provider.dart';
import '../domain/member_profile.dart';
import 'avatar_picker_sheet.dart';

/// Composable Belong avatar widget with camera badge that opens [AvatarPickerSheet].
///
/// Can be embedded in [MemberProfileDialog] or passed as `avatar:` to
/// `firebase_ui_auth`'s [ProfileScreen].
class BelongEditableAvatar extends ConsumerWidget {
  const BelongEditableAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider);
    final hasPhoto = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Tooltip(
      message: 'Change profile avatar',
      child: Semantics(
        identifier: 'edit_avatar_button',
        button: true,
        label: 'Change profile avatar',
        child: InkWell(
          key: const Key('edit_avatar_button'),
          borderRadius: .circular(999),
          onTap: () => AvatarPickerSheet.show(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: radius,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: hasPhoto ? NetworkImage(profile.avatarUrl!) : null,
                onBackgroundImageError: hasPhoto ? (_, _) {} : null,
                child: !hasPhoto
                    ? Text(
                        profile.initials,
                        style: TextStyle(
                          fontSize: radius * 0.65,
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
                  padding: const .all(3.5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                  ),
                  child: Icon(Icons.camera_alt, size: radius * 0.45, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upper-right Member Profile Dialog combining Belong fellowship fields
/// (Avatar, First/Last Name, ICOC Church Affiliation, Bio) with composable
/// `firebase_ui_auth` account management (#23, #26, #35, #672).
class MemberProfileDialog extends HookConsumerWidget {
  const MemberProfileDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const MemberProfileDialog());

  static bool _isSystemDefaultBio(String bio) {
    final trimmed = bio.trim();
    return trimmed.isEmpty ||
        trimmed == 'Verified Member of Belong on the Spectrum' ||
        trimmed == 'Exploring Belong on the Spectrum';
  }

  static fb_auth.FirebaseAuth? _liveFirebaseAuthWithUser() {
    try {
      if (Firebase.apps.isEmpty) return null;
      final auth = fb_auth.FirebaseAuth.instance;
      return auth.currentUser != null ? auth : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final profile = ref.watch(memberProfileProvider);

    final firstNameController = useTextEditingController(text: profile.firstName);
    final lastNameController = useTextEditingController(text: profile.lastName);
    final emailController = useTextEditingController(text: profile.email);
    final bioController = useTextEditingController(
      text: _isSystemDefaultBio(profile.bio) ? '' : profile.bio,
    );
    final churchAffiliationController = useTextEditingController(
      text: profile.icocChurchAffiliation ?? '',
    );
    final selectedAffiliation = useState<String?>(profile.icocChurchAffiliation);
    final validationError = useState<String?>(null);

    final allAffiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

    final liveAuth = _liveFirebaseAuthWithUser();

    return AlertDialog(
      titlePadding: const .fromLTRB(20, 20, 20, 12),
      contentPadding: const .fromLTRB(20, 4, 20, 12),
      actionsPadding: const .fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          const BelongEditableAvatar(radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  profile.isSignedIn ? profile.displayName : 'Member Profile & Sign-In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (profile.isSignedIn && profile.email.isNotEmpty)
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                    ),
                  )
                else if (!profile.isSignedIn)
                  Text(
                    'Complete your fellowship profile',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
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
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              if (validationError.value != null) ...[
                Container(
                  key: const Key('profile_validation_error_banner'),
                  padding: const .all(8),
                  margin: const .only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: .circular(8),
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
              Row(
                crossAxisAlignment: .start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('profile_display_name_field'),
                      controller: firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        hintText: 'First name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('profile_last_name_field'),
                      controller: lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Last name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (!profile.isSignedIn || profile.email.isEmpty) ...[
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
              ],
              if (brand.enableFellowshipAffiliationField) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: .min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        brand.fellowshipAffiliationPrompt,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                TextFormField(
                  key: const Key('profile_church_affiliation_dropdown'),
                  controller: churchAffiliationController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const .symmetric(horizontal: 10, vertical: 10),
                    border: const OutlineInputBorder(),
                    hintText: 'Select or enter your church affiliation...',
                    hintStyle: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
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
                    final offset = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
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
              TextField(
                key: const Key('profile_bio_field'),
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Bio / Note to Fellowship',
                  hintText: 'A quiet sentence about yourself',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final isPreview = ref.watch(previewFeaturesEnabledProvider);
                  return SwitchListTile.adaptive(
                    key: const Key('preview_mode_switch'),
                    contentPadding: .zero,
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
              if (profile.isSignedIn) ...[
                const SizedBox(height: 4),
                if (liveAuth != null)
                  FirebaseUIActions(
                    actions: [
                      AccountDeletedAction((ctx, _) async {
                        await ref.read(memberProfileProvider.notifier).signOut();
                        if (ctx.mounted && Navigator.of(ctx).canPop()) {
                          Navigator.of(ctx).pop();
                        }
                      }),
                      SignedOutAction((ctx) async {
                        await ref.read(memberProfileProvider.notifier).signOut();
                        if (ctx.mounted && Navigator.of(ctx).canPop()) {
                          Navigator.of(ctx).pop();
                        }
                      }),
                    ],
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme
                              .copyWith(onError: Theme.of(context).colorScheme.error),
                        ),
                        child: DeleteAccountButton(
                          key: const Key('delete_my_account_button'),
                          auth: liveAuth,
                          variant: ButtonVariant.text,
                          showDeleteConfirmationDialog: true,
                          onSignInRequired: () => showReauthenticateDialog(
                            context: context,
                            providers: [EmailAuthProvider()],
                            auth: liveAuth,
                            onSignedIn: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('delete_my_account_button'),
                      onPressed: () => DeleteMyAccountDialog.show(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const .symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete account'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (profile.isSignedIn)
          TextButton(
            key: const Key('profile_sign_out_button'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () async {
              await ref.read(memberProfileProvider.notifier).signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        TextButton(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('profile_save_sign_in_button'),
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: () {
            final affiliation = churchAffiliationController.text.trim();
            if (brand.enableFellowshipAffiliationField && affiliation.isEmpty) {
              validationError.value = 'Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".';
              return;
            }

            final combinedName = [
              firstNameController.text.trim(),
              lastNameController.text.trim(),
            ].where((part) => part.isNotEmpty).join(' ');
            final effectiveName = combinedName.isNotEmpty ? combinedName : profile.displayName;
            final effectiveBio = bioController.text.trim().isNotEmpty
                ? bioController.text.trim()
                : profile.bio;

            ref
                .read(memberProfileProvider.notifier)
                .signIn(
                  displayName: effectiveName,
                  email: emailController.text.trim().isNotEmpty
                      ? emailController.text.trim()
                      : profile.email,
                  bio: effectiveBio,
                  icocChurchAffiliation: affiliation,
                );
            Navigator.of(context).pop();
          },
          child: Text(profile.isSignedIn ? 'Save Profile' : 'Save & Sign In'),
        ),
      ],
    );
  }
}
