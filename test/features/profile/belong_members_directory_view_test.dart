import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  group('BelongMembersDirectoryView BDD Widget Tests (#93)', () {
    patrolWidgetTest('renders header, user card, and dev dummy members', ($) async {
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

      // Verify dev-mode dummy community members
      expect($('Marty (Organizer)'), findsOneWidget);
      expect($('Hannah M.'), findsOneWidget);
      expect($('Alex K.'), findsOneWidget);
      expect($('Jordan P.'), findsOneWidget);

      // Verify church affiliations shown
      expect($(find.textContaining('DFW Church (Partner)')), findsWidgets);
      expect($(find.textContaining('Austin Christian Church')), findsOneWidget);
      expect($(find.textContaining('Boston Church of Christ')), findsOneWidget);
      expect($(find.textContaining('I am not a member of an ICOC church')), findsOneWidget);

      // Verify back button works
      await $(const Key('members_directory_back_button')).tap();
      expect(backTapped, isTrue);
    });

    patrolWidgetTest('tapping Edit Profile opens MemberProfileDialog', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: BelongMembersDirectoryView(
                onBackToSpaces: () {},
              ),
            ),
          ),
        ),
      );

      await $(const Key('members_edit_profile_button')).tap();
      await $.pumpAndSettle();

      expect($('Member Profile & Sign-In'), findsOneWidget);
      expect($('Which ICOC church do you attend?'), findsOneWidget);
    });
  });
}
