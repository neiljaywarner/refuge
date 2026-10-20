import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../feedback/data/feature_voting_repository.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_session.dart';

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
}

class _InMemoryUserRecord {
  _InMemoryUserRecord({required this.password, required this.session});

  final String password;
  AuthSession session;
}

/// In-Memory implementation of [AuthRepository] for deterministic testing.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthSession initialSession = const AuthSession.guest()})
    : _session = initialSession {
    _controller.add(_session);
  }

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
}

/// Production Firebase Authentication repository with graceful offline/test fallback.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb_auth.FirebaseAuth? firebaseAuth, InMemoryAuthRepository? fallback})
    : _auth = firebaseAuth,
      _fallback = fallback ?? InMemoryAuthRepository();

  final fb_auth.FirebaseAuth? _auth;
  final InMemoryAuthRepository _fallback;

  fb_auth.FirebaseAuth? get auth {
    if (_auth != null) return _auth;
    try {
      return fb_auth.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  BackendTarget get target => BackendTarget.firebase;

  @override
  AuthSession currentSession() {
    final fbUser = auth?.currentUser;
    if (fbUser != null) {
      return AuthSession(
        userId: fbUser.uid,
        displayName: fbUser.displayName ?? 'Fellowship Member',
        email: fbUser.email ?? '',
        bio: 'Verified Member of Belong on the Spectrum',
        comfortBadges: const ['Literal communication appreciated', 'Firebase Cloud Verified'],
        isSignedIn: true,
        authMethod: 'firebase_auth',
        emailVerified: fbUser.emailVerified,
        photoUrl: fbUser.photoURL,
      );
    }
    return _fallback.currentSession();
  }

  @override
  Stream<AuthSession> authStateChanges() {
    final liveAuth = auth;
    if (liveAuth != null) {
      return liveAuth.authStateChanges().map((fbUser) {
        if (fbUser != null) {
          return AuthSession(
            userId: fbUser.uid,
            displayName: fbUser.displayName ?? 'Fellowship Member',
            email: fbUser.email ?? '',
            bio: 'Verified Member of Belong on the Spectrum',
            comfortBadges: const ['Literal communication appreciated', 'Firebase Cloud Verified'],
            isSignedIn: true,
            authMethod: 'firebase_auth',
            emailVerified: fbUser.emailVerified,
            photoUrl: fbUser.photoURL,
          );
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
    if (liveAuth != null) {
      try {
        final credential = await liveAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(displayName.trim());
          return AuthSession(
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
        }
      } catch (e) {
        throw AuthException.fromFirebase(e);
      }
    }
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
    if (liveAuth != null) {
      try {
        final credential = await liveAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = credential.user;
        if (user != null) {
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
        throw AuthException.fromFirebase(e);
      }
    }
    return _fallback.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> sendMagicLink({required String email, String? redirectUrl}) async {
    final liveAuth = auth;
    if (liveAuth != null) {
      try {
        final actionCodeSettings = fb_auth.ActionCodeSettings(
          url: redirectUrl ?? 'https://belongonthespectrum.web.app/auth',
          handleCodeInApp: true,
          androidPackageName: 'com.belongonthespectrum.refuge',
          androidInstallApp: true,
          androidMinimumVersion: '12',
          iOSBundleId: 'com.belongonthespectrum.refuge',
        );
        await liveAuth.sendSignInLinkToEmail(
          email: email.trim(),
          actionCodeSettings: actionCodeSettings,
        );
        return;
      } catch (e) {
        throw AuthException.fromFirebase(e);
      }
    }
    return _fallback.sendMagicLink(email: email, redirectUrl: redirectUrl);
  }

  @override
  Future<AuthSession> signInWithMagicLink({
    required String email,
    required String emailLink,
  }) async {
    final liveAuth = auth;
    if (liveAuth != null) {
      try {
        final credential = await liveAuth.signInWithEmailLink(
          email: email.trim(),
          emailLink: emailLink,
        );
        final user = credential.user;
        if (user != null) {
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
        throw AuthException.fromFirebase(e);
      }
    }
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
    final session = _fallback.signInWithEmailAndName(
      displayName: displayName,
      email: email,
      bio: bio,
      comfortBadges: comfortBadges,
      icocChurchAffiliation: icocChurchAffiliation,
    );
    return session.copyWith(authMethod: 'firebase_email');
  }

  @override
  AuthSession signInWithOAuthProvider(String provider) {
    final session = _fallback.signInWithOAuthProvider(provider);
    return session.copyWith(authMethod: 'firebase_$provider');
  }

  @override
  Future<AuthSession> signOut() async {
    try {
      await auth?.signOut();
    } catch (_) {}
    return _fallback.signOut();
  }
}

class ServerpodAuthRepository extends InMemoryAuthRepository {
  @override
  BackendTarget get target => BackendTarget.serverpod;
}

class AppwriteAuthRepository extends InMemoryAuthRepository {
  @override
  BackendTarget get target => BackendTarget.appwrite;
}

/// 1-line switchable provider controlling which backend powers Authentication.
/// Defaults to [BackendTarget.firebase] for solid cloud auth.
final authBackendTargetProvider = Provider<BackendTarget>((ref) => BackendTarget.firebase);

/// Active [AuthRepository] adapter.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final target = ref.watch(authBackendTargetProvider);
  return switch (target) {
    BackendTarget.inMemory => InMemoryAuthRepository(),
    BackendTarget.serverpod => ServerpodAuthRepository(),
    BackendTarget.appwrite => AppwriteAuthRepository(),
    BackendTarget.firebase => FirebaseAuthRepository(),
  };
});
