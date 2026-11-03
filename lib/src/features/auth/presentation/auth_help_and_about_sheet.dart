import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_flavor.dart';
import '../../about/presentation/about_build_stamp.dart';
import '../../about/presentation/about_refuge_dialog.dart';

/// Neurodivergent-affirming, accessible Help & About action and dialog for Auth screens.
///
/// Provides:
/// 1. Exact app version and semantic build number (e.g. `v0.9.9 (build 9990)`).
/// 2. Active environment detection (Pre-Prod / Dev vs Production).
/// 3. One-tap cross-environment navigation link to switch between Dev and Prod web apps.
/// 4. Direct access to comprehensive About Refuge / Sensory & Feedback dialog.
class AuthHelpAndAboutButton extends StatelessWidget {
  const AuthHelpAndAboutButton({
    super.key,
    this.flavor,
    this.loadVersion,
  });

  final AppFlavor? flavor;
  final Future<AppVersionLabel> Function()? loadVersion;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('auth_help_and_about_button'),
    tooltip: 'Need Help & About Belong',
    icon: const Icon(Icons.help_outline_rounded, size: 20),
    onPressed: () => showAuthHelpAndAboutDialog(
      context,
      flavor: flavor,
      loadVersion: loadVersion,
    ),
  );
}

/// Displays the auth-screen specific Help & About dialog with environment and version badges.
void showAuthHelpAndAboutDialog(
  BuildContext context, {
  AppFlavor? flavor,
  Future<AppVersionLabel> Function()? loadVersion,
}) {
  final activeFlavor = flavor ?? _detectRuntimeFlavor();
  final versionFuture = (loadVersion ?? loadPackageVersion)();

  showDialog<void>(
    context: context,
    builder: (ctx) => Semantics(
      namesRoute: true,
      scopesRoute: true,
      explicitChildNodes: true,
      container: true,
      label: 'Authentication Help and About',
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 22,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            const Gap(10),
            const Expanded(
              child: Text(
                'Help & About Belong',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              key: const Key('auth_help_dialog_close_button'),
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
              tooltip: 'Close',
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                // Environment & Version Badge Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            activeFlavor.isProduction
                                ? Icons.verified_rounded
                                : Icons.science_outlined,
                            size: 16,
                            color: activeFlavor.isProduction
                                ? Colors.green.shade700
                                : Colors.amber.shade800,
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              activeFlavor.isProduction
                                  ? 'Production Environment'
                                  : 'Development / Pre-Prod Environment',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: activeFlavor.isProduction
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      FutureBuilder<AppVersionLabel>(
                        future: versionFuture,
                        builder: (context, snapshot) {
                          final versionLabel = snapshot.data?.titleSuffix ?? 'v0.9.9+9990';
                          return Text(
                            'Belong on the Spectrum ($versionLabel)',
                            key: const Key('auth_help_version_label'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                      const Gap(4),
                      Text(
                        'Calm-tech Christian & neurodivergent fellowship platform.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(ctx).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),

                // Cross-Environment Switch Notice
                Text(
                  activeFlavor.isProduction
                      ? 'Looking for the latest preview features?'
                      : 'Looking for the stable production community?',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                Text(
                  activeFlavor.isProduction
                      ? 'You are currently on the stable public release. Pre-release testing and new features update continuously on the Development site.'
                      : 'You are currently on the development preview. The stable public site receives curated milestone releases.',
                  style: const TextStyle(fontSize: 11.5, height: 1.35),
                ),
                const Gap(8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('auth_help_switch_env_button'),
                    onPressed: () async {
                      final targetUrl = activeFlavor.isProduction
                          ? 'https://dev-belongonthespectrum.web.app'
                          : 'https://belongonthespectrum.web.app';
                      final uri = Uri.parse(targetUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(
                      activeFlavor.isProduction
                          ? Icons.open_in_new_rounded
                          : Icons.public_rounded,
                      size: 16,
                    ),
                    label: Text(
                      activeFlavor.isProduction
                          ? 'Open Development Site (dev-belongonthespectrum.web.app)'
                          : 'Open Public Community (belongonthespectrum.web.app)',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),

                const Gap(14),
                const Divider(),
                const Gap(8),

                // Community Guidelines & Account Assistance
                const Text(
                  'Need Account Assistance?',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                const Text(
                  '• If you forgot your password, use the "Forgot Password" link on the sign-in form.\n'
                  '• If your account was soft-deleted, sign in with your email to access the 30-day restore panel.\n'
                  '• For accessibility requests or inquiries, reach out to community organizers during worship fellowship.',
                  style: TextStyle(fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('auth_help_full_about_button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              showAboutRefugeDialog(
                context,
                primaryColor: Theme.of(context).colorScheme.primary,
                isContrast: false,
                loadVersion: loadVersion,
              );
            },
            child: const Text('Sensory & Full About', style: TextStyle(fontSize: 12)),
          ),
          FilledButton(
            key: const Key('auth_help_dialog_dismiss_button'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    ),
  );
}

AppFlavor _detectRuntimeFlavor() {
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.contains('dev-belongonthespectrum') || host.contains('localhost')) {
      return AppFlavor.dev;
    }
    if (host.contains('belongonthespectrum.web.app') || host.contains('belongonthespectrum.com')) {
      return AppFlavor.prod;
    }
  }
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  return AppFlavor.fromString(envFlavor);
}
