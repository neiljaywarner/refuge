import 'package:flutter/material.dart';

import '../domain/circle_ban.dart';

/// Full-screen lockout for a signed-in member whose account is paused.
///
/// Reading and posting are both paused. The screen does not include a reason.
class AccountPausedLockout extends StatelessWidget {
  const AccountPausedLockout({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('account_paused_lockout'),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_outline_rounded, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            circleBanSignInMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Posts, comments, and messages from this member were removed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
