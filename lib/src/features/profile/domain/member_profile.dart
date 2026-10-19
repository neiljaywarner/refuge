import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/data/auth_repository.dart';

/// Represents the signed-in community member's profile and Stage 1 ("Any Auth")
/// session state (#23, #26), backed by the pluggable [AuthRepository] (#52, ADR-0009).
@immutable
class MemberProfile {
  const MemberProfile({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.comfortBadges,
    required this.isSignedIn,
    this.authMethod = 'guest',
  });

  const MemberProfile.guest()
    : displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false,
      authMethod = 'guest';

  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;
  final String authMethod;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'BM';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  MemberProfile copyWith({
    String? displayName,
    String? email,
    String? bio,
    List<String>? comfortBadges,
    bool? isSignedIn,
    String? authMethod,
  }) {
    return MemberProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      comfortBadges: comfortBadges ?? this.comfortBadges,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      authMethod: authMethod ?? this.authMethod,
    );
  }
}

class MemberProfileNotifier extends Notifier<MemberProfile> {
  @override
  MemberProfile build() {
    final repo = ref.watch(authRepositoryProvider);
    final session = repo.currentSession();
    return MemberProfile(
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
    );
  }

  void signIn({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
  }) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithEmailAndName(
      displayName: displayName,
      email: email,
      bio: bio ?? state.bio,
      comfortBadges: comfortBadges ?? state.comfortBadges,
    );
    state = MemberProfile(
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
    );
  }

  void signInWithOAuth(String provider) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithOAuthProvider(provider);
    state = MemberProfile(
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
    );
  }

  void signOut() {
    final repo = ref.read(authRepositoryProvider);
    repo.signOut();
    state = const MemberProfile.guest();
  }
}

final memberProfileProvider =
    NotifierProvider<MemberProfileNotifier, MemberProfile>(
      MemberProfileNotifier.new,
    );
