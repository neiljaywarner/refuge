import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_session.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/first_visit_welcome_card.dart';

void main() {
  group('FirstVisitWelcomeCard (#663)', () {
    setUp(() {
      ProfileStorageService.instance.clear();
    });

    tearDown(() {
      ProfileStorageService.instance.clear();
    });

    testWidgets('Skip marks storage and calls onFinished', (tester) async {
      var finished = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: FirstVisitWelcomeCard(onFinished: () => finished = true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first_visit_welcome_screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('first_visit_skip_button')));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(ProfileStorageService.instance.skippedFirstVisitWelcome, isTrue);
    });

    testWidgets('Save with name updates profile and finishes', (tester) async {
      final authRepo = InMemoryAuthRepository(
        initialSession: AuthSession(
          userId: 'uid-save-test',
          displayName: 'Fellowship Member',
          email: 'member@belongonthespectrum.com',
          bio: 'bio',
          comfortBadges: const ['Literal communication appreciated'],
          isSignedIn: true,
          authMethod: 'in_memory_password',
          emailVerified: true,
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
      );
      addTearDown(container.dispose);
      var finished = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: FirstVisitWelcomeCard(onFinished: () => finished = true)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('first_visit_display_name_field')), 'Sarah K.');
      await tester.tap(find.byKey(const Key('first_visit_church_affiliation_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I am not a member of an ICOC church').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('first_visit_save_button')));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(container.read(memberProfileProvider).displayName, 'Sarah K.');
      expect(
        container.read(memberProfileProvider).icocChurchAffiliation,
        'I am not a member of an ICOC church',
      );
    });
  });
}
