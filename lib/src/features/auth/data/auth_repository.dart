import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../account_deletion/data/account_deletion_provider.dart';
import '../../account_deletion/domain/account_deletion_exception.dart';
import '../../feedback/data/feature_voting_repository.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_session.dart';
import '../../../core/logging/app_logger.dart';
import 'auth_backend_target.dart';

export 'auth_backend_target.dart';

/// Pluggable authentication repository interface supporting:
/// - Firebase Authentication (Production Email/Password & Passwordless Magic Link)
/// - Serverpod & Appwrite hybrid migration seams (ADR-0009)
/// - In-Memory Auth (Deterministic, zero-network unit & widget testing)
abstract interface class AuthRepository {
  BackendTarget get target;

  /// Current synchronous session snapshot.
  AuthSession currentSession();

  /// Reactive stream of session updates.
  Stream<AuthSession> authStateChanges();

  /// Authenticate with email and password.
  Future<AuthSession> signInWithPassword({required String email, required String password});

  /// Create a new account with email, password, display name, and required church affiliation.
  Future<AuthSession> registerWithPassword({
    required String email,
    required String password,
    required String displayName,
    String? bio,
    List<String>? comfortBadges,
    required String icocChurchAffiliation,
  });

  /// Dispatch a passwordless "Magic Link" email for 1-tap sign-in.
  Future<void> sendMagicLink({required String email, String? redirectUrl});

  /// Complete sign-in using an incoming magic email link.
  Future<AuthSession> signInWithMagicLink({required String email, required String emailLink});

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Legacy synchronous helper for Stage 1 backward compatibility.
  AuthSession signInWithEmailAndName({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
    String? icocChurchAffiliation,
  });

  /// Legacy synchronous helper for OAuth providers ('google' | 'apple' | 'facebook').
  AuthSession signInWithOAuthProvider(String provider);

  /// Sign out current user.
  Future<AuthSession> signOut();

  /// Refreshes the current user from the auth backend (e.g. after email verification).
  Future<AuthSession> reloadCurrentUser();

  /// Sends an email verification link when required for the active flavor.
  Future<void> sendEmailVerification();
}

class _InMemoryUserRecord {
  _InMemoryUserRecord({required this.password, required this.session});

  final String password;
  AuthSession session;
}

