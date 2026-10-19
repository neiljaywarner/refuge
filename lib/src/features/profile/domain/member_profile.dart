import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Represents the signed-in community member's profile and Stage 1 ("Any Auth")
/// session state (#23, #26).
@immutable
class MemberProfile {
  const MemberProfile({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.comfortBadges,
    required this.isSignedIn,
  });

  const MemberProfile.guest()
    : displayName = 'Fellowship Member',
      email = '',
      bio = 'Exploring Belong on the Spectrum',
      comfortBadges = const ['Literal communication appreciated'],
      isSignedIn = false;

  final String displayName;
  final String email;
  final String bio;
  final List<String> comfortBadges;
  final bool isSignedIn;

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
  }) {
    return MemberProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      comfortBadges: comfortBadges ?? this.comfortBadges,
      isSignedIn: isSignedIn ?? this.isSignedIn,
    );
  }
}

class MemberProfileNotifier extends StateNotifier<MemberProfile> {
  MemberProfileNotifier() : super(const MemberProfile.guest());

  void signIn({
    required String displayName,
    required String email,
    String? bio,
  }) {
    state = state.copyWith(
      displayName: displayName.trim().isEmpty
          ? 'Fellowship Member'
          : displayName.trim(),
      email: email.trim(),
      bio: bio?.trim() ?? state.bio,
      isSignedIn: true,
    );
  }

  void signOut() {
    state = const MemberProfile.guest();
  }
}

final memberProfileProvider =
    StateNotifierProvider<MemberProfileNotifier, MemberProfile>(
      (ref) => MemberProfileNotifier(),
    );
