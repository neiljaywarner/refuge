import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

void main() {
  group('Member Profile Persistence & Church Dropdown Tests (#448)', () {
    setUp(() {
      ProfileStorageService.instance.clear();
    });

    tearDown(() {
      ProfileStorageService.instance.clear();
    });

    patrolWidgetTest(
      'Preferred display name and ICOC church selection persist across notifier reloads and app restarts',
      ($) async {
        final container1 = ProviderContainer(
          overrides: [
            authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          ],
        );
        addTearDown(container1.dispose);

        // 1. Initial guest state
        expect(container1.read(memberProfileProvider).isSignedIn, isFalse);

        // 2. Sign in with custom display name and church affiliation
        container1
            .read(memberProfileProvider.notifier)
            .signIn(
              displayName: 'Caleb Pioneer',
              email: 'caleb@belongonthespectrum.com',
              bio: 'Walking in unhurried peace',
              icocChurchAffiliation: 'Austin Christian Church',
            );

        final profile1 = container1.read(memberProfileProvider);
        expect(profile1.isSignedIn, isTrue);
        expect(profile1.displayName, equals('Caleb Pioneer'));
        expect(
          profile1.icocChurchAffiliation,
          equals('Austin Christian Church'),
        );

        // 3. Verify local persistent storage saved the metadata
        final saved = ProfileStorageService.instance.load();
        expect(saved, isNotNull);
        expect(saved!['displayName'], equals('Caleb Pioneer'));
        expect(
          saved['icocChurchAffiliation'],
          equals('Austin Christian Church'),
        );

        // 4. Simulate a fresh app cold-start / browser page refresh
        final container2 = ProviderContainer(
          overrides: [
            authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          ],
        );
        addTearDown(container2.dispose);

        final restored = container2.read(memberProfileProvider);
        expect(restored.isSignedIn, isTrue);
        expect(restored.displayName, equals('Caleb Pioneer'));
        expect(
          restored.icocChurchAffiliation,
          equals('Austin Christian Church'),
        );
        expect(restored.isIcocMember, isTrue);
      },
    );

    patrolWidgetTest(
      'MemberProfileDialog selects ICOC church via dropdown and saves persisted session',
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
              home: Scaffold(body: MemberProfileDialog()),
            ),
          ),
        );

        // Enter display name and email
        await $(const Key('profile_display_name_field'))
            .enterText('Sarah Rest');
        await $(const Key('profile_email_field'))
            .enterText('sarah@belongonthespectrum.com');

        // Tap dropdown and select Boston Church of Christ
        await $(const Key('profile_church_affiliation_dropdown')).tap();
        await $.pumpAndSettle();

        await $('Boston Church of Christ').last.tap();
        await $.pumpAndSettle();

        // Tap Save & Sign In
        await $(const Key('profile_save_sign_in_button')).tap();
        await $.pumpAndSettle();

        final profile = container.read(memberProfileProvider);
        expect(profile.isSignedIn, isTrue);
        expect(profile.displayName, equals('Sarah Rest'));
        expect(
          profile.icocChurchAffiliation,
          equals('Boston Church of Christ'),
        );

        // Verify storage
        final saved = ProfileStorageService.instance.load();
        expect(saved!['displayName'], equals('Sarah Rest'));
        expect(
          saved['icocChurchAffiliation'],
          equals('Boston Church of Christ'),
        );
      },
    );

    patrolWidgetTest('Signing out clears persisted profile storage cleanly', (
      $,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(memberProfileProvider.notifier)
          .signIn(
            displayName: 'Grace',
            email: 'grace@belong.com',
            icocChurchAffiliation: 'DFW Church (Partner)',
          );

      expect(ProfileStorageService.instance.load(), isNotNull);

      // Sign out
      container.read(memberProfileProvider.notifier).signOut();

      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
      expect(ProfileStorageService.instance.load(), isNull);
    });
  });
}
