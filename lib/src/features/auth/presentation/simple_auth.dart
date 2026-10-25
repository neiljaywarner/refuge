import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/system_insets.dart';
import '../../account_deletion/data/account_deletion_provider.dart';
import '../../account_deletion/domain/soft_delete_sign_in_guard.dart';
import '../../account_deletion/presentation/soft_delete_sign_in_notice.dart';

/// Minimal, plain-vanilla wrapper around the official [firebase_ui_auth] example.
///
/// Provides out-of-the-box:
/// 1. [SignInScreen] with [EmailAuthProvider], register toggle, and forgot password.
/// 2. [ProfileScreen] showing account email, change password, and sign out.
/// 3. Zero custom forms or state overhead — plain vanilla Firebase Auth.
class SimpleAuthScreen extends StatelessWidget {
  const SimpleAuthScreen({
    super.key,
    this.auth,
    this.onAuthenticated,
    this.onSignedOut,
  });

  final FirebaseAuth? auth;
  final VoidCallback? onAuthenticated;
  final VoidCallback? onSignedOut;

  /// Opens the SimpleAuth screen directly via Navigator.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAuthenticated,
    VoidCallback? onSignedOut,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SystemBottomInset(
          child: SimpleAuthScreen(
            onAuthenticated: onAuthenticated,
            onSignedOut: onSignedOut,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];
    final effectiveAuth =
        auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

    if (effectiveAuth == null) {
      // In headless unit tests or when Firebase is uninitialized
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sign In to Belong'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SimpleAuthScreen._belongLogo(context, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'Belong on the Spectrum',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unhurried Christian fellowship',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('auth_offline_sign_in_button'),
                        onPressed: () {
                          onAuthenticated?.call();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text(
                          'Enter Community (Offline / Test Mode)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: effectiveAuth.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? effectiveAuth.currentUser;
        if (user == null) {
          return _BelongFirebaseSignIn(
            auth: effectiveAuth,
            providers: providers,
            onAuthenticated: onAuthenticated,
          );
        }

        return ProfileScreen(
          auth: effectiveAuth,
          providers: providers,
          actions: [
            SignedOutAction((context) {
              onSignedOut?.call();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }),
          ],
          appBar: AppBar(title: const Text('Account Profile')),
        );
      },
    );
  }

  static Widget _belongLogo(BuildContext context, {required double size}) {
    return belongSignInLogo(context, size: size);
  }
}

/// FirebaseUI sign-in that undoes the session when the account is soft-deleted.
class _BelongFirebaseSignIn extends HookConsumerWidget {
  const _BelongFirebaseSignIn({
    required this.auth,
    required this.providers,
    required this.onAuthenticated,
  });

  final FirebaseAuth auth;
  final List<EmailAuthProvider> providers;
  final VoidCallback? onAuthenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedMessage = useState<String?>(null);
    final watchedNotice = ref.watch(softDeleteSignInNoticeProvider);
    final message = blockedMessage.value ?? watchedNotice;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In to Belong'), centerTitle: true),
      body: SignInScreen(
        auth: auth,
        providers: providers,
        headerMaxExtent: 120,
        headerBuilder: (context, constraints, shrinkOffset) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  belongSignInLogo(context, size: 52),
                  const SizedBox(height: 6),
                  Text(
                    'Belong on the Spectrum',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
        subtitleBuilder: (context, action) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SoftDeleteSignInNotice(message: message),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  action == AuthAction.signIn
                      ? 'Sign in to access your reflections, spaces, and private saved items.'
                      : 'Join our calm Christian fellowship. No algorithmic rush.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
        footerBuilder: (context, action) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  'Safe, sensory-friendly & private',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        },
        actions: [
          AuthStateChangeAction<UserCreated>((context, state) {
            ref.read(softDeleteSignInNoticeProvider.notifier).state = null;
            onAuthenticated?.call();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }),
          AuthStateChangeAction<SignedIn>((context, state) {
            final userId = state.user?.uid ?? '';
            final isBlocked = ref
                .read(accountDeletionRepositoryProvider)
                .isSignInBlocked;
            () async {
              final notice = await softDeleteSignInBlockMessage(
                userId: userId,
                isBlocked: isBlocked,
              );
              if (!context.mounted) return;
              if (notice != null) {
                blockedMessage.value = notice;
                ref.read(softDeleteSignInNoticeProvider.notifier).state =
                    notice;
                try {
                  await auth.signOut();
                } catch (_) {}
                return;
              }
              ref.read(softDeleteSignInNoticeProvider.notifier).state = null;
              onAuthenticated?.call();
              if (context.mounted) Navigator.of(context).pop();
            }();
          }),
        ],
      ),
    );
  }
}

Widget belongSignInLogo(BuildContext context, {required double size}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.28),
    child: Image.asset(
      'assets/images/belong_logo.png',
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Icon(
        Icons.spa_rounded,
        size: size * 0.65,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
