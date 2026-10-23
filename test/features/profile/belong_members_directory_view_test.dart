import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  group('BelongMembersDirectoryView BDD Widget Tests (#93)', () {
    patrolWidgetTest('renders header, user card, and dev dummy members', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          postRepositoryProvider.overrideWithValue(LocalPostRepository(isDevMode: true)),
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
      expect($('Caleb Stone'), findsOneWidget);
      expect($('Sarah Chen'), findsOneWidget);
      expect($('David Okafor'), findsOneWidget);

      // Verify church affiliations shown
      expect($('DFW Church (Partner) • Community Organizer & Founder'), findsOneWidget);
      expect($('Boston Church • Bible Teacher & Scholar'), findsOneWidget);

      // Verify back button works
      await $(Icons.arrow_back_rounded).tap();
      expect(backTapped, isTrue);
    });

    patrolWidgetTest('tapping a member card opens OtherMemberProfileDialog', ($) async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          postRepositoryProvider.overrideWithValue(LocalPostRepository(isDevMode: true)),
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

      // Tap Marty (Organizer) card
      await $('Marty (Organizer)').tap();
      await $.pumpAndSettle();

      // Dialog opens showing other member profile details
      expect($(const Key('other_member_profile_name')), findsOneWidget);
      expect($('ICOC'), findsWidgets);
    });
  });
}
