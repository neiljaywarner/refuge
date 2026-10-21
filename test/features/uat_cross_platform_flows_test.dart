import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/belong_auth_sheet.dart';

void main() {
  group('Comprehensive UAT Cross-Platform Flow Verification (Patrol BDD)', () {
    Widget createTestApp({
      Widget? home,
      CommunityBrandConfig? brand,
    }) {
      return ProviderScope(
        overrides: [
          if (brand != null)
            communityBrandConfigProvider.overrideWithValue(brand),
        ],
        child: MaterialApp(
          home: home ?? RefugeApp(repository: LocalPostRepository()),
        ),
      );
    }

    patrolWidgetTest('Flow 1: Sensory Calm Audit & Navigation Bar', ($) async {
      await $.pumpWidgetAndSettle(createTestApp());

      // Verify Calm Header
      expect($('Refuge'), findsOneWidget);
      expect($(find.textContaining('Calm Tech')), findsWidgets);

      // Verify Tab navigation
      expect($('Feed'), findsOneWidget);
      expect($('Spaces'), findsOneWidget);
      expect($('Vote & Feedback'), findsOneWidget);

      // Verify bottom navigation bar items
      expect($('Home'), findsOneWidget);
      expect($('Notifications'), findsOneWidget);
      expect($('Msgs'), findsOneWidget);
      expect($('Search'), findsOneWidget);
    });

    patrolWidgetTest('Flow 2: Member Profile & Marty the Organizer ICOC Church Question', ($) async {
      await $.pumpWidgetAndSettle(
        createTestApp(home: const Scaffold(body: MemberProfileDialog())),
      );

      // Verify title and prompts
      expect($('Member Profile & Sign-In'), findsOneWidget);
      expect($('Which ICOC church do you attend?'), findsOneWidget);
      expect($('Required: Confirms whether you are part of our church fellowship or a welcoming visitor.'), findsOneWidget);

      // Verify validation: tapping Save without selecting affiliation shows banner
      await $(const Key('profile_save_sign_in_button')).tap();
      await $.pump();

      expect($(const Key('profile_validation_error_banner')), findsOneWidget);
      expect($(const Key('profile_affiliation_error_text')), findsOneWidget);
      expect(
        $('Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".'),
        findsOneWidget,
      );

      // Select Non-Member Option
      await $(const Key('profile_church_affiliation_dropdown')).tap();
      await $.pumpAndSettle();

      await $('I am not a member of an ICOC church').tap();
      await $.pumpAndSettle();

      // Enter name and save
      await $(const Key('profile_display_name_field')).enterText('Caleb Visitor');
      await $(const Key('profile_save_sign_in_button')).tap();
      await $.pumpAndSettle();
    });

    patrolWidgetTest('Flow 3: Firebase Auth & Passwordless Magic Link Sheet', ($) async {
      await $.pumpWidgetAndSettle(
        createTestApp(home: const Scaffold(body: BelongAuthSheet())),
      );

      // Verify 3 tabs
      expect($(const Key('auth_tab_sign_in')), findsOneWidget);
      expect($(const Key('auth_tab_register')), findsOneWidget);
      expect($(const Key('auth_tab_magic_link')), findsOneWidget);

      // Sign In validation
      await $(const Key('auth_sign_in_submit_button')).tap();
      await $.pump();
      expect($(const Key('auth_error_banner')), findsOneWidget);
      expect($('Please enter your email address.'), findsOneWidget);

      // Register Tab
      await $(const Key('auth_tab_register')).tap();
      await $.pumpAndSettle();

      expect($(const Key('auth_register_display_name_field')), findsOneWidget);
      expect($(const Key('auth_register_email_field')), findsOneWidget);
      expect($(const Key('auth_register_password_field')), findsOneWidget);
      expect($(const Key('auth_register_church_affiliation_dropdown')), findsOneWidget);

      // Magic Link Tab
      await $(const Key('auth_tab_magic_link')).tap();
      await $.pumpAndSettle();

      await $(const Key('auth_magic_link_email_field')).enterText('fellowship@belong.org');
      await $(const Key('auth_send_magic_link_button')).tap();
      await $.pumpAndSettle();

      expect($(const Key('auth_success_banner')), findsOneWidget);
      expect($(const Key('auth_success_text')), findsOneWidget);
    });

    patrolWidgetTest('Flow 4: Feature Voting & Community Voice Sheet', ($) async {
      await $.pumpWidgetAndSettle(
        createTestApp(
          home: const Scaffold(body: BelongFeedbackAndVotingSheet()),
        ),
      );

      expect($('Belong Roadmap & Feedback'), findsOneWidget);
      expect($(const Key('tab_feature_voting')), findsOneWidget);
      expect($(const Key('tab_private_feedback')), findsOneWidget);

      // Switch to Share Feedback tab
      await $(const Key('tab_private_feedback')).tap();
      await $.pumpAndSettle();

      expect($('Works Great'), findsOneWidget);
      expect($('Idea / Tweak'), findsOneWidget);
      expect($('Bug / Confusing'), findsOneWidget);
    });
  });
}
