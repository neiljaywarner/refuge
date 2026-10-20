import 'package:flutter/foundation.dart';

/// Represents an authenticated or guest session in **Belong on the Spectrum**
/// powered by Firebase Authentication and pluggable offline/test seams.
@immutable
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.comfortBadges,
    required this.isSignedIn,
    required this.authMethod,
    this.icocChurchAffiliation,
    this.emailVerified = false,
    this.photoUrl,
  });

  const AuthSession.guest()
      : userId = 'guest',
        displayName = 'Fellowship Member',
        email = '',
        bio = 'Exploring Belong on the Spectrum',
        comfortBadges = const ['Literal communication appreciated'],
        isSignedIn = false,
        authMethod = 'guest',
        icocChurchAffiliation = null,
        emailVerified = false,
        photoUrl = null;

  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;
  final String authMethod; // 'guest', 'firebase_password', 'firebase_magic_link', 'in_memory_password', 'in_memory_magic_link'
  final String? icocChurchAffiliation;
  final bool emailVerified;
  final String? photoUrl;

  /// Returns true if this session is an unauthenticated guest.
  bool get isGuest => !isSignedIn;

  /// Returns true if this member has explicitly affiliated with an ICOC church congregation.
  bool get isIcocMember =>
      icocChurchAffiliation != null &&
      icocChurchAffiliation!.trim().isNotEmpty &&
      icocChurchAffiliation != 'I am not a member of an ICOC church' &&
      icocChurchAffiliation != 'I am not a member of this fellowship';

  AuthSession copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? bio,
    List<String>? comfortBadges,
    bool? isSignedIn,
    String? authMethod,
    String? icocChurchAffiliation,
    bool? emailVerified,
    String? photoUrl,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      comfortBadges: comfortBadges ?? this.comfortBadges,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      authMethod: authMethod ?? this.authMethod,
      icocChurchAffiliation:
          icocChurchAffiliation ?? this.icocChurchAffiliation,
      emailVerified: emailVerified ?? this.emailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
