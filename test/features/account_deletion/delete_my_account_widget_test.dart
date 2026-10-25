import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_provider.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/account_deletion/presentation/soft_delete_sign_in_notice.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

class MockAccountDeletionSink extends Mock implements AccountDeletionSink {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AccountDeletionRecord(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        flavor: 'dev',
        deletedAt: DateTime.utc(2026, 10, 24),
      ),
    );
  });

  Future<ProviderContainer> pumpProfile(
    PatrolTester $, {
    bool signedIn = false,
    AccountDeletionRepository? repository,
  }) async {
    $.tester.view.physicalSize = const Size(1080, 2400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    ProfileStorageService.instance.clear();

    final container = ProviderContainer(
      overrides: [
        authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        if (repository != null)
          accountDeletionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      await container.read(memberProfileProvider.notifier).signOut();
      container.dispose();
    });

    if (signedIn) {
      container
          .read(memberProfileProvider.notifier)
          .signIn(
            displayName: 'Fellow Member',
            email: 'tester@example.com',
            bio: 'Exploring Belong on the Spectrum',
            icocChurchAffiliation: 'I am not a member of an ICOC church',
          );
    }

    await $.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
      ),
    );
    await $.pump();
    return container;
  }

  group('Delete my account dialog', () {
    patrolWidgetTest('hides the action for a guest', ($) async {
      await pumpProfile($);

      expect($(const Key('delete_my_account_button')), findsNothing);
    });

    patrolWidgetTest('requires DELETE and then signs the member out', (
      $,
    ) async {
      final sink = InMemoryAccountDeletionSink();
      final repository = AccountDeletionRepository(
        sinks: [sink],
        flavor: 'dev',
      );
      final container = await pumpProfile(
        $,
        signedIn: true,
        repository: repository,
      );

      expect($(const Key('delete_my_account_button')), findsOneWidget);
      await $(const Key('delete_my_account_button')).tap();
      await $.pumpAndSettle();

      await $(const Key('delete_my_account_confirm_field')).enterText('nope');
      await $(const Key('delete_my_account_submit_button')).tap();
      await $.pump();

      expect($(const Key('delete_my_account_error_text')), findsOneWidget);
      expect($(AccountDeletionMessages.confirmationRequired), findsOneWidget);
      expect(container.read(memberProfileProvider).isSignedIn, isTrue);
      expect(sink.records, isEmpty);

      await $(const Key('delete_my_account_confirm_field')).enterText('DELETE');
      await $(const Key('delete_my_account_submit_button')).tap();
      await $.pumpAndSettle();

      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
      expect(sink.records.values.single.deletionKind, 'soft');
      expect(sink.records.values.single.email, 'tester@example.com');
    });

    patrolWidgetTest('keeps the member signed in when a backend fails', (
      $,
    ) async {
      final sink = MockAccountDeletionSink();
      when(() => sink.name).thenReturn('firestore');
      when(() => sink.softDelete(any()))
          .thenThrow(Exception('permission-denied'));
      when(
        () => sink.isSoftDeleted(
          userId: any(named: 'userId'),
          flavor: any(named: 'flavor'),
        ),
      ).thenAnswer((_) async => false);

      final container = await pumpProfile(
        $,
        signedIn: true,
        repository: AccountDeletionRepository(sinks: [sink], flavor: 'prod'),
      );

      await $(const Key('delete_my_account_button')).tap();
      await $.pumpAndSettle();
      await $(const Key('delete_my_account_confirm_field')).enterText('DELETE');
      await $(const Key('delete_my_account_submit_button')).tap();
      await $.pumpAndSettle();

      expect($(AccountDeletionMessages.backendFailed), findsOneWidget);
      expect(container.read(memberProfileProvider).isSignedIn, isTrue);
      verify(() => sink.softDelete(any())).called(1);
    });
  });

  patrolWidgetTest('shows the blocked sign-in notice', ($) async {
    await $.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoftDeleteSignInNotice(
            message: 'This account was deleted. Sign-in is turned off. Your posts are still here.',
          ),
        ),
      ),
    );
    expect($(const Key('soft_delete_sign_in_blocked')), findsOneWidget);
    expect(
      $(
        'This account was deleted. Sign-in is turned off. Your posts are still here.',
      ),
      findsOneWidget,
    );
  });
}