/// In-Memory implementation of [AuthRepository] for deterministic testing.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({
    AuthSession initialSession = const AuthSession.guest(),
    this.isAccountSoftDeleted,
  }) : _session = initialSession {
    _controller.add(_session);
  }

  /// When this returns true, password and magic-link sign-in are refused.
  final Future<bool> Function(String userId)? isAccountSoftDeleted;

  final StreamController<AuthSession> _controller = StreamController<AuthSession>.broadcast();

  final Map<String, _InMemoryUserRecord> _users = {};
  final Set<String> _pendingMagicLinks = {};
  String? lastGeneratedMagicLink;
  AuthSession _session;

  @override
  BackendTarget get target => BackendTarget.inMemory;

  @override
  AuthSession currentSession() => _session;

  @override
  Stream<AuthSession> authStateChanges() => _controller.stream;

  void _updateSession(AuthSession newSession) {
    _session = newSession;
    _controller.add(_session);
  }

  Future<void> _rejectIfSoftDeleted(String userId) async {
    final blocked = await isAccountSoftDeleted?.call(userId) ?? false;
    if (!blocked) return;
    throw AuthException(
      code: 'account-soft-deleted',
      message: AccountDeletionMessages.signInBlocked,
      userId: userId,
    );
  }

  /// Seeds an in-memory user account (useful for offline testing and deterministic harnesses).
  void seedUser({required String email, required String password, required AuthSession session}) {
    _users[email.trim().toLowerCase()] = _InMemoryUserRecord(password: password, session: session);
  }

  /// Returns true if an account with this email exists in memory.
  bool hasUser(String email) => _users.containsKey(email.trim().toLowerCase());

  void _validateEmail(String email) {
    final clean = email.trim();
    if (clean.isEmpty || !clean.contains('@') || !clean.contains('.')) {
      throw const AuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address (e.g. member@example.com).',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw const AuthException(
        code: 'weak-password',
        message: 'For your security, please choose a password with at least 6 characters.',
      );
    }
  }

  @override
  Future<AuthSession> registerWithPassword({
    required String email,
    required String password,
    required String displayName,
    String? bio,
    List<String>? comfortBadges,
    required String icocChurchAffiliation,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    final cleanEmail = email.trim().toLowerCase();
    if (_users.containsKey(cleanEmail)) {
      throw const AuthException(
        code: 'email-already-in-use',
        message:
            'An account with this email already exists. Please sign in or request a magic link.',
      );
    }

    final cleanName = displayName.trim().isEmpty ? 'Fellowship Member' : displayName.trim();
    final newSession = AuthSession(
      userId: 'user-${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-')}',
      displayName: cleanName,
      email: cleanEmail,
      bio: bio ?? 'Exploring Belong on the Spectrum',
      comfortBadges: comfortBadges ?? const ['Literal communication appreciated'],
      isSignedIn: true,
      authMethod: 'in_memory_password',
      icocChurchAffiliation: icocChurchAffiliation,
      emailVerified: false,
    );

    _users[cleanEmail] = _InMemoryUserRecord(password: password, session: newSession);

    _updateSession(newSession);
    return newSession;
  }

  @override
  Future<AuthSession> signInWithPassword({required String email, required String password}) async {
    _validateEmail(email);
    _validatePassword(password);

    final cleanEmail = email.trim().toLowerCase();
    final record = _users[cleanEmail];
    if (record == null) {
      throw const AuthException(
        code: 'user-not-found',
        message:
            'No account was found with this email. Please check your email or create an account.',
      );
    }

    if (record.password != password) {
      throw const AuthException(
        code: 'wrong-password',
        message: 'The password entered does not match our records. Please check and try again, or sign in with a magic link.',
      );
    }

    await _rejectIfSoftDeleted(record.session.userId);
    _updateSession(record.session);
    return record.session;
  }

  @override
  Future<void> sendMagicLink({required String email, String? redirectUrl}) async {
    _validateEmail(email);
    final cleanEmail = email.trim().toLowerCase();
    _pendingMagicLinks.add(cleanEmail);
    lastGeneratedMagicLink =
        'https://belong.org/auth/magic?email=$cleanEmail&token=${cleanEmail.hashCode}';
  }

  @override
  Future<AuthSession> signInWithMagicLink({
    required String email,
    required String emailLink,
  }) async {
    _validateEmail(email);
    final cleanEmail = email.trim().toLowerCase();

    if (!emailLink.contains(cleanEmail)) {
      throw const AuthException(
        code: 'invalid-action-code',
        message: 'This magic link is invalid or has already been used. Please request a new one.',
      );
    }

    // Auto-create or resume member via magic link
    final existing = _users[cleanEmail]?.session;
    final session = existing != null
        ? existing.copyWith(
            isSignedIn: true,
            authMethod: 'in_memory_magic_link',
            emailVerified: true,
          )
        : AuthSession(
            userId: 'user-magic-${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-')}',
            displayName: cleanEmail.split('@').first,
            email: cleanEmail,
            bio: 'Belong Member (Signed in via Magic Link)',
            comfortBadges: const ['Literal communication appreciated', 'Magic Link Verified'],
            isSignedIn: true,
            authMethod: 'in_memory_magic_link',
            emailVerified: true,
          );

    _users[cleanEmail] ??= _InMemoryUserRecord(password: 'magic-link-login', session: session);

    _pendingMagicLinks.remove(cleanEmail);
    await _rejectIfSoftDeleted(session.userId);
    _updateSession(session);
    return session;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    _validateEmail(email);
  }

  @override
  AuthSession signInWithEmailAndName({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
    String? icocChurchAffiliation,
  }) {
    final cleanName = displayName.trim().isEmpty ? 'Fellowship Member' : displayName.trim();
    final cleanEmail = email.trim();
    final session = AuthSession(
      userId:
          'member-${cleanEmail.isEmpty ? cleanName.toLowerCase().replaceAll(' ', '-') : cleanEmail}',
      displayName: cleanName,
      email: cleanEmail,
      bio: (bio == null || bio.trim().isEmpty) ? 'Exploring Belong on the Spectrum' : bio.trim(),
      comfortBadges: comfortBadges ?? const ['Literal communication appreciated'],
      isSignedIn: true,
      authMethod: '${target.name}_email',
      icocChurchAffiliation: icocChurchAffiliation,
    );
    _updateSession(session);
    return session;
  }

  @override
  AuthSession signInWithOAuthProvider(String provider) {
    final cleanProvider = provider.toLowerCase();
    final label = switch (cleanProvider) {
      'apple' => 'Apple',
      'facebook' => 'Facebook',
      _ => 'Google',
    };
    final session = AuthSession(
      userId: 'oauth-$cleanProvider-member',
      displayName: '$label Community Member',
      email: 'member@$cleanProvider.belongonthespectrum.com',
      bio: 'Signed in with 1-Tap $label Auth',
      comfortBadges: const ['Literal communication appreciated', '1-Tap Verified'],
      isSignedIn: true,
      authMethod: '${target.name}_$cleanProvider',
    );
    _updateSession(session);
    return session;
  }

  @override
  Future<AuthSession> signOut() async {
    final guest = const AuthSession.guest();
    _updateSession(guest);
    return guest;
  }

  @override
  Future<AuthSession> reloadCurrentUser() async {
    if (_session.isSignedIn) {
      _updateSession(_session.copyWith(emailVerified: true));
    }
    return _session;
  }

  @override
  Future<void> sendEmailVerification() async {}
}

