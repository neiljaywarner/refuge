import 'package:flutter/foundation.dart';

/// Represents an authenticated or guest session in **Belong on the Spectrum**
/// for Stage 1 ("Any Auth", `v0.8.0-alpha`) and Stage 2 (Appwrite OAuth2, `v0.9.0-beta`).
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
  });

  const AuthSession.guest()
    : userId = 'guest',
      displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false,
      authMethod = 'guest';

  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;
  final String authMethod; // 'guest', 'stage1_email', 'appwrite_google', 'appwrite_apple'
}
