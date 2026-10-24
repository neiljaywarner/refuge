import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

void main() {
  group('Profile Persistence & Church Dropdown (#448)', () {
    patrolWidgetTest(
      'MemberProfileDialog displays dropdown trigger and selects church affiliation without ActionChip clutter',
      ($) async {
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

        // Verify dropdown trigger exists
        expect($(const Key('profile_church_affiliation_dropdown')), findsOneWidget);
        expect($(const Key('profile_church_dropdown_trigger_button')), findsOneWidget);

        // Open dropdown via trigger button
        await $(const Key('profile_church_dropdown_trigger_button')).tap();
        await $.pumpAndSettle();

        // Select 'Austin Christian Church'
        await $('Austin Christian Church').last.tap();
        await $.pumpAndSettle();

        // Enter display name
        await $(const Key('profile_display_name_field')).enterText('Test Disciple');
        await $.pumpAndSettle();

        // Save
        await $(const Key('profile_save_sign_in_button')).tap();
        await $.pumpAndSettle();

        final profile = container.read(memberProfileProvider);
        expect(profile.isSignedIn, isTrue);
        expect(profile.displayName, 'Test Disciple');
        expect(profile.icocChurchAffiliation, 'Austin Christian Church');
        expect(profile.isIcocMember, isTrue);
      },
    );

    patrolWidgetTest(
      'Preferred display name and church affiliation persist across notifier re-instantiation (#448)',
      ($) async {
        final repo = InMemoryAuthRepository();
        final container1 = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
        );

        // 1. Initial sign in
        container1.read(memberProfileProvider.notifier).signIn(
          displayName: 'Hannah S.',
          email: 'hannah@example.com',
          icocChurchAffiliation: 'DFW Church (Partner)',
        );

        final profile1 = container1.read(memberProfileProvider);
        expect(profile1.isSignedIn, isTrue);
        expect(profile1.displayName, 'Hannah S.');
        expect(profile1.icocChurchAffiliation, 'DFW Church (Partner)');

        container1.dispose();

        // 2. Re-instantiate container simulating page refresh / app relaunch
        final container2 = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container2.dispose);

        final profile2 = container2.read(memberProfileProvider);
        expect(profile2.isSignedIn, isTrue);
        expect(profile2.displayName, 'Hannah S.');
        expect(profile2.icocChurchAffiliation, 'DFW Church (Partner)');

        // 3. Signing out clears persisted state
        container2.read(memberProfileProvider.notifier).signOut();
        final profile3 = container2.read(memberProfileProvider);
        expect(profile3.isSignedIn, isFalse);
        expect(profile3.displayName, 'Fellowship Member');
        expect(profile3.icocChurchAffiliation, isNull);
      },
    );
  });
}