/// Production Firebase Authentication repository with graceful offline/test fallback.
class FirebaseAuthRepository implements AuthRepository {
  static AuthSession? _savedSession;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    InMemoryAuthRepository? fallback,
    this.flavor = AppFlavor.prod,
    this.isAccountSoftDeleted,
  }) : _auth = firebaseAuth,
       _fallback = fallback ?? InMemoryAuthRepository(isAccountSoftDeleted: isAccountSoftDeleted);

  final fb_auth.FirebaseAuth? _auth;
  final InMemoryAuthRepository _fallback;
  final AppFlavor flavor;

  /// When this returns true, a successful Firebase credential is signed out.
  final Future<bool> Function(String userId)? isAccountSoftDeleted;

  Future<void> _rejectIfSoftDeleted(fb_auth.FirebaseAuth liveAuth, String userId) async {
    final blocked = await isAccountSoftDeleted?.call(userId) ?? false;
    if (!blocked) return;
    try {
      await liveAuth.signOut();
    } catch (_) {}
    throw AuthException(
      code: 'account-soft-deleted',
      message: AccountDeletionMessages.signInBlocked,
      userId: userId,
    );
  }

  fb_auth.FirebaseAuth? get auth {
    if (_auth != null) return _auth;
    try {
      return fb_auth.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Whether Firebase has been initialized with real (non-placeholder) credentials.
  bool get _hasRealCredentials {
    try {
      final key = auth?.app.options.apiKey;
      if (key == null) return false;
      if (key.contains('DummyKey') || key.contains('dummy')) return false;
      return key.length > 20;
    } catch (_) {
      return false;
    }
  }

  @override
  BackendTarget get target => BackendTarget.firebase;

  AuthSession _sessionFromFirebaseUser(fb_auth.User fbUser) {
    if (fbUser.isAnonymous) {
      return const AuthSession.guest();
    }
    return AuthSession(
      userId: fbUser.uid,
      displayName: (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
          ? fbUser.displayName!
          : (_savedSession?.displayName ?? 'Fellowship Member'),
      email: fbUser.email ?? (_savedSession?.email ?? ''),
      bio: _savedSession?.bio ?? 'Verified Member of Belong on the Spectrum',
      comfortBadges:
          _savedSession?.comfortBadges ??
          const ['Literal communication appreciated', 'Firebase Cloud Verified'],
      isSignedIn: true,
      authMethod: 'firebase_auth',
      icocChurchAffiliation: _savedSession?.icocChurchAffiliation,
      emailVerified: fbUser.emailVerified,
      photoUrl: fbUser.photoURL ?? _savedSession?.photoUrl,
    );
  }

  @override
  AuthSession currentSession() {
    if (_hasRealCredentials) {
      final fbUser = auth?.currentUser;
      if (fbUser != null) {
        return _sessionFromFirebaseUser(fbUser);
      }
    }
    if (_savedSession != null && _savedSession!.isSignedIn) {
      return _savedSession!;
    }
    return _fallback.currentSession();
  }

  @override
  Stream<AuthSession> authStateChanges() {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      return liveAuth.authStateChanges().map((fbUser) {
        if (fbUser != null) {
          final s = _sessionFromFirebaseUser(fbUser);
          _savedSession = s;
          return s;
        }
        if (_savedSession != null && _savedSession!.isSignedIn) {
          return _savedSession!;
        }
        return const AuthSession.guest();
      });
    }
    return _fallback.authStateChanges();
  }

  @override
  Future<AuthSession> registerWithPassword({
    required String email,
    required String password,
    required String displayName,
    String? bio,
    List<String>? comfortBadges,
    required String icocChurchAffiliation,
  }) async {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      try {
        final credential = await liveAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(displayName.trim());
          if (flavor.isProduction) {
            try {
              await user.sendEmailVerification();
            } catch (e) {
              talker.warning('⚠️ [FirebaseAuthRepository] sendEmailVerification failed: $e');
            }
          }
          final session = AuthSession(
            userId: user.uid,
            displayName: displayName.trim(),
            email: user.email ?? email.trim(),
            bio: bio ?? 'Verified Member of Belong on the Spectrum',
            comfortBadges: comfortBadges ?? const ['Literal communication appreciated'],
            isSignedIn: true,
            authMethod: 'firebase_password',
            icocChurchAffiliation: icocChurchAffiliation,
            emailVerified: user.emailVerified,
            photoUrl: user.photoURL,
          );
          _fallback.seedUser(email: email, password: password, session: session);
          return session;
        }
      } catch (e) {
        talker.warning('⚠️ [FirebaseAuthRepository] Firebase registration failed: $e');
        throw AuthException.fromFirebase(e);
      }
    }
    talker.info(
      '🔐 [FirebaseAuthRepository] Using resilient in-memory session (offline/test credentials)',
    );
    return _fallback.registerWithPassword(
      email: email,
      password: password,
      displayName: displayName,
      bio: bio,
      comfortBadges: comfortBadges,
      icocChurchAffiliation: icocChurchAffiliation,
    );
  }

  @override
  Future<AuthSession> signInWithPassword({required String email, required String password}) async {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      try {
        final credential = await liveAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await _rejectIfSoftDeleted(liveAuth, user.uid);
          return AuthSession(
            userId: user.uid,
            displayName: user.displayName ?? 'Fellowship Member',
            email: user.email ?? email.trim(),
            bio: 'Verified Member of Belong on the Spectrum',
            comfortBadges: const ['Literal communication appreciated'],
            isSignedIn: true,
            authMethod: 'firebase_password',
            emailVerified: user.emailVerified,
            photoUrl: user.photoURL,
          );
        }
      } catch (e) {
        talker.warning('⚠️ [FirebaseAuthRepository] Firebase sign-in failed: $e');
        throw AuthException.fromFirebase(e);
      }
    }
    talker.info(
      '🔐 [FirebaseAuthRepository] Using resilient in-memory sign-in (offline/test credentials)',
    );
    return _fallback.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> sendMagicLink({required String email, String? redirectUrl}) async {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      try {
        final actionCodeSettings = fb_auth.ActionCodeSettings(
          url: redirectUrl ?? flavor.magicLinkRedirectUrl,
          handleCodeInApp: true,
          androidPackageName: flavor.applicationId,
          androidInstallApp: true,
          androidMinimumVersion: '12',
          iOSBundleId: flavor.applicationId,
        );
        await liveAuth.sendSignInLinkToEmail(
          email: email.trim(),
          actionCodeSettings: actionCodeSettings,
        );
        return;
      } catch (e) {
        talker.warning('⚠️ [FirebaseAuthRepository] Firebase magic link failed: $e');
        throw AuthException.fromFirebase(e);
      }
    }
    talker.info('🔐 [FirebaseAuthRepository] Using resilient in-memory magic link');
    return _fallback.sendMagicLink(email: email, redirectUrl: redirectUrl);
  }

  @override
  Future<AuthSession> signInWithMagicLink({
    required String email,
    required String emailLink,
  }) async {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      try {
        final credential = await liveAuth.signInWithEmailLink(
          email: email.trim(),
          emailLink: emailLink,
        );
        final user = credential.user;
        if (user != null) {
          await _rejectIfSoftDeleted(liveAuth, user.uid);
          return AuthSession(
            userId: user.uid,
            displayName: user.displayName ?? 'Fellowship Member',
            email: user.email ?? email.trim(),
            bio: 'Verified Member of Belong on the Spectrum (Magic Link)',
            comfortBadges: const ['Literal communication appreciated', 'Magic Link Verified'],
            isSignedIn: true,
            authMethod: 'firebase_magic_link',
            emailVerified: true,
            photoUrl: user.photoURL,
          );
        }
      } catch (e) {
        talker.warning('⚠️ [FirebaseAuthRepository] Firebase magic link consumption failed: $e');
        throw AuthException.fromFirebase(e);
      }
    }
    talker.info('🔐 [FirebaseAuthRepository] Using resilient in-memory magic link consumption');
    return _fallback.signInWithMagicLink(email: email, emailLink: emailLink);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final liveAuth = auth;
    if (liveAuth != null) {
      try {
        await liveAuth.sendPasswordResetEmail(email: email.trim());
        return;
      } catch (e) {
        throw AuthException.fromFirebase(e);
      }
    }
    return _fallback.sendPasswordResetEmail(email: email);
  }

  @override
  AuthSession signInWithEmailAndName({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
    String? icocChurchAffiliation,
  }) {
    final liveAuth = auth;
    final currentUser = liveAuth?.currentUser;
    if (currentUser != null) {
      try {
        currentUser.updateDisplayName(displayName);
      } catch (_) {}
    }

    final session = _fallback.signInWithEmailAndName(
      displayName: displayName,
      email: email,
      bio: bio,
      comfortBadges: comfortBadges,
      icocChurchAffiliation: icocChurchAffiliation,
    );
    final effective = session.copyWith(
      authMethod: 'firebase_email',
      icocChurchAffiliation: icocChurchAffiliation,
    );
    _savedSession = effective;
    return effective;
  }

  @override
  AuthSession signInWithOAuthProvider(String provider) {
    final session = _fallback.signInWithOAuthProvider(provider);
    return session.copyWith(authMethod: 'firebase_$provider');
  }

  @override
  Future<AuthSession> signOut() async {
    _savedSession = null;
    try {
      await auth?.signOut();
    } catch (_) {}
    return _fallback.signOut();
  }

  @override
  Future<AuthSession> reloadCurrentUser() async {
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      final user = liveAuth.currentUser;
      if (user != null) {
        await user.reload();
        final refreshed = liveAuth.currentUser;
        if (refreshed != null) {
          final session = _sessionFromFirebaseUser(refreshed);
          _savedSession = session;
          return session;
        }
      }
    }
    return _fallback.reloadCurrentUser();
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!flavor.isProduction) return;
    final liveAuth = auth;
    if (liveAuth != null && _hasRealCredentials) {
      final user = liveAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
      return;
    }
    return _fallback.sendEmailVerification();
  }
}

