import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_provider.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/auth/domain/auth_exception.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';

void main() {
  final deletedAt = DateTime.utc(2026, 10, 24, 18);

  AccountDeletionRepository repository({
    List<AccountDeletionSink>? sinks,
    String flavor = 'dev',
  }) {
    return AccountDeletionRepository(
      sinks: sinks ?? [InMemoryAccountDeletionSink()],
      flavor: flavor,
      clock: () => deletedAt,
    );
  }

  group('AccountDeletionRecord', () {
    test('document ids keep dev and prod tombstones apart', () {
      final dev = AccountDeletionRecord(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        flavor: 'dev',
        deletedAt: deletedAt,
      );
      final prod = AccountDeletionRecord(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        flavor: 'prod',
        deletedAt: deletedAt,
      );

      expect(dev.documentId, 'dev_member-1');
      expect(prod.documentId, 'prod_member-1');
      expect(dev.toMap()['deletionKind'], 'soft');
      expect(dev.toMap()['accountStatus'], 'soft_deleted');
      expect(dev.profilePatch()['softDeleted'], isTrue);
    });
  });

  group('AccountDeletionRepository', () {
    test('rejects a missing confirmation', () async {
      final repo = repository();

      expect(
        () => repo.softDeleteSelf(
          userId: 'member-1',
          displayName: 'Fellow Member',
          email: 'tester@example.com',
          confirmed: false,
        ),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.code,
            'code',
            'confirmation-required',
          ),
        ),
      );
    });

    test('rejects a guest session', () async {
      final repo = repository();

      expect(
        () => repo.softDeleteSelf(
          userId: 'guest',
          displayName: 'Fellow Member',
          email: '',
          confirmed: true,
        ),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.code,
            'code',
            'not-signed-in',
          ),
        ),
      );
    });

    test('writes a soft tombstone and then refuses a second delete', () async {
      final sink = InMemoryAccountDeletionSink();
      final repo = repository(sinks: [sink]);

      final record = await repo.softDeleteSelf(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        confirmed: true,
      );

      expect(record.acknowledgedBackends, ['memory']);
      expect(record.deletionKind, 'soft');
      expect(sink.records['dev_member-1']?.email, 'tester@example.com');
      expect(await repo.isSignInBlocked('member-1'), isTrue);
      expect(await repo.isSignInBlocked('someone-else'), isFalse);

      expect(
        () => repo.softDeleteSelf(
          userId: 'member-1',
          displayName: 'Fellow Member',
          email: 'tester@example.com',
          confirmed: true,
        ),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.code,
            'code',
            'already-deleted',
          ),
        ),
      );
    });

    test('a dev tombstone does not block the prod flavor', () async {
      final sink = InMemoryAccountDeletionSink();
      final dev = repository(sinks: [sink], flavor: 'dev');
      final prod = repository(sinks: [sink], flavor: 'prod');

      await dev.softDeleteSelf(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        confirmed: true,
      );

      expect(await dev.isSignInBlocked('member-1'), isTrue);
      expect(await prod.isSignInBlocked('member-1'), isFalse);
    });

    test('sign out leaves the following container signed out', () {
      ProfileStorageService.instance.clear();
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);
      container.read(memberProfileProvider.notifier).signIn(
            displayName: 'Fellow Member',
            email: 'tester@example.com',
          );
      container.read(memberProfileProvider.notifier).signInWithOAuth('google');
      container.read(memberProfileProvider.notifier).signOut();
      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    });

    test('a later container stays signed out', () {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.serverpod),
        ],
      );
      addTearDown(container.dispose);
      final profile = container.read(memberProfileProvider);
      expect(profile.isSignedIn, isFalse, reason: profile.authMethod);
    });

    test('password sign-in is refused after a soft delete', () async {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authRepositoryProvider);
      await auth.registerWithPassword(
        email: 'tester@example.com',
        password: 'password1',
        displayName: 'Fellow Member',
        icocChurchAffiliation: 'Chicago Church of Christ',
      );
      final userId = auth.currentSession().userId;

      await container
          .read(accountDeletionRepositoryProvider)
          .softDeleteSelf(
            userId: userId,
            displayName: 'Fellow Member',
            email: 'tester@example.com',
            confirmed: true,
          );
      await auth.signOut();

      expect(
        () => auth.signInWithPassword(
          email: 'tester@example.com',
          password: 'password1',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            'account-soft-deleted',
          ),
        ),
      );
      expect(auth.currentSession().isSignedIn, isFalse);
    });
  });
}
