import 'package:flutter/foundation.dart';

import '../../../core/config/app_flavor.dart';

/// Production builds require a verified email before the main app is shown.
bool mustVerifyEmail(AppFlavor flavor) => flavor.isProduction;

/// Dev-family example accounts on the sign-in wall (Android and web only).
bool showDevExampleAccounts({
  required AppFlavor flavor,
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (flavor.isProduction) return false;
  return isWeb || platform == TargetPlatform.android;
}

/// Password for dev example accounts. Set at build time only; never commit.
const String devExamplePassword = String.fromEnvironment('DEV_EXAMPLE_PASSWORD');

class DevExampleAccount {
  const DevExampleAccount({
    required this.email,
    required this.displayName,
    required this.semanticsKey,
    required this.shortcutLabel,
    required this.bio,
    required this.icocChurchAffiliation,
    this.comfortBadges = const ['Literal communication appreciated'],
  });

  final String email;
  final String displayName;
  final String semanticsKey;

  /// Shown on the dev-only shortcut button (Android / web).
  final String shortcutLabel;
  final String bio;
  final String icocChurchAffiliation;
  final List<String> comfortBadges;
}

const String devExampleChurchAffiliation =
    'I am not a member of an ICOC church';

/// Example User 1: longtime ICOC fellowship member focused on prayer spaces.
/// Example User 2: welcoming visitor / newcomer exploring at a sensory-friendly pace.
const List<DevExampleAccount> devExampleAccounts = [
  DevExampleAccount(
    email: 'exampleuser1@yopmail.com',
    displayName: 'David M.',
    semanticsKey: 'dev_example_user_1',
    shortcutLabel: 'Tap here to use Example User 1',
    bio: 'Prayer and quiet reflection. I use the Prayer Sanctuary space most.',
    icocChurchAffiliation: 'DFW Church (Partner)',
    comfortBadges: const [
      'Literal communication appreciated',
      'Prayer requests welcome',
    ],
  ),
  DevExampleAccount(
    email: 'exampleuser2@yopmail.com',
    displayName: 'Sarah K.',
    semanticsKey: 'dev_example_user_2',
    shortcutLabel: 'Tap here to use Example User 2',
    bio:
        'New to the fellowship — appreciates clear, low-pressure conversation.',
    icocChurchAffiliation: devExampleChurchAffiliation,
    comfortBadges: const [
      'Literal communication appreciated',
      'New here',
      'Low sensory preferred',
    ],
  ),
];

const String devExamplePasswordMissingMessage =
    'Dev example sign-in needs DEV_EXAMPLE_PASSWORD';
