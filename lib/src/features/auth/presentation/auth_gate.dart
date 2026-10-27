import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../profile/domain/member_profile.dart';
import '../../reflections/data/post_repository.dart';
import '../../sensory_themes/presentation/sensory_theme_controller.dart';
import '../../../home_screen.dart';
import '../data/auth_repository.dart';
import '../domain/auth_access_policy.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_session.dart';
import 'simple_sign_in_screen.dart';

/// Blocks the main app until the auth session is signed in and, in production,
/// email-verified. Reads [authRepositoryProvider], not [memberProfileProvider].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.repository, required this.themeNotifier});

  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthSession? _reloadedSession;
  String? _devExampleError;
  bool _devExampleLoading = false;

  AuthSession _effectiveSession(AuthSession streamSession) => _reloadedSession ?? streamSession;

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(appFlavorProvider);
    final streamValue = ref.watch(authSessionStreamProvider);
    final repo = ref.read(authRepositoryProvider);
    final streamSession = streamValue.value ?? streamValue.asData?.value ?? repo.currentSession();

    ref.listen<AsyncValue<AuthSession>>(authSessionStreamProvider, (_, next) {
      if (next.hasValue) {
        setState(() => _reloadedSession = null);
      }
    });

    final session = _effectiveSession(streamSession);

    if (!sessionMayEnterCommunity(session)) {
      return KeyedSubtree(
        key: const Key('auth_gate_sign_in_wall'),
        child: _SignInWall(
          devExampleError: _devExampleError,
          devExampleLoading: _devExampleLoading,
          flavor: flavor,
          onDevExampleTap: _signInWithDevExample,
        ),
      );
    }

    if (mustVerifyEmail(flavor) && !session.emailVerified) {
      return KeyedSubtree(
        key: const Key('auth_gate_verify_email_wall'),
        child: _VerifyEmailWall(
          email: session.email,
          onReload: _reloadVerified,
          onResend: _resendVerification,
          onSignOut: _signOut,
        ),
      );
    }

    return RefugeHomeScreen(repository: widget.repository, themeNotifier: widget.themeNotifier);
  }

  Future<void> _reloadVerified() async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.reloadCurrentUser();
    setState(() => _reloadedSession = updated);
  }

  Future<void> _resendVerification() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> _signOut() async {
    setState(() => _reloadedSession = null);
    await ref.read(memberProfileProvider.notifier).signOut();
  }

  Future<void> _signInWithDevExample(DevExampleAccount account) async {
    if (devExamplePassword.isEmpty) return;
    setState(() {
      _devExampleLoading = true;
      _devExampleError = null;
    });
    try {
      final notifier = ref.read(memberProfileProvider.notifier);
      try {
        await notifier.signInWithPassword(email: account.email, password: devExamplePassword);
      } on AuthException catch (e) {
        if (e.code == 'user-not-found') {
          await notifier.registerWithPassword(
            email: account.email,
            password: devExamplePassword,
            displayName: account.displayName,
            bio: account.bio,
            comfortBadges: account.comfortBadges,
            icocChurchAffiliation: account.icocChurchAffiliation,
          );
        } else {
          rethrow;
        }
      }
      notifier.signIn(
        displayName: account.displayName,
        email: account.email,
        bio: account.bio,
        comfortBadges: account.comfortBadges,
        icocChurchAffiliation: account.icocChurchAffiliation,
      );
    } on AuthException catch (e) {
      setState(() => _devExampleError = e.message);
    } catch (e) {
      setState(() {
        _devExampleError = AuthException.fromFirebase(e).message;
      });
    } finally {
      if (mounted) {
        setState(() => _devExampleLoading = false);
      }
    }
  }
}

class _SignInWall extends StatelessWidget {
  const _SignInWall({
    required this.flavor,
    required this.onDevExampleTap,
    required this.devExampleError,
    required this.devExampleLoading,
  });

  final AppFlavor flavor;
  final Future<void> Function(DevExampleAccount account) onDevExampleTap;
  final String? devExampleError;
  final bool devExampleLoading;

  @override
  Widget build(BuildContext context) {
    final showExamples = showDevExampleAccounts(
      flavor: flavor,
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
    );
    final passwordReady = devExamplePassword.isNotEmpty;

    return Column(
      children: [
        // TODO: troubleshoot later - old SimpleAuthScreen kept in simple_auth.dart.
        const Expanded(child: SimpleSignInScreen()),
        if (showExamples) ...[
          const Divider(height: 1),
          Padding(
            padding: const .fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                if (!passwordReady)
                  Text(
                    devExamplePasswordMissingMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                for (final account in devExampleAccounts) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    key: Key(account.semanticsKey),
                    onPressed: passwordReady && !devExampleLoading
                        ? () => onDevExampleTap(account)
                        : null,
                    child: Text(account.shortcutLabel),
                  ),
                ],
                if (devExampleError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    devExampleError!,
                    key: const Key('dev_example_sign_in_error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VerifyEmailWall extends StatelessWidget {
  const _VerifyEmailWall({
    required this.email,
    required this.onReload,
    required this.onResend,
    required this.onSignOut,
  });

  final String email;
  final Future<void> Function() onReload;
  final Future<void> Function() onResend;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check your email'), centerTitle: true),
    body: Center(
      child: SingleChildScrollView(
        padding: const .all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: .min,
            children: [
              Text(
                'We sent a verification link to $email. Open it, then come back.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('auth_gate_i_verified'),
                onPressed: onReload,
                child: const Text('I verified my email'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('auth_gate_resend_verification'),
                onPressed: onResend,
                child: const Text('Resend email'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('auth_gate_sign_out'),
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
