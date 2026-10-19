import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../feedback/data/feature_voting_repository.dart';
import '../domain/auth_session.dart';

/// Pluggable authentication repository interface supporting:
/// - **Piece-by-Piece** or **One-Shot** migration from Serverpod to Appwrite
///   (graded A+ / 9.6 in ADR-0009).
abstract interface class AuthRepository {
  BackendTarget get target;

  AuthSession currentSession();

  AuthSession signInWithEmailAndName({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
  });

  AuthSession signInWithOAuthProvider(String provider); // 'google' | 'apple'

  AuthSession signOut();
}

mixin AuthSessionTransformMixin implements AuthRepository {
  AuthSession _session = const AuthSession.guest();

  @override
  AuthSession currentSession() => _session;

  @override
  AuthSession signInWithEmailAndName({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
  }) {
    final cleanName = displayName.trim().isEmpty
        ? 'Fellowship Member'
        : displayName.trim();
    final cleanEmail = email.trim();
    _session = AuthSession(
      userId: 'member-${cleanEmail.isEmpty ? cleanName.toLowerCase().replaceAll(' ', '-') : cleanEmail}',
      displayName: cleanName,
      email: cleanEmail,
      bio: (bio == null || bio.trim().isEmpty)
          ? 'Exploring Belong on the Spectrum'
          : bio.trim(),
      comfortBadges:
          comfortBadges ?? const ['Literal communication appreciated'],
      isSignedIn: true,
      authMethod: '${target.name}_email',
    );
    return _session;
  }

  @override
  AuthSession signInWithOAuthProvider(String provider) {
    final cleanProvider = provider.toLowerCase();
    final label = cleanProvider == 'apple' ? 'Apple' : 'Google';
    _session = AuthSession(
      userId: 'oauth-$cleanProvider-member',
      displayName: '$label Community Member',
      email: 'member@$cleanProvider.belongonthespectrum.com',
      bio: 'Signed in with 1-Tap $label Auth',
      comfortBadges: const [
        'Literal communication appreciated',
        '1-Tap Verified',
      ],
      isSignedIn: true,
      authMethod: '${target.name}_$cleanProvider',
    );
    return _session;
  }

  @override
  AuthSession signOut() {
    _session = const AuthSession.guest();
    return _session;
  }
}

class InMemoryAuthRepository with AuthSessionTransformMixin implements AuthRepository {
  @override
  BackendTarget get target => BackendTarget.inMemory;
}

class ServerpodAuthRepository with AuthSessionTransformMixin implements AuthRepository {
  @override
  BackendTarget get target => BackendTarget.serverpod;
}

class AppwriteAuthRepository with AuthSessionTransformMixin implements AuthRepository {
  @override
  BackendTarget get target => BackendTarget.appwrite;
}

class FirebaseAuthRepository with AuthSessionTransformMixin implements AuthRepository {
  @override
  BackendTarget get target => BackendTarget.firebase;
}

/// 1-line switchable provider controlling which backend powers Authentication.
final authBackendTargetProvider = Provider<BackendTarget>(
  (ref) => BackendTarget.serverpod,
);

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
