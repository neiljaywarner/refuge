import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../data/member_directory_store.dart';

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
    this.userId = '',
    this.authMethod = 'guest',
    this.icocChurchAffiliation,
    this.tagline,
    this.avatarUrl,
  });

  const MemberProfile.guest()
    : userId = '',
      displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false,
      authMethod = 'guest',
      icocChurchAffiliation = null,
      tagline = 'Exploring Belong on the Spectrum',
      avatarUrl = null;

  /// Firebase uid when signed in. Empty for guests. Never an email address.
  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;
  final String authMethod;
  final String? icocChurchAffiliation;
  final String? tagline;
  final String? avatarUrl;

  /// Effective tagline for community display.
  String get effectiveTagline => (tagline != null && tagline!.trim().isNotEmpty)
      ? tagline!
      : (bio.isNotEmpty ? bio : 'Fellowship member');

  /// Returns true if the member has confirmed affiliation with an ICOC church congregation.
  bool get isIcocMember =>
      icocChurchAffiliation != null &&
      icocChurchAffiliation!.trim().isNotEmpty &&
      icocChurchAffiliation != 'I am not a member of an ICOC church' &&
      icocChurchAffiliation != 'I am not a member of this fellowship';

  /// Extracts a 1- or 2-letter uppercase monogram initial string for avatars.
  ///
  /// Examples:
  /// - "Marty Organizer" -> "MO"
  /// - "Neil" -> "N"
  /// - "Dr. Grace Hopper" -> "GH"
  /// - "" or whitespace -> "B" (Default monogram for a "Belong" community member)
  String get initials {
    final cleaned = displayName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), ''))
        .where((p) => p.isNotEmpty)
        .where((p) => !isHonorificToken(p))
        .toList();
    return switch (parts) {
      [] => 'B', // Default 'B' monogram for Belong fellowship members
      [final single] => single[0].toUpperCase(),
      [final first, ..., final last] => '${first[0]}${last[0]}'.toUpperCase(),
    };
  }

  /// Skips title tokens like `Dr.` when forming fellowship monograms.
  static bool isHonorificToken(String token) => RegExp(
    r'^(dr|mr|mrs|ms|miss|prof)\.?$',
    caseSensitive: false,
  ).hasMatch(token);

  MemberProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? bio,
    List<String>? comfortBadges,
    bool? isSignedIn,
    String? authMethod,
    String? icocChurchAffiliation,
    String? tagline,
    String? avatarUrl,
  }) {
    return MemberProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      comfortBadges: comfortBadges ?? this.comfortBadges,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      authMethod: authMethod ?? this.authMethod,
      icocChurchAffiliation:
          icocChurchAffiliation ?? this.icocChurchAffiliation,
      tagline: tagline ?? this.tagline,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class MemberProfileNotifier extends Notifier<MemberProfile> {
  StreamSubscription<AuthSession>? _sub;
  int _applyGeneration = 0;
  Future<void>? _publishFlight;

  MemberProfile _profileFrom(AuthSession session) {
    return MemberProfile(
      userId: session.userId,
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
      icocChurchAffiliation: session.icocChurchAffiliation,
    );
  }

  bool _shouldPublish(MemberProfile profile) =>
      profile.isSignedIn &&
      profile.userId.isNotEmpty &&
      profile.userId != 'guest';

  /// Applies [session] immediately, then publishes the public directory entry.
  ///
  /// The profile update stays synchronous up to the first await so in-memory
  /// sign-in tests observe it before this method yields. The Firestore write
  /// continues even if the member signs out, because the picker reads that
  /// document from the other account.
  Future<void> _applySession(AuthSession session) async {
    final ticket = ++_applyGeneration;
    final profile = _profileFrom(session);
    try {
      state = profile;
    } catch (_) {
      return;
    }
    if (!_shouldPublish(profile)) return;
    final flight = ref
        .read(memberDirectoryStoreProvider)
        .publishSignedInMember(
          uid: profile.userId,
          displayName: profile.displayName,
          email: profile.email,
          tagline: profile.effectiveTagline,
        )
        .timeout(const Duration(seconds: 8));
    _publishFlight = flight;
    try {
      await flight;
    } catch (_) {}
    if (identical(_publishFlight, flight)) _publishFlight = null;
    if (ticket != _applyGeneration) return;
  }

  @override
  MemberProfile build() {
    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.authStateChanges().listen((session) {
      unawaited(_applySession(session));
    });
    ref.onDispose(() {
      _sub?.cancel();
    });

    return _profileFrom(repo.currentSession());
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
    unawaited(_applySession(session));
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
    await _applySession(session);
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
    await _applySession(session);
  }

  Future<void> sendMagicLink({
    required String email,
    String? redirectUrl,
  }) async {
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
    await _applySession(session);
  }

  void signInWithOAuth(String provider) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithOAuthProvider(provider);
    unawaited(_applySession(session));
  }

  void setAvatarUrl(String? url) {
    state = state.copyWith(avatarUrl: url);
  }

  Future<void> signOut() async {
    final pending = _publishFlight;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    final repo = ref.read(authRepositoryProvider);
    unawaited(repo.signOut());
    _applyGeneration++;
    state = const MemberProfile.guest();
  }
}

final memberProfileProvider =
    NotifierProvider<MemberProfileNotifier, MemberProfile>(
      MemberProfileNotifier.new,
    );
