import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../data/auth_repository.dart';
import '../domain/auth_access_policy.dart';
import '../domain/auth_session.dart';
import 'verify_email_copy.dart';

/// Home notice for flavors that do not block on email verification.
///
/// The member can keep using the app. The first visit sends one verification
/// email and says so. Resend stays on screen if that message does not arrive.
class UnverifiedEmailBanner extends ConsumerStatefulWidget {
  const UnverifiedEmailBanner({super.key});

  @override
  ConsumerState<UnverifiedEmailBanner> createState() => _UnverifiedEmailBannerState();
}

class _UnverifiedEmailBannerState extends ConsumerState<UnverifiedEmailBanner> {
  String? _startedForUserId;
  String? _queuedUserId;
  bool _busy = false;
  String? _status;

  AuthSession _session(AsyncValue<AuthSession> streamValue) {
    final repo = ref.read(authRepositoryProvider);
    return streamValue.value ?? streamValue.asData?.value ?? repo.currentSession();
  }

  void _queueFirstSend(String userId) {
    if (_startedForUserId == userId || _queuedUserId == userId) return;
    _queuedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startedForUserId == userId) return;
      _startedForUserId = userId;
      _send(automatic: true);
    });
  }

  Future<void> _send({required bool automatic}) async {
    if (!automatic && _busy) return;
    setState(() {
      if (!automatic) _busy = true;
      _status = VerifyEmailCopy.softBannerSending;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _status = automatic ? VerifyEmailCopy.softBannerSent : VerifyEmailCopy.softBannerResent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = friendlyVerifyEmailError(e));
    } finally {
      if (!automatic && mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(appFlavorProvider);
    final session = _session(ref.watch(authSessionStreamProvider));
    if (!showSoftVerifyBanner(flavor: flavor, session: session)) {
      return const SizedBox.shrink();
    }
    _queueFirstSend(session.userId);

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('home_verify_email_banner'),
      padding: const .fromLTRB(12, 8, 12, 0),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: .circular(10),
        child: Padding(
          padding: const .fromLTRB(12, 10, 12, 4),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Text(
                VerifyEmailCopy.softBannerBody(session.email),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_status != null) ...[
                const SizedBox(height: 6),
                Text(
                  _status!,
                  key: const Key('home_verify_email_status'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('home_resend_verification'),
                  onPressed: _busy ? null : () => _send(automatic: false),
                  child: const Text(VerifyEmailCopy.resendButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
