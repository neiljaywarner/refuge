import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_session.dart';

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
    this.icocChurchAffiliation,
    this.tagline,
  });

  const MemberProfile.guest()
    : displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false,
      authMethod = 'guest',
      icocChurchAffiliation = null,
      tagline = 'Exploring Belong on the Spectrum';

  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;
  final String authMethod;
  final String? icocChurchAffiliation;
  final String? tagline;

  /// Effective tagline for community display.
  String get effectiveTagline =>
      (tagline != null && tagline!.trim().isNotEmpty)
          ? tagline!
          : (bio.isNotEmpty ? bio : 'Fellowship member');

  /// Returns true if the member has confirmed affiliation with an ICOC church congregation.
  bool get isIcocMember =>
      icocChurchAffiliation != null &&
      icocChurchAffiliation!.trim().isNotEmpty &&
      icocChurchAffiliation != 'I am not a member of an ICOC church' &&
      icocChurchAffiliation != 'I am not a member of this fellowship';

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
    String? icocChurchAffiliation,
    String? tagline,
  }) {
    return MemberProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      comfortBadges: comfortBadges ?? this.comfortBadges,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      authMethod: authMethod ?? this.authMethod,
      icocChurchAffiliation:
          icocChurchAffiliation ?? this.icocChurchAffiliation,
      tagline: tagline ?? this.tagline,
    );
  }
}

class MemberProfileNotifier extends Notifier<MemberProfile> {
  StreamSubscription<AuthSession>? _sub;

  @override
  MemberProfile build() {
    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.authStateChanges().listen((session) {
      state = MemberProfile(
        displayName: session.displayName,
        email: session.email,
        bio: session.bio,
        comfortBadges: session.comfortBadges,
        isSignedIn: session.isSignedIn,
        authMethod: session.authMethod,
        icocChurchAffiliation: session.icocChurchAffiliation,
      );
    });
    ref.onDispose(() {
      _sub?.cancel();
    });

    final session = repo.currentSession();
    return MemberProfile(
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
      icocChurchAffiliation: session.icocChurchAffiliation,
    );
  }

  void signIn({
    required String displayName,
    required String email,
    String? bio,
    List<String>? comfortBadges,
    String? icocChurchAffiliation,
  }) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithEmailAndName(
      displayName: displayName,
      email: email,
      bio: bio ?? state.bio,
      comfortBadges: comfortBadges ?? state.comfortBadges,
      icocChurchAffiliation:
          icocChurchAffiliation ?? state.icocChurchAffiliation,
    );
    _applySession(session);
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.signInWithPassword(
      email: email,
      password: password,
    );
    _applySession(session);
  }

  Future<void> registerWithPassword({
    required String email,
    required String password,
    required String displayName,
    String? bio,
    List<String>? comfortBadges,
    required String icocChurchAffiliation,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.registerWithPassword(
      email: email,
      password: password,
      displayName: displayName,
      bio: bio ?? state.bio,
      comfortBadges: comfortBadges ?? state.comfortBadges,
      icocChurchAffiliation: icocChurchAffiliation,
    );
    _applySession(session);
  }

  Future<void> sendMagicLink({required String email, String? redirectUrl}) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendMagicLink(email: email, redirectUrl: redirectUrl);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithMagicLink({
    required String email,
    required String emailLink,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.signInWithMagicLink(
      email: email,
      emailLink: emailLink,
    );
    _applySession(session);
  }

  void signInWithOAuth(String provider) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithOAuthProvider(provider);
    _applySession(session);
  }

  void _applySession(AuthSession session) {
    state = MemberProfile(
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
      icocChurchAffiliation: session.icocChurchAffiliation,
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
