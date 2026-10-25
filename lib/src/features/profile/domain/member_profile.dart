import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../data/member_directory_store.dart';
import '../data/profile_storage_service.dart';

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
    : displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false,
      userId = 'guest',
      authMethod = 'guest',
      icocChurchAffiliation = null,
      tagline = 'Exploring Belong on the Spectrum',
      avatarUrl = null;

  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;

  /// Auth session id. Empty until a session is applied. Guests use `guest`.
  final String userId;
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
  static MemberProfile? _persistedProfile;
  Future<void>? _publishFlight;

  /// Set while [signOut] is draining auth events that were already queued.
  ///
  /// Those events arrive on a later microtask. Leaving the latch set after
  /// sign-out returns drops the next Firebase UI sign-in, so it is cleared
  /// once the auth backend has signed out.
  bool _explicitlySignedOut = false;

  MemberProfile _profileFor(AuthSession session) {
    final persisted = _persistedProfile;
    return MemberProfile(
      userId: session.userId,
      displayName:
          session.displayName.isNotEmpty &&
              session.displayName != 'Fellowship Member'
          ? session.displayName
          : (persisted?.displayName ?? session.displayName),
      email: session.email.isNotEmpty
          ? session.email
          : (persisted?.email ?? session.email),
      bio: session.bio.isNotEmpty
          ? session.bio
          : (persisted?.bio ?? session.bio),
      comfortBadges: session.comfortBadges.isNotEmpty
          ? session.comfortBadges
          : (persisted?.comfortBadges ?? session.comfortBadges),
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
      icocChurchAffiliation:
          session.icocChurchAffiliation ?? persisted?.icocChurchAffiliation,
      avatarUrl: session.photoUrl ?? persisted?.avatarUrl,
    );
  }

  void _publishDirectory(MemberProfile profile) {
    if (!profile.isSignedIn ||
        profile.userId.isEmpty ||
        profile.userId == 'guest') {
      return;
    }
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
    unawaited(
      flight.then(
        (_) {
          if (identical(_publishFlight, flight)) _publishFlight = null;
        },
        onError: (_, _) {
          if (identical(_publishFlight, flight)) _publishFlight = null;
        },
      ),
    );
  }

  @override
  MemberProfile build() {
    // Reconcile with storage on every build so a cleared session file does
    // not leave a stale in-memory profile looking signed in.
    final local = ProfileStorageService.instance.load();
    if (local != null && local['displayName'] != null) {
      _persistedProfile = MemberProfile(
        displayName: local['displayName'] as String? ?? 'Fellowship Member',
        email: local['email'] as String? ?? '',
        bio: local['bio'] as String? ?? '',
        comfortBadges:
            (local['comfortBadges'] as List<dynamic>?)?.cast<String>() ??
            const ['Literal communication appreciated'],
        isSignedIn: true,
        authMethod: 'persisted_storage',
        icocChurchAffiliation: local['icocChurchAffiliation'] as String?,
        userId: local['userId'] as String? ?? _persistedProfile?.userId ?? '',
        avatarUrl: _persistedProfile?.avatarUrl,
        tagline: _persistedProfile?.tagline,
      );
    } else {
      _persistedProfile = null;
    }

    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.authStateChanges().listen((session) {
      if (_explicitlySignedOut) {
        _persistedProfile = null;
        state = const MemberProfile.guest();
        return;
      }
      if (session.isSignedIn) {
        state = _profileFor(session);
        _persistedProfile = state;
        _publishDirectory(state);
      } else if (_persistedProfile != null && _persistedProfile!.isSignedIn) {
        state = _persistedProfile!;
      } else {
        state = const MemberProfile.guest();
      }
    });
    ref.onDispose(() {
      _sub?.cancel();
    });

    final session = repo.currentSession();
    if (session.isSignedIn) {
      final effective = _profileFor(session);
      _persistedProfile = effective;
      return effective;
    }

    if (_persistedProfile != null && _persistedProfile!.isSignedIn) {
      return _persistedProfile!;
    }
    return const MemberProfile.guest();
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
    _applySession(session);
  }

  void signInWithOAuth(String provider) {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.signInWithOAuthProvider(provider);
    _applySession(session);
  }

  void _applySession(AuthSession session) {
    if (session.isSignedIn) {
      _explicitlySignedOut = false;
    }
    state = MemberProfile(
      userId: session.userId,
      displayName: session.displayName,
      email: session.email,
      bio: session.bio,
      comfortBadges: session.comfortBadges,
      isSignedIn: session.isSignedIn,
      authMethod: session.authMethod,
      icocChurchAffiliation: session.icocChurchAffiliation,
      avatarUrl: session.photoUrl,
    );
    if (session.isSignedIn) {
      _persistedProfile = state;
      ProfileStorageService.instance.save(
        displayName: state.displayName,
        email: state.email,
        userId: state.userId,
        bio: state.bio,
        icocChurchAffiliation: state.icocChurchAffiliation,
        comfortBadges: state.comfortBadges,
      );
      _publishDirectory(state);
    } else {
      _persistedProfile = null;
      ProfileStorageService.instance.clear();
    }
  }

  void setAvatarUrl(String? url) {
    state = state.copyWith(avatarUrl: url);
    _persistedProfile = state;
  }

  Future<void> signOut() async {
    // Guest state is applied before the first await so callers that do not
    // wait still observe a signed-out profile. Auth sign-out runs before
    // directory publish so a new sign-in is not undone by this method.
    _explicitlySignedOut = true;
    final pending = _publishFlight;
    _persistedProfile = null;
    ProfileStorageService.instance.clear();
    state = const MemberProfile.guest();

    await ref.read(authRepositoryProvider).signOut();
    if (!_explicitlySignedOut) return;

    // Broadcast auth events are delivered one per microtask, and the next
    // event is scheduled only after the previous one is delivered. Drain the
    // queue that already existed when sign-out started before accepting a
    // later sign-in.
    for (var i = 0; i < 8; i++) {
      await Future<void>.microtask(() {});
      if (!_explicitlySignedOut) return;
    }
    _explicitlySignedOut = false;

    final session = ref.read(authRepositoryProvider).currentSession();
    if (session.isSignedIn) {
      _applySession(session);
    } else {
      _persistedProfile = null;
      ProfileStorageService.instance.clear();
      state = const MemberProfile.guest();
    }

    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
  }
}

final memberProfileProvider =
    NotifierProvider<MemberProfileNotifier, MemberProfile>(
      MemberProfileNotifier.new,
    );

/// Alias provider for backwards compatibility and clean semantic naming.
final currentUserProfileProvider = memberProfileProvider;
