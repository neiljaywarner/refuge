import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';

void main() {
  group('Stage 1 Any Auth & Pluggable AuthRepository Adapter Tests (#26, ADR-0009)', () {
    setUp(() {
      ProfileStorageService.instance.clear();
    });

    tearDown(() {
      ProfileStorageService.instance.clear();
    });

    test('signs in with email/name, OAuth, and signs out cleanly on InMemory backend', () async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(memberProfileProvider).isSignedIn, isFalse);

      container
          .read(memberProfileProvider.notifier)
          .signIn(
            displayName: 'Hannah Grace',
            email: 'hannah@belongonthespectrum.com',
            bio: 'Autistic worship leader & Scripture nerd',
          );

      final signedIn = container.read(memberProfileProvider);
      expect(signedIn.isSignedIn, isTrue);
      expect(signedIn.displayName, 'Hannah Grace');
      expect(signedIn.initials, 'HG');
      expect(signedIn.authMethod, 'inMemory_email');

      container.read(memberProfileProvider.notifier).signInWithOAuth('google');
      final oauthSession = container.read(memberProfileProvider);
      expect(oauthSession.isSignedIn, isTrue);
      expect(oauthSession.authMethod, 'inMemory_google');

      await container.read(memberProfileProvider.notifier).signOut();
      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    });

    patrolWidgetTest(
      'MemberProfileDialog supports Email/Name Sign-In and Sign Out via Patrol BDD',
      ($) async {
        $.tester.view.physicalSize = const Size(1080, 2400);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
        );
        addTearDown(container.dispose);

        await $.pumpWidgetAndSettle(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
          ),
        );

        expect($('Member Profile & Sign-In'), findsOneWidget);
        await $(const Key('profile_display_name_field')).enterText('Caleb Stone');
        await $(const Key('profile_email_field')).enterText('caleb@belong.org');
        await $(const Key('profile_save_sign_in_button')).tap();
      },
    );
  });
}