class ServerpodAuthRepository extends InMemoryAuthRepository {
  ServerpodAuthRepository({super.isAccountSoftDeleted});

  @override
  BackendTarget get target => BackendTarget.serverpod;
}

class AppwriteAuthRepository extends InMemoryAuthRepository {
  AppwriteAuthRepository({super.isAccountSoftDeleted});

  @override
  BackendTarget get target => BackendTarget.appwrite;
}

/// Active [AuthRepository] adapter.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final target = ref.watch(authBackendTargetProvider);
  final flavor = ref.watch(appFlavorProvider);
  final blockSignIn = ref.watch(accountDeletionRepositoryProvider).isSignInBlocked;
  return switch (target) {
    BackendTarget.inMemory => InMemoryAuthRepository(isAccountSoftDeleted: blockSignIn),
    BackendTarget.serverpod => ServerpodAuthRepository(isAccountSoftDeleted: blockSignIn),
    BackendTarget.appwrite => AppwriteAuthRepository(isAccountSoftDeleted: blockSignIn),
    BackendTarget.firebase => FirebaseAuthRepository(
      flavor: flavor,
      isAccountSoftDeleted: blockSignIn,
    ),
  };
});

/// Reactive auth session for gates and shells that must not trust local profile cache.
final authSessionStreamProvider = StreamProvider<AuthSession>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});
