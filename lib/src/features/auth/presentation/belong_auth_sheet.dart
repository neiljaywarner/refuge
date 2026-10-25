import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../account_deletion/data/account_deletion_provider.dart';
import '../../account_deletion/presentation/return_after_delete_panel.dart';
import '../../branding/presentation/brand_config_provider.dart';
import '../../profile/domain/member_profile.dart';
import '../domain/auth_exception.dart';
import '../../../core/config/preview_mode_provider.dart';

/// Neurodivergent-friendly authentication dialog & sheet for Belong.
///
/// Supports:
/// 1. Email & Password Sign-In
/// 2. Account Registration with required ICOC church affiliation selection
/// 3. Passwordless Magic Link Sign-In / Link consumption
class BelongAuthSheet extends HookConsumerWidget {
  const BelongAuthSheet({super.key, this.initialTab = 0});

  final int initialTab;

  /// Shows the dialog or sheet responsively.
  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BelongAuthSheet(initialTab: initialTab),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(communityBrandConfigProvider);
    final currentProfile = ref.watch(memberProfileProvider);
    final previewFeaturesEnabled = ref.watch(previewFeaturesEnabledProvider);

    final tabController = useTabController(
      initialLength: 3,
      initialIndex: initialTab,
    );
    final activeTabIndex = useState<int>(initialTab);

    // Form inputs
    final emailController = useTextEditingController(
      text: currentProfile.isSignedIn ? currentProfile.email : '',
    );
    final passwordController = useTextEditingController();
    final displayNameController = useTextEditingController(
      text: currentProfile.isSignedIn ? currentProfile.displayName : '',
    );
    final magicLinkInputController = useTextEditingController();
    final resetEmailController = useTextEditingController();

    // Church affiliation for registration
    final churchAffiliationController = useTextEditingController(
      text: currentProfile.icocChurchAffiliation ?? '',
    );
    final selectedAffiliation = useState<String?>(
      currentProfile.icocChurchAffiliation,
    );

    // UI state
    final obscurePassword = useState<bool>(true);
    final isLoading = useState<bool>(false);
    final errorMessage = useState<String?>(null);
    final successMessage = useState<String?>(null);
    final pendingReturnUserId = useState<String?>(null);

    final allAffiliationOptions = [
      ...brand.fellowshipAffiliationOptions,
      brand.fellowshipNonMemberOption,
    ];

