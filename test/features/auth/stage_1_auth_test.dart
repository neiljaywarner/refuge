import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

void main() {
  group('Stage 1 Any Auth & Pluggable AuthRepository Adapter Tests (#26, ADR-0009)', () {
    for (final target in BackendTarget.values) {
      test('signs in with email/name, OAuth, and signs out cleanly on ${target.displayName}', () async {
        final container = ProviderContainer(
          overrides: [
            authBackendTargetProvider.overrideWithValue(target),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(memberProfileProvider).isSignedIn, isFalse);

        container.read(memberProfileProvider.notifier).signIn(
              displayName: 'Hannah Grace',
              email: 'hannah@belongonthespectrum.com',
              bio: 'Autistic worship leader & Scripture nerd',
            );

        final signedIn = container.read(memberProfileProvider);
        expect(signedIn.isSignedIn, isTrue);
        expect(signedIn.displayName, 'Hannah Grace');
        expect(signedIn.initials, 'HG');
        expect(signedIn.authMethod, '${target.name}_email');

        container.read(memberProfileProvider.notifier).signInWithOAuth('google');
        final oauthSession = container.read(memberProfileProvider);
        expect(oauthSession.isSignedIn, isTrue);
        expect(oauthSession.authMethod, '${target.name}_google');

        await container.read(memberProfileProvider.notifier).signOut();
        expect(container.read(memberProfileProvider).isSignedIn, isFalse);
      });
    }

    patrolWidgetTest('MemberProfileDialog supports Email/Name Sign-In and Sign Out via Patrol BDD', ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MemberProfileDialog(),
            ),
          ),
        ),
      );

      expect($('Member Profile & Sign-In'), findsOneWidget);
      await $(const Key('profile_display_name_field')).enterText('Caleb Stone');
      await $(const Key('profile_email_field')).enterText('caleb@belong.org');
      await $(const Key('profile_save_sign_in_button')).tap();
    });
  });
}
