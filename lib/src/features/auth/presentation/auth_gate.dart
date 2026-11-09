import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../account_deletion/data/account_deletion_provider.dart';
import '../../account_deletion/presentation/return_after_delete_panel.dart';
import '../../admin/data/admin_banning_repository.dart';
import '../../admin/presentation/account_paused_banner.dart';
import '../../profile/data/profile_storage_service.dart';
import '../../profile/domain/member_profile.dart';
import '../../profile/presentation/first_visit_welcome_card.dart';
import '../../reflections/data/post_repository.dart';
import '../../sensory_themes/presentation/sensory_theme_controller.dart';
import '../../../home_screen.dart';
import '../../group_call/data/stream_video_preview_config.dart';
import '../../group_call/domain/guest_invite.dart';
import '../../group_call/presentation/group_call_flow.dart';
import '../../group_call/presentation/group_call_guest_join_page.dart';
import '../../group_call/presentation/group_call_lobby.dart';
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
/// 2. not soft-deleted (else [ReturnAfterDeletePanel]),
/// 3. not banned (else the lockout copy, which stays up after sign-out), and
/// 4. in production only, email-verified.
///
/// Dev does not send a verification email and does not show a reminder.
/// Other non-production flavors keep the soft banner.
///
/// Reads [authRepositoryProvider], not [memberProfileProvider].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({
    super.key,
    required this.repository,
    required this.themeNotifier,
    this.groupCallPreviewCompiled = streamVideoPreviewEnabled,
    this.groupCallLocation,
    this.inviteSignals,
    this.guestTokenClientFactory,
    this.onGuestReady,
  });

  final PostRepository repository;
  final ThemeNotifier themeNotifier;

  /// Preview compile flag. Tests pass true. Production builds leave it false.
  final bool groupCallPreviewCompiled;

  /// Page address. Tests pass a fixed link. The app uses the browser address.
  final Uri? groupCallLocation;

  /// Invite from a cold start or a later VIEW intent. [Uri.base] on Android
  /// stays `file://` and is not this value.
  final GuestInviteSignals? inviteSignals;

  final GuestJoinClientBuilder? guestTokenClientFactory;

  final GroupCallStarter? onGuestReady;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthSession? _reloadedSession;

  @override
  void initState() {
    super.initState();
    widget.inviteSignals?.addListener(_onInvite);
  }

  @override
  void didUpdateWidget(covariant AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inviteSignals == widget.inviteSignals) return;
    oldWidget.inviteSignals?.removeListener(_onInvite);
    widget.inviteSignals?.addListener(_onInvite);
  }

  @override
  void dispose() {
    widget.inviteSignals?.removeListener(_onInvite);
    super.dispose();
  }

  void _onInvite() {
    if (mounted) setState(() {});
  }

  /// Soft-delete lookup, cached per user id so rebuilds do not re-query.
  String? _deleteCheckUserId;
  Future<bool>? _deleteCheck;

  /// Ban lookup, cached per user id. Runs before the feed is built.
  String? _banCheckUserId;
  Future<bool>? _banCheck;
  bool _banRefusalScheduled = false;

  /// Firebase UI registration does not send a verification email, so the
  /// gate sends one the first time a prod member lands on the verify wall.
  String? _verificationSentFor;
  Future<void>? _initialVerification;

  /// Session-local skip so the first-visit card does not flash again before storage reloads.
  bool _skippedFirstVisit = false;

  AuthSession _effectiveSession(AuthSession streamSession) => _reloadedSession ?? streamSession;

  String? _accountForCache(AuthSession session) {
    if (!session.isSignedIn) return null;
    final id = session.userId.trim();
    if (id.isEmpty || id == 'guest') return null;
    return id;
  }

  String? _lastAdoptedAccount;
  bool _adoptScheduled = false;

  void _adoptCachedAccount(AuthSession session) {
    final accountId = _accountForCache(session);
    if (_adoptScheduled && _lastAdoptedAccount == accountId) return;
    _adoptScheduled = true;
    _lastAdoptedAccount = accountId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.repository.adoptSignedInAccount(accountId));
    });
  }

  Future<bool> _isSoftDeleted(String userId) {
    if (_deleteCheckUserId != userId || _deleteCheck == null) {
      _deleteCheckUserId = userId;
      _deleteCheck = ref.read(accountDeletionRepositoryProvider).isSignInBlocked(userId);
    }
    return _deleteCheck!;
  }

  Future<bool> _isBanned(AuthSession session) {
    if (_banCheckUserId != session.userId || _banCheck == null) {
      _banCheckUserId = session.userId;
      _banCheck = _lookupBan(session);
    }
    return _banCheck!;
  }

  Future<bool> _lookupBan(AuthSession session) async {
    final bans = ref.read(adminBanningRepositoryProvider);
    for (final key in [session.userId, session.email, session.displayName]) {
      if (key.trim().isEmpty) continue;
      if (await bans.isUserBanned(key)) return true;
    }
    return false;
  }

  void _scheduleBanRefusal() {
    if (_banRefusalScheduled) return;
    _banRefusalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(banRefusalVisibleProvider.notifier).state = true;
      await _signOut();
    });
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
        final session = next.value;
        if (session != null) {
          unawaited(widget.repository.adoptSignedInAccount(_accountForCache(session)));
        }
      }
    });

    final session = _effectiveSession(streamSession);
    _adoptCachedAccount(session);

    if (ref.watch(banRefusalVisibleProvider)) {
      return _BanRefusalWall(
        onBack: () {
          ref.read(banRefusalVisibleProvider.notifier).state = false;
          _banRefusalScheduled = false;
          _banCheck = null;
          _banCheckUserId = null;
        },
      );
    }

    if (!sessionMayEnterCommunity(session)) {
      final location = widget.groupCallLocation ?? widget.inviteSignals?.location ?? Uri.base;
      final invite = guestInviteFromLocation(location);
      if (guestJoinEntryVisible(
        compileTimePreview: widget.groupCallPreviewCompiled,
        inviteToken: invite,
      )) {
        final callId = explicitGroupCallIdFromLocation(location);
        final builder = widget.guestTokenClientFactory;
        return GroupCallGuestJoinPage(
          inviteToken: invite!,
          callId: callId,
          tokenClientFactory: () =>
              builder?.call(inviteToken: invite, callId: callId) ??
              buildLiveStreamGuestJoinClient(inviteToken: invite, callId: callId),
          onReady: widget.onGuestReady ?? pushStreamGroupCall,
        );
      }
      return KeyedSubtree(
        key: const Key('auth_gate_sign_in_wall'),
        child: SimpleSignInScreen(firebaseReady: Firebase.apps.isNotEmpty),
      );
    }

    return FutureBuilder<bool>(
      future: _isSoftDeleted(session.userId),
      builder: (context, deleteSnapshot) {
        if (deleteSnapshot.connectionState != ConnectionState.done) {
          return _checkingAccountScaffold;
        }

        if (deleteSnapshot.data ?? false) {
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

        return FutureBuilder<bool>(
          future: _isBanned(session),
          builder: (context, banSnapshot) {
            if (banSnapshot.connectionState != ConnectionState.done) {
              return _checkingAccountScaffold;
            }
            if (banSnapshot.data ?? false) {
              _scheduleBanRefusal();
              return const _BanRefusalWall();
            }
            if (sendsEmailVerification(flavor) && !session.emailVerified) {
              // Dev never reaches this. Other flavors send one message.
              // The wall below stays production-only.
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

            final profile = ref.watch(memberProfileProvider);
            final skipped =
                _skippedFirstVisit || ProfileStorageService.instance.skippedFirstVisitWelcome;
            if (profile.hasDefaultDisplayName && !skipped) {
              return FirstVisitWelcomeCard(
                onFinished: () => setState(() => _skippedFirstVisit = true),
              );
            }

            return RefugeHomeScreen(
              repository: widget.repository,
              themeNotifier: widget.themeNotifier,
            );
          },
        );
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
      _banCheck = null;
      _banCheckUserId = null;
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

/// Shown while a soft-delete or ban lookup is in flight.
const _checkingAccountScaffold = Scaffold(
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

/// Full-screen refusal. Stays up after sign-out so the member can read it.
class _BanRefusalWall extends StatelessWidget {
  const _BanRefusalWall({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('auth_gate_ban_refusal'),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AccountPausedLockout(),
              if (onBack != null)
                TextButton(
                  key: const Key('ban_refusal_back_to_sign_in'),
                  onPressed: onBack,
                  child: const Text('Back to sign in'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
