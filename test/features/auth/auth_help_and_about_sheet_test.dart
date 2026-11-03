import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_build_stamp.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/auth_help_and_about_sheet.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/belong_auth_sheet.dart';

void main() {
  group('Milestone 1.0 RC / v0.9.9 Auth Help & About Verification (#855)', () {
    Widget buildSheet({AppFlavor flavor = AppFlavor.dev}) => ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BelongAuthSheet(),
            ),
          ),
        );

    Widget buildHelpButton({
      AppFlavor flavor = AppFlavor.dev,
      Future<AppVersionLabel> Function()? loadVersion,
    }) =>
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AuthHelpAndAboutButton(
                  flavor: flavor,
                  loadVersion: loadVersion,
                ),
              ),
            ),
          ),
        );

    patrolWidgetTest('BelongAuthSheet renders Help & About button', ($) async {
      await $.pumpWidgetAndSettle(buildSheet());

      expect($(const Key('auth_help_and_about_button')), findsOneWidget);
    });

    patrolWidgetTest('Tapping Help & About button displays version badge and dev env link', ($) async {
      Future<AppVersionLabel> mockVersion() async =>
          const AppVersionLabel(version: '0.9.9', buildNumber: '9990');

      await $.pumpWidgetAndSettle(
        buildHelpButton(flavor: AppFlavor.dev, loadVersion: mockVersion),
      );

      await $(const Key('auth_help_and_about_button')).tap();
      await $.pumpAndSettle();

      // Verify title & version label
      expect($('Help & About Belong'), findsOneWidget);
      expect($('Development / Pre-Prod Environment'), findsOneWidget);
      expect($(const Key('auth_help_version_label')), findsOneWidget);
      expect($('Belong on the Spectrum (v0.9.9+9990)'), findsOneWidget);

      // Verify cross-environment switch button
      expect($(const Key('auth_help_switch_env_button')), findsOneWidget);
      expect($('Open Public Community (belongonthespectrum.web.app)'), findsOneWidget);

      // Dismiss dialog
      await $(const Key('auth_help_dialog_dismiss_button')).tap();
      await $.pumpAndSettle();
      expect($('Help & About Belong'), findsNothing);
    });

    patrolWidgetTest('Prod flavor renders Production badge and dev link', ($) async {
      Future<AppVersionLabel> mockVersion() async =>
          const AppVersionLabel(version: '0.9.9', buildNumber: '9990');

      await $.pumpWidgetAndSettle(
        buildHelpButton(flavor: AppFlavor.prod, loadVersion: mockVersion),
      );

      await $(const Key('auth_help_and_about_button')).tap();
      await $.pumpAndSettle();

      expect($('Production Environment'), findsOneWidget);
      expect($(const Key('auth_help_switch_env_button')), findsOneWidget);
      expect($('Open Development Site (dev-belongonthespectrum.web.app)'), findsOneWidget);
    });
  });
}
