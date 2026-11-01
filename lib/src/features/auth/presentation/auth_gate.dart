import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../account_deletion/data/account_deletion_provider.dart';
import '../../account_deletion/presentation/return_after_delete_panel.dart';
import '../../profile/domain/member_profile.dart';
import '../../reflections/data/post_repository.dart';
import '../../sensory_themes/presentation/sensory_theme_controller.dart';
import '../../../home_screen.dart';
import '../data/auth_repository.dart';
import '../domain/auth_access_policy.dart';
import '../domain/auth_session.dart';
import 'simple_sign_in_screen.dart';
import 'verify_email_copy.dart';

// TODO: troubleshoot later - the old SimpleAuthScreen (simple_auth.dart) and
// dev example account buttons were removed from this gate for #667. The old
// screen is kept in the repo; this gate now uses the plain firebase_ui_auth
// SignInScreen only.

/// Blocks the main app until the member is:
/// 1. signed in (plain [SimpleSignInScreen]),
/// 2. not soft-deleted (else [ReturnAfterDeletePanel]), and
/// 3. in production only, email-verified.
///
/// Other flavors keep the soft gate and explain verification on Home.
///
/// Reads [authRepositoryProvider], not [memberProfileProvider].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.repository, required this.themeNotifier});

  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthSession? _reloadedSession;

  /// Soft-delete lookup, cached per user id so rebuilds do not re-query.
  String? _deleteCheckUserId;
  Future<bool>? _deleteCheck;

  /// Firebase UI registration does not send a verification email, so the
  /// gate sends one the first time a prod member lands on the verify wall.
  String? _verificationSentFor;
  Future<void>? _initialVerification;

  AuthSession _effectiveSession(AuthSession streamSession) => _reloadedSession ?? streamSession;

  Future<bool> _isSoftDeleted(String userId) {
    if (_deleteCheckUserId != userId || _deleteCheck == null) {
      _deleteCheckUserId = userId;
      _deleteCheck = ref.read(accountDeletionRepositoryProvider).isSignInBlocked(userId);
    }
    return _deleteCheck!;
  }

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
        child: SimpleSignInScreen(firebaseReady: Firebase.apps.isNotEmpty),
      );
    }

    return FutureBuilder<bool>(
      future: _isSoftDeleted(session.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            key: Key('auth_gate_checking_account'),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      VerifyEmailCopy.checkingAccount,
                      key: Key('auth_gate_checking_account_message'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data ?? false) {
          return Scaffold(
            key: const Key('auth_gate_soft_deleted_wall'),
            appBar: AppBar(title: const Text('Come back?'), centerTitle: true),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ReturnAfterDeletePanel(
                  onStayDeleted: _signOut,
                  onRestore: () => _restore(session.userId),
                ),
              ),
            ),
          );
        }

        if (!session.emailVerified) {
          // Dev does not block, but still sends one message so a yopmail
          // inbox can confirm the account (#749). The wall stays prod-only.
          _sendVerificationOnce(session.userId);
        }

        if (mustVerifyEmail(flavor) && !session.emailVerified) {
          return KeyedSubtree(
            key: const Key('auth_gate_verify_email_wall'),
            child: _VerifyEmailWall(
              email: session.email,
              initialSend: _initialVerification,
              onReload: _reloadVerified,
              onResend: _resendVerification,
              onSignOut: _signOut,
            ),
          );
        }

        return RefugeHomeScreen(repository: widget.repository, themeNotifier: widget.themeNotifier);
      },
    );
  }

  void _sendVerificationOnce(String userId) {
    if (_verificationSentFor == userId) return;
    _verificationSentFor = userId;
    _initialVerification = _resendVerification();
  }

  Future<void> _restore(String userId) async {
    await ref.read(accountDeletionRepositoryProvider).restoreSelf(userId: userId, confirmed: true);
    if (!mounted) return;
    ref.read(memberProfileProvider.notifier).publishDirectoryAfterRestore();
    setState(() {
      _deleteCheckUserId = userId;
      _deleteCheck = Future.value(false);
    });
  }

  Future<AuthSession> _reloadVerified() async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.reloadCurrentUser();
    setState(() => _reloadedSession = updated);
    return updated;
  }

  Future<void> _resendVerification() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> _signOut() async {
    setState(() {
      _reloadedSession = null;
      _deleteCheck = null;
      _deleteCheckUserId = null;
    });
    await ref.read(memberProfileProvider.notifier).signOut();
  }
}

class _VerifyEmailWall extends StatefulWidget {
  const _VerifyEmailWall({
    required this.email,
    required this.initialSend,
    required this.onReload,
    required this.onResend,
    required this.onSignOut,
  });

  final String email;
  final Future<void>? initialSend;
  final Future<AuthSession?> Function() onReload;
  final Future<void> Function() onResend;
  final Future<void> Function() onSignOut;

  @override
  State<_VerifyEmailWall> createState() => _VerifyEmailWallState();
}

class _VerifyEmailWallState extends State<_VerifyEmailWall> {
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    final send = widget.initialSend;
    if (send != null) {
      _status = VerifyEmailCopy.wallSending;
      unawaited(_watchInitialSend(send));
    }
  }

  Future<void> _watchInitialSend(Future<void> send) async {
    try {
      await send;
      if (!mounted) return;
      setState(() => _status = VerifyEmailCopy.wallSent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = friendlyVerifyEmailError(e));
    }
  }

  Future<void> _handleReload() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.onReload();
      if (!mounted) return;
      if (updated != null && !updated.emailVerified) {
        setState(() => _status = VerifyEmailCopy.notVerifiedYet);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = friendlyVerifyEmailError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() => _status = VerifyEmailCopy.wallResent);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = friendlyVerifyEmailError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Check your email'), centerTitle: true),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                VerifyEmailCopy.wallBody(widget.email),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_status != null) ...[
                const SizedBox(height: 16),
                Text(
                  _status!,
                  key: const Key('auth_gate_verify_status'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('auth_gate_i_verified'),
                onPressed: _busy ? null : _handleReload,
                child: const Text('I verified my email'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('auth_gate_resend_verification'),
                onPressed: _busy ? null : _handleResend,
                child: const Text(VerifyEmailCopy.resendButton),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('auth_gate_sign_out'),
                onPressed: _busy ? null : widget.onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