    useEffect(() {
      void listener() {
        activeTabIndex.value = tabController.index;
        errorMessage.value = null;
        successMessage.value = null;
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    Future<void> handleSignIn() async {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (email.isEmpty) {
        errorMessage.value = 'Please enter your email address.';
        return;
      }
      if (password.isEmpty) {
        errorMessage.value = 'Please enter your password.';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      try {
        await ref
            .read(memberProfileProvider.notifier)
            .signInWithPassword(email: email, password: password);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        final authEx = AuthException.fromFirebase(e);
        if (authEx.code == 'account-soft-deleted') {
          pendingReturnUserId.value = authEx.userId;
        }
        errorMessage.value = authEx.message;
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleRegister() async {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final displayName = displayNameController.text.trim();
      final affiliation = churchAffiliationController.text.trim();

      if (displayName.isEmpty) {
        errorMessage.value =
            'Please enter a name or nickname you would like to be called.';
        return;
      }
      if (email.isEmpty) {
        errorMessage.value = 'Please enter your email address.';
        return;
      }
      if (password.length < 6) {
        errorMessage.value = 'For your security, please choose a password with at least 6 characters.';
        return;
      }
      if (brand.enableFellowshipAffiliationField && affiliation.isEmpty) {
        errorMessage.value =
            'Please select which ICOC church you attend, or choose "${brand.fellowshipNonMemberOption}".';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      try {
        await ref
            .read(memberProfileProvider.notifier)
            .registerWithPassword(
              email: email,
              password: password,
              displayName: displayName,
              icocChurchAffiliation: affiliation,
            );
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        final authEx = AuthException.fromFirebase(e);
        errorMessage.value = authEx.message;
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleSendMagicLink() async {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        errorMessage.value =
            'Please enter your email address so we can send your sign-in link.';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      try {
        await ref
            .read(memberProfileProvider.notifier)
            .sendMagicLink(email: email);
        successMessage.value =
            'A secure sign-in link has been sent to $email. Please check your inbox or paste the link below.';
      } catch (e) {
        final authEx = AuthException.fromFirebase(e);
        errorMessage.value = authEx.message;
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleConsumeMagicLink() async {
      final email = emailController.text.trim();
      final link = magicLinkInputController.text.trim();
      if (email.isEmpty) {
        errorMessage.value = 'Please enter your email address.';
        return;
      }
      if (link.isEmpty) {
        errorMessage.value =
            'Please paste the magic link received in your email.';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      try {
        await ref
            .read(memberProfileProvider.notifier)
            .signInWithMagicLink(email: email, emailLink: link);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        final authEx = AuthException.fromFirebase(e);
        if (authEx.code == 'account-soft-deleted') {
          pendingReturnUserId.value = authEx.userId;
        }
        errorMessage.value = authEx.message;
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> handleForgotPassword() async {
      resetEmailController.text = emailController.text.trim();
      final dialogContext = context;

      final requested = await showDialog<bool>(
        context: dialogContext,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your account email to receive a password reset link.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('auth_reset_password_email_field'),
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('auth_reset_password_cancel_button'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('auth_send_password_reset_button'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      );

      if (requested == true) {
        final email = resetEmailController.text.trim();
        if (email.isEmpty) {
          errorMessage.value = 'Please enter your email address.';
          return;
        }
        isLoading.value = true;
        errorMessage.value = null;
        successMessage.value = null;
        try {
          await ref
              .read(memberProfileProvider.notifier)
              .sendPasswordResetEmail(email: email);
          successMessage.value =
              'Password reset instructions have been sent to $email.';
        } catch (e) {
          final authEx = AuthException.fromFirebase(e);
          errorMessage.value = authEx.message;
        } finally {
          isLoading.value = false;
        }
      }
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_person_rounded, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${brand.fullName} Account',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const Key('auth_sheet_close_button'),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: tabController,
            isScrollable: false,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(key: Key('auth_tab_sign_in'), text: 'Sign In'),
              Tab(key: Key('auth_tab_register'), text: 'Register'),
              Tab(key: Key('auth_tab_magic_link'), text: 'Magic Link'),
            ],
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
              if (previewFeaturesEnabled) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('auth_google_sign_in_button'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(memberProfileProvider.notifier)
                          .signInWithOAuth('google');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or with email',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (errorMessage.value != null) ...[
                Container(
                  key: const Key('auth_error_banner'),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          key: const Key('auth_error_text'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (successMessage.value != null) ...[
                Container(
                  key: const Key('auth_success_banner'),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          successMessage.value!,
                          key: const Key('auth_success_text'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tab 0: Sign In
              if (pendingReturnUserId.value != null) ...[
                ReturnAfterDeletePanel(
                  onRestore: () async {
                    final userId = pendingReturnUserId.value;
                    if (userId == null) return;
                    await ref
                        .read(accountDeletionRepositoryProvider)
                        .restoreSelf(userId: userId, confirmed: true);
                    pendingReturnUserId.value = null;
                    errorMessage.value = null;
                    final email = emailController.text.trim();
                    final password = passwordController.text;
                    if (password.isNotEmpty) {
                      await ref
                          .read(memberProfileProvider.notifier)
                          .signInWithPassword(email: email, password: password);
                    } else {
                      await ref
                          .read(memberProfileProvider.notifier)
                          .signInWithMagicLink(
                            email: email,
                            emailLink: magicLinkInputController.text.trim(),
                          );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  onStayDeleted: () async {
                    pendingReturnUserId.value = null;
                  },
                ),
              ] else if (activeTabIndex.value == 0) ...[
                TextField(
                  key: const Key('auth_sign_in_email_field'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('auth_sign_in_password_field'),
                  controller: passwordController,
                  obscureText: obscurePassword.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.key_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('auth_sign_in_submit_button'),
                    onPressed: isLoading.value ? null : handleSignIn,
                    icon: isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign In with Password'),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      key: const Key('auth_forgot_password_button'),
                      onPressed: isLoading.value ? null : handleForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                    TextButton(
                      key: const Key('auth_switch_to_magic_link_button'),
                      onPressed: () => tabController.animateTo(2),
                      child: const Text('Magic Link →'),
                    ),
                  ],
                ),
              ],

              // Tab 1: Register
              if (activeTabIndex.value == 1 &&
                  pendingReturnUserId.value == null) ...[
                TextField(
                  key: const Key('auth_register_display_name_field'),
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Display Name',
                    helperText: 'What should other members call you?',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('auth_register_email_field'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('auth_register_password_field'),
                  controller: passwordController,
                  obscureText: obscurePassword.value,
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 chars)',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (brand.enableFellowshipAffiliationField) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        brand.fellowshipAffiliationPrompt,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Required: Confirms whether you are part of our church fellowship or a welcoming visitor.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('auth_register_church_affiliation_dropdown'),
                    controller: churchAffiliationController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Select or enter your church affiliation...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                      suffixIcon: PopupMenuButton<String>(
                        key: const Key(
                          'auth_register_church_dropdown_trigger_button',
                        ),
                        tooltip: 'Select church affiliation',
                        icon: const Icon(Icons.arrow_drop_down, size: 24),
                        onSelected: (val) {
                          churchAffiliationController.text = val;
                          selectedAffiliation.value = val;
                          errorMessage.value = null;
                        },
                        itemBuilder: (context) =>
                            allAffiliationOptions.map((opt) {
                              final isNonMember =
                                  opt == brand.fellowshipNonMemberOption;
                              return PopupMenuItem<String>(
                                value: opt,
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: isNonMember
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    onTap: () async {
                      final RenderBox? box =
                          context.findRenderObject() as RenderBox?;
                      final offset = box != null
                          ? box.localToGlobal(Offset.zero)
                          : Offset.zero;
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
                          final isNonMember =
                              opt == brand.fellowshipNonMemberOption;
                          return PopupMenuItem<String>(
                            value: opt,
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: isNonMember
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                      if (selected != null) {
                        churchAffiliationController.text = selected;
                        selectedAffiliation.value = selected;
                        errorMessage.value = null;
                      }
                    },
                    onChanged: (val) {
                      selectedAffiliation.value = val;
                      if (val.trim().isNotEmpty) {
                        errorMessage.value = null;
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('auth_register_submit_button'),
                    onPressed: isLoading.value ? null : handleRegister,
                    icon: isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Create Account'),
                  ),
                ),
              ],

              // Tab 2: Magic Link
              if (activeTabIndex.value == 2 &&
                  pendingReturnUserId.value == null) ...[
                Text(
                  'Sign in without memorizing a password. We will email you a secure link that signs you in with one click.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('auth_magic_link_email_field'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Your Email Address',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('auth_send_magic_link_button'),
                    onPressed: isLoading.value ? null : handleSendMagicLink,
                    icon: isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Magic Link to Email'),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 6),
                const Text(
                  'Already received a link?',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('auth_paste_magic_link_field'),
                  controller: magicLinkInputController,
                  decoration: const InputDecoration(
                    labelText: 'Paste Magic Link URL or Token',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('auth_complete_magic_link_button'),
                    onPressed: isLoading.value ? null : handleConsumeMagicLink,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Complete Sign-In with Link'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
