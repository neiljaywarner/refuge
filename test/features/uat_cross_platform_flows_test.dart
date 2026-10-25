import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

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
      expect($('Messages'), findsOneWidget);
      expect($('Search'), findsOneWidget);
    });

    patrolWidgetTest('Flow 2: Member Profile & Marty the Organizer ICOC Church Question', ($) async {
      await $.tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));
      await $.pumpWidgetAndSettle(
        createTestApp(home: const Scaffold(body: MemberProfileDialog())),
      );

      // Verify title and prompts
      expect($('Member Profile'), findsOneWidget);
      expect($('Marty the Organizer'), findsOneWidget);
      expect($('ICOC Church'), findsOneWidget);
      expect($('Faith Journey:'), findsOneWidget);
      expect($('Saved (Baptized) in 1993'), findsOneWidget);

      // Close modal
      await $(const Key('close_member_profile_sheet')).tap();
      await $.pumpAndSettle();
      expect($('Member Profile'), findsNothing);
    });

    patrolWidgetTest('Flow 3: Firebase Auth & Passwordless Magic Link Sheet', ($) async {
      await $.tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));
      await $.pumpWidgetAndSettle(
        createTestApp(home: const Scaffold(body: BelongAuthSheet())),
      );

      // Verify Auth Header
      expect($('Sign in to Belong'), findsOneWidget);
      expect($('Passwordless magic link sign-in for autistic individuals and allies.'), findsOneWidget);

      // Verify Email Field
      expect($(const Key('belong_auth_email_field')), findsOneWidget);

      // Enter email and tap Send Magic Link
      await $(const Key('belong_auth_email_field')).enterText('alex@belongonthespectrum.com');
      await $.pumpAndSettle();

      await $(const Key('belong_auth_send_link_button')).tap();
      await $.pumpAndSettle();

      // Verify Confirmation Sent State
      expect($('Magic Link Sent!'), findsOneWidget);
      expect($('We sent a secure, passwordless sign-in link to:'), findsOneWidget);
      expect($('alex@belongonthespectrum.com'), findsOneWidget);
    });

    patrolWidgetTest('Flow 4: Whitelabel Brand Dynamic Reconfiguration', ($) async {
      const customBrand = CommunityBrandConfig(
        tenantId: 'spectrum_oasis',
        shortName: 'Spectrum Oasis',
        fullName: 'Spectrum Oasis Fellowship',
        tagline: 'Quiet fellowship for autistic adults',
        scriptureAnchor: 'Psalm 23:2',
        websiteUrl: 'https://belongonthespectrum.com/oasis',
        partnerOrgName: 'Oasis Network',
        partnerOrgUrl: 'https://belongonthespectrum.com',
        logoAssetPath: 'assets/images/belong_logo.png',
        creamBackgroundColor: Color(0xFFF3EFE6),
        deepNavyPrimaryColor: Color(0xFF1B4332),
        warmGoldAccentColor: Color(0xFF52B788),
        defaultOrganizerWelcomeTitle: 'Welcome to Oasis Fellowship',
        defaultOrganizerWelcomeMessage: 'Quiet fellowship for autistic adults',
      );

      await $.pumpWidgetAndSettle(createTestApp(brand: customBrand));

      // Verify dynamic brand injection
      expect($('Spectrum Oasis'), findsOneWidget);
    });
  });
}
