import 'package:firebase_auth/firebase_auth.dart' as fb_auth hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/preview_mode_provider.dart';
import '../../../core/presentation/system_insets.dart';
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
    useEffect(() {
      final restored = profile.icocChurchAffiliation;
      if (restored != null &&
          restored.trim().isNotEmpty &&
          churchAffiliationController.text.trim().isEmpty) {
        churchAffiliationController.text = restored;
        selectedAffiliation.value = restored;
      }
      return null;
    }, [profile.icocChurchAffiliation]);
    final validationError = useState<String?>(null);
    final firstNameFocus = useFocusNode();
    final lastNameFocus = useFocusNode();
    final emailFocus = useFocusNode();
    final churchFocus = useFocusNode();
    final bioFocus = useFocusNode();
    useEffect(() {
      final nodes = [firstNameFocus, lastNameFocus, emailFocus, churchFocus, bioFocus];
      void listener() => _scheduleProfileFieldReveal(nodes);
      for (final node in nodes) {
        node.addListener(listener);
      }
      return () {
        for (final node in nodes) {
          node.removeListener(listener);
        }
      };
    }, [firstNameFocus, lastNameFocus, emailFocus, churchFocus, bioFocus]);

    final allAffiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

    final liveAuth = _liveFirebaseAuthWithUser();
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    // Above this, Sign Out / Cancel / Save stack so each stays a full-width
    // target and Experimental Preview Features can scroll into view (#932).
    final largeText = textScale > 1.15;
    final keyboardInset = media.viewInsets.bottom;
    final keyboardUp = keyboardInset > 0;
    useEffect(() {
      if (keyboardInset <= 0) return null;
      _scheduleProfileFieldReveal([
        firstNameFocus,
        lastNameFocus,
        emailFocus,
        churchFocus,
        bioFocus,
      ]);
      return null;
    }, [keyboardInset, firstNameFocus, lastNameFocus, emailFocus, churchFocus, bioFocus]);
    final available = media.size.width - (keyboardUp ? 24 : 80);
    final sheetWidth = available < 380 ? available.clamp(220.0, 380.0) : 380.0;
    final fieldGap = keyboardUp ? 8.0 : 12.0;
    // A 2-line bio is taller than the band above the keyboard on a short phone.
    final bioLines = keyboardUp && media.size.height - keyboardInset < 420 ? 1 : 2;
    final baseInset = SystemInsets.dialogInsetPadding(media);
    final insetPadding = keyboardUp ? EdgeInsets.fromLTRB(12, baseInset.top, 12, 8) : baseInset;

    Future<void> signOut() async {
      await ref.read(memberProfileProvider.notifier).signOut();
      if (context.mounted) Navigator.of(context).pop();
    }

    void cancel() => Navigator.of(context).pop();

    void saveProfile() {
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
    }

    final signOutButton = profile.isSignedIn
        ? TextButton(
            key: const Key('profile_sign_out_button'),
            style: TextButton.styleFrom(
              visualDensity: largeText ? VisualDensity.standard : VisualDensity.compact,
              minimumSize: largeText ? const Size(48, 48) : null,
            ),
            onPressed: signOut,
            child: const Text('Sign Out'),
          )
        : null;
    final cancelButton = TextButton(
      key: const Key('profile_cancel_button'),
      style: TextButton.styleFrom(
        visualDensity: largeText ? VisualDensity.standard : VisualDensity.compact,
        minimumSize: largeText ? const Size(48, 48) : null,
      ),
      onPressed: cancel,
      child: const Text('Cancel'),
    );
    final saveButton = FilledButton(
      key: const Key('profile_save_sign_in_button'),
      style: FilledButton.styleFrom(
        visualDensity: largeText ? VisualDensity.standard : VisualDensity.compact,
        minimumSize: largeText ? const Size(48, 48) : null,
      ),
      onPressed: saveProfile,
      child: Text(
        profile.isSignedIn ? 'Save Profile' : 'Save & Sign In',
        textAlign: TextAlign.center,
      ),
    );
    Widget stretch(Widget child) => Row(children: [Expanded(child: child)]);
    final stackedActions = Column(
      crossAxisAlignment: .stretch,
      children: [
        stretch(saveButton),
        const SizedBox(height: 8),
        stretch(cancelButton),
        if (signOutButton != null) ...[const SizedBox(height: 8), stretch(signOutButton)],
      ],
    );

    final stackActions = largeText || keyboardUp;
    final inlineActions = Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [?signOutButton, cancelButton, saveButton],
      ),
    );

    InputDecoration fieldDecoration({
      required String label,
      String? hintText,
      String? helperText,
    }) => InputDecoration(
      labelText: largeText ? null : label,
      hintText: hintText,
      helperText: helperText,
      isDense: true,
      border: const OutlineInputBorder(),
    );

    Widget profileField({
      required Key key,
      required String label,
      required String identifier,
      required FocusNode focusNode,
      required TextEditingController controller,
      String? hintText,
      String? helperText,
      TextInputType? keyboardType,
      TextCapitalization textCapitalization = TextCapitalization.none,
      int maxLines = 1,
    }) => _WrappingFieldLabel(
      label: label,
      largeText: largeText,
      identifier: identifier,
      child: TextField(
        key: key,
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        scrollPadding: const .symmetric(vertical: 8, horizontal: 8),
        decoration: fieldDecoration(label: label, hintText: hintText, helperText: helperText),
      ),
    );

    final firstNameField = profileField(
      key: const Key('profile_display_name_field'),
      label: 'First Name',
      identifier: 'profile_display_name_field',
      focusNode: firstNameFocus,
      controller: firstNameController,
      hintText: 'First name',
      textCapitalization: TextCapitalization.words,
    );
    final lastNameField = profileField(
      key: const Key('profile_last_name_field'),
      label: 'Last Name',
      identifier: 'profile_last_name_field',
      focusNode: lastNameFocus,
      controller: lastNameController,
      hintText: 'Last name',
      textCapitalization: TextCapitalization.words,
    );

    return Dialog(
      insetPadding: insetPadding,
      alignment: keyboardUp ? Alignment.topCenter : Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sheetWidth),
        child: SingleChildScrollView(
          key: const Key('profile_sheet_scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: .fromLTRB(16, keyboardUp ? 8 : 16, 16, 12),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                crossAxisAlignment: .start,
                children: [
                  BelongEditableAvatar(radius: keyboardUp ? 16 : 20),
                  SizedBox(width: keyboardUp ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          profile.isSignedIn ? profile.displayName : 'Member Profile & Sign-In',
                          // One line while the keyboard is open so the first
                          // field still fits on a short phone at large text.
                          maxLines: keyboardUp ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: keyboardUp ? 15 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!keyboardUp && profile.isSignedIn && profile.email.isNotEmpty)
                          Text(
                            profile.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          )
                        else if (!keyboardUp && !profile.isSignedIn)
                          Text(
                            'Complete your fellowship profile',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
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
                    visualDensity: keyboardUp ? VisualDensity.compact : VisualDensity.standard,
                  ),
                ],
              ),
              SizedBox(height: keyboardUp ? 8 : 12),
              if (validationError.value != null) ...[
                Container(
                  key: const Key('profile_validation_error_banner'),
                  padding: const .all(8),
                  margin: .only(bottom: fieldGap),
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
              if (largeText)
                Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    firstNameField,
                    SizedBox(height: fieldGap),
                    lastNameField,
                  ],
                )
              else
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(child: firstNameField),
                    const SizedBox(width: 10),
                    Expanded(child: lastNameField),
                  ],
                ),
              if (!profile.isSignedIn || profile.email.isEmpty) ...[
                SizedBox(height: fieldGap),
                profileField(
                  key: const Key('profile_email_field'),
                  label: 'Email Address',
                  identifier: 'profile_email_field',
                  focusNode: emailFocus,
                  controller: emailController,
                  helperText: keyboardUp ? null : 'For notifications and account recovery',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
              if (brand.enableFellowshipAffiliationField) ...[
                SizedBox(height: keyboardUp ? 8 : 14),
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
                if (!keyboardUp) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Required: Confirms whether you are part of our church fellowship or a welcoming visitor.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Semantics(
                  identifier: 'profile_church_affiliation_dropdown',
                  child: TextFormField(
                    key: const Key('profile_church_affiliation_dropdown'),
                    focusNode: churchFocus,
                    controller: churchAffiliationController,
                    scrollPadding: const .symmetric(vertical: 8, horizontal: 8),
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
                    onChanged: (val) {
                      selectedAffiliation.value = val;
                      if (val.trim().isNotEmpty) {
                        validationError.value = null;
                      }
                    },
                  ),
                ),
              ],
              SizedBox(height: keyboardUp ? 8 : 14),
              profileField(
                key: const Key('profile_bio_field'),
                label: 'Bio / Note to Fellowship',
                identifier: 'profile_bio_field',
                focusNode: bioFocus,
                controller: bioController,
                hintText: 'A quiet sentence about yourself',
                maxLines: bioLines,
              ),
              SizedBox(height: keyboardUp ? 8 : 12),
              const Divider(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final isPreview = ref.watch(previewFeaturesEnabledProvider);
                  return SwitchListTile.adaptive(
                    key: const Key('preview_mode_switch'),
                    contentPadding: .zero,
                    dense: !largeText,
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
                      ref.read(memberProfileProvider.notifier).persistPreviewFeatures(val);
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
              SizedBox(height: stackActions ? 16 : 8),
              if (stackActions) stackedActions else inlineActions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Brings the focused profile field to the top of the dialog scroll view
/// after the caret's own reveal animation, so the whole field stays above
/// the keyboard (#992).
void _scheduleProfileFieldReveal(Iterable<FocusNode> nodes) {
  for (final node in nodes) {
    if (!node.hasFocus) continue;
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!node.hasFocus) return;
      final fieldContext = node.context;
      if (fieldContext == null || !fieldContext.mounted) return;
      Scrollable.ensureVisible(fieldContext, alignment: 0.0, duration: Duration.zero);
    });
  }
}

/// Floating field labels ellipsize to "First N…" at large text. Above the
/// field they can wrap to as many lines as the words need.
class _WrappingFieldLabel extends StatelessWidget {
  const _WrappingFieldLabel({
    required this.label,
    required this.largeText,
    required this.child,
    this.identifier,
  });

  final String label;
  final bool largeText;
  final Widget child;
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final field = Semantics(identifier: identifier, label: largeText ? label : null, child: child);
    if (!largeText) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(label)),
        const SizedBox(height: 4),
        field,
      ],
    );
  }
}
