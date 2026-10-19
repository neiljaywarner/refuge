import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

void main() {
  group('MemberProfileDialog BDD Widget Tests (#93)', () {
    patrolWidgetTest('displays validation error if saved without selecting church affiliation', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MemberProfileDialog(),
            ),
          ),
        ),
      );

      // Verify header and required indicator
      expect($('Member Profile & Sign-In'), findsOneWidget);
      expect($('Which ICOC church do you attend?'), findsOneWidget);

      // Enter name & email
      await $(const Key('profile_display_name_field')).enterText('Test Member');
      await $(const Key('profile_email_field')).enterText('test@belong.org');

      // Attempt to save without choosing church affiliation
      await $(const Key('profile_save_sign_in_button')).tap();
      await $.pump();

      // Verify validation error banner is displayed
      expect($(const Key('profile_affiliation_error_text')), findsOneWidget);
      expect(
        $('Please select which ICOC church you attend, or choose "I am not a member of an ICOC church".'),
        findsOneWidget,
      );

      // User should still not be signed in
      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    });

    patrolWidgetTest('signs in successfully when an ICOC church is selected', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MemberProfileDialog(),
            ),
          ),
        ),
      );

      await $(const Key('profile_display_name_field')).enterText('Marty');
      await $(const Key('profile_email_field')).enterText('marty@belongonthespectrum.com');

      // Open dropdown and select 'DFW Church (Partner)'
      await $(const Key('profile_church_affiliation_dropdown')).tap();
      await $.pumpAndSettle();

      await $('DFW Church (Partner)').last.tap();
      await $.pumpAndSettle();

      // Tap save
      await $(const Key('profile_save_sign_in_button')).tap();
      await $.pumpAndSettle();

      final profile = container.read(memberProfileProvider);
      expect(profile.isSignedIn, isTrue);
      expect(profile.displayName, 'Marty');
      expect(profile.icocChurchAffiliation, 'DFW Church (Partner)');
      expect(profile.isIcocMember, isTrue);
    });

    patrolWidgetTest('signs in successfully when selecting "I am not a member of an ICOC church"', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MemberProfileDialog(),
            ),
          ),
        ),
      );

      await $(const Key('profile_display_name_field')).enterText('Jordan NonMember');
      await $(const Key('profile_email_field')).enterText('jordan@example.com');

      // Open dropdown and select non-member option
      await $(const Key('profile_church_affiliation_dropdown')).tap();
      await $.pumpAndSettle();

      await $('I am not a member of an ICOC church').last.tap();
      await $.pumpAndSettle();

      // Tap save
      await $(const Key('profile_save_sign_in_button')).tap();
      await $.pumpAndSettle();

      final profile = container.read(memberProfileProvider);
      expect(profile.isSignedIn, isTrue);
      expect(profile.displayName, 'Jordan NonMember');
      expect(profile.icocChurchAffiliation, 'I am not a member of an ICOC church');
      expect(profile.isIcocMember, isFalse);
    });
  });
}
