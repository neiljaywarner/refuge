import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  group('BelongMembersDirectoryView BDD Widget Tests (#93)', () {
    patrolWidgetTest('renders header, dev members, and handles back button', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      bool backTapped = false;
      await $.tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BelongMembersDirectoryView(
                onBackToSpaces: () => backTapped = true,
              ),
            ),
          ),
        ),
      );

      // Verify title and descriptions
      expect($('Member Directory'), findsOneWidget);
      expect(
        $('Fellowship disciples & leaders'),
        findsOneWidget,
      );

      // Verify dev-mode community members
      expect($('Marty (Organizer)'), findsOneWidget);
      expect($('Caleb Stone'), findsOneWidget);
      expect($('Sarah Chen'), findsOneWidget);
      expect($('David Okafor'), findsOneWidget);

      // Verify church affiliations shown
      expect($(RegExp('DFW Church')), findsWidgets);
      expect($(RegExp('Boston Church')), findsOneWidget);
      expect($(RegExp('London Church')), findsOneWidget);

      // Verify back button works
      await $(const Key('members_directory_back_button')).tap();
      expect(backTapped, isTrue);
    });

    patrolWidgetTest('tapping Edit Profile opens MemberProfileDialog when signed in', ($) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: const AuthSession(
          userId: 'test-user-1',
          displayName: 'Fellow Member',
          email: 'member@belongonthespectrum.com',
          isSignedIn: true,
          authMethod: 'in_memory',
          icocChurchAffiliation: 'DFW Church',
          comfortBadges: ['Sensory Sensitive'],
          bio: 'Calm fellowship advocate',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BelongMembersDirectoryView(),
            ),
          ),
        ),
      );

      expect($('Your Community Card'), findsOneWidget);
      await $(const Key('members_edit_profile_button')).tap();
      await $.pumpAndSettle();

      expect($('Fellow Member'), findsWidgets);
      expect($('Which ICOC church do you attend?'), findsOneWidget);
    });
  });
}
