import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/belong_auth_sheet.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/branding/presentation/brand_config_provider.dart';

void main() {
  group('BelongAuthSheet Widget & BDD Tests (#119)', () {
    Widget buildTestWidget({CommunityBrandConfig? brandConfig}) {
      return ProviderScope(
        overrides: [
          if (brandConfig != null)
            communityBrandConfigProvider.overrideWithValue(brandConfig),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BelongAuthSheet(),
          ),
        ),
      );
    }

    patrolWidgetTest('renders all three tabs (Sign In, Register, Magic Link)', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      expect($(const Key('auth_tab_sign_in')), findsOneWidget);
      expect($(const Key('auth_tab_register')), findsOneWidget);
      expect($(const Key('auth_tab_magic_link')), findsOneWidget);
      expect($(const Key('auth_sign_in_email_field')), findsOneWidget);
      expect($(const Key('auth_sign_in_password_field')), findsOneWidget);
      expect($(const Key('auth_sign_in_submit_button')), findsOneWidget);
    });

    patrolWidgetTest('shows error banner when signing in with empty fields', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      await $(const Key('auth_sign_in_submit_button')).tap();
      await $.pump();

      expect($(const Key('auth_error_banner')), findsOneWidget);
      expect($(const Key('auth_error_text')), findsOneWidget);
      expect(
        $('Please enter your email address.'),
        findsOneWidget,
      );
    });

    patrolWidgetTest('requires ICOC church affiliation selection on registration', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      // Switch to Register tab
      await $(const Key('auth_tab_register')).tap();
      await $.pumpAndSettle();

      expect($(const Key('auth_register_display_name_field')), findsOneWidget);
      expect($(const Key('auth_register_email_field')), findsOneWidget);
      expect($(const Key('auth_register_password_field')), findsOneWidget);
      expect($(const Key('auth_register_church_affiliation_dropdown')), findsOneWidget);

      // Fill in fields without selecting church affiliation
      await $(const Key('auth_register_display_name_field')).enterText('Joy Disciple');
      await $(const Key('auth_register_email_field')).enterText('joy@belong.org');
      await $(const Key('auth_register_password_field')).enterText('belongPass123');

      await $(const Key('auth_register_submit_button')).tap();
      await $.pump();

      expect($(const Key('auth_error_banner')), findsOneWidget);
      expect($(const Key('auth_error_text')), findsOneWidget);
      expect(
        $('Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".'),
        findsOneWidget,
      );
    });

    patrolWidgetTest('sends magic link and displays calm success banner', ($) async {
      await $.pumpWidgetAndSettle(buildTestWidget());

      // Switch to Magic Link tab
      await $(const Key('auth_tab_magic_link')).tap();
      await $.pumpAndSettle();

      expect($(const Key('auth_magic_link_email_field')), findsOneWidget);
      expect($(const Key('auth_send_magic_link_button')), findsOneWidget);

      await $(const Key('auth_magic_link_email_field')).enterText('magic@belong.org');
      await $(const Key('auth_send_magic_link_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('auth_success_banner')), findsOneWidget);
      expect($(const Key('auth_success_text')), findsOneWidget);
      expect(
        $('A secure sign-in link has been sent to magic@belong.org. Please check your inbox or paste the link below.'),
        findsOneWidget,
      );
    });
  });
}
