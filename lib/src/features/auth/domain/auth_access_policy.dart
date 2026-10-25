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
  });

  final String email;
  final String displayName;
  final String semanticsKey;
}

const List<DevExampleAccount> devExampleAccounts = [
  DevExampleAccount(
    email: 'exampleuser1@yopmail.com',
    displayName: 'Example User 1',
    semanticsKey: 'dev_example_user_1',
  ),
  DevExampleAccount(
    email: 'exampleuser2@yopmail.com',
    displayName: 'Example User 2',
    semanticsKey: 'dev_example_user_2',
  ),
];

const String devExamplePasswordMissingMessage =
    'Dev example sign-in needs DEV_EXAMPLE_PASSWORD';

const String devExampleChurchAffiliation =
    'I am not a member of an ICOC church';
