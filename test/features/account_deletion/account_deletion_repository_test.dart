import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
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

  AccountDeletionRepository repository({List<AccountDeletionSink>? sinks, String flavor = 'dev'}) =>
      AccountDeletionRepository(
        sinks: sinks ?? [InMemoryAccountDeletionSink()],
        flavor: flavor,
        clock: () => deletedAt,
      );

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
      expect(dev.profilePatch()['listedInDirectory'], isFalse);
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
          isA<AccountDeletionException>().having((error) => error.code, 'code', 'not-signed-in'),
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
          isA<AccountDeletionException>().having((error) => error.code, 'code', 'already-deleted'),
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

    test('sign out leaves the following container signed out', () async {
      ProfileStorageService.instance.clear();
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          accountDeletionRepositoryProvider.overrideWithValue(
            AccountDeletionRepository(sinks: [InMemoryAccountDeletionSink()], flavor: 'dev'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(memberProfileProvider.notifier)
          .signIn(displayName: 'Fellow Member', email: 'tester@example.com');
      container.read(memberProfileProvider.notifier).signInWithOAuth('google');
      await container.read(memberProfileProvider.notifier).signOut();
      expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    });

    test('a later container stays signed out', () {
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.serverpod),
          accountDeletionRepositoryProvider.overrideWithValue(
            AccountDeletionRepository(sinks: [InMemoryAccountDeletionSink()], flavor: 'dev'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profile = container.read(memberProfileProvider);
      expect(profile.isSignedIn, isFalse, reason: profile.authMethod);
    });

    test('password sign-in is refused after a soft delete', () async {
      final repo = AccountDeletionRepository(sinks: [InMemoryAccountDeletionSink()], flavor: 'dev');
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          accountDeletionRepositoryProvider.overrideWithValue(repo),
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

      await repo.softDeleteSelf(
        userId: userId,
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        confirmed: true,
      );
      await auth.signOut();

      expect(
        () => auth.signInWithPassword(email: 'tester@example.com', password: 'password1'),
        throwsA(isA<AuthException>().having((error) => error.code, 'code', 'account-soft-deleted')),
      );
      expect(auth.currentSession().isSignedIn, isFalse);
    });

    test('a member created now can delete, stay blocked, then come back', () async {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final email = 'tester-$stamp@example.com';
      final sink = InMemoryAccountDeletionSink();
      final repo = repository(sinks: [sink]);

      final record = await repo.softDeleteSelf(
        userId: 'member-$stamp',
        displayName: 'Fellow Member',
        email: email,
        confirmed: true,
      );

      expect(record.profilePatch()['listedInDirectory'], isFalse);
      expect(await repo.isSignInBlocked('member-$stamp'), isTrue);

      expect(
        () => repo.restoreSelf(userId: 'member-$stamp', confirmed: false),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.code,
            'code',
            'confirmation-required',
          ),
        ),
      );
      expect(await repo.isSignInBlocked('member-$stamp'), isTrue);

      await repo.restoreSelf(userId: 'member-$stamp', confirmed: true);

      expect(await repo.isSignInBlocked('member-$stamp'), isFalse);
      expect(sink.records['dev_member-$stamp']?.softDeleted, isFalse);
      expect(
        AccountDeletionRecord.directoryRestorePatch(
          DateTime.utc(2026, 10, 25),
        )['listedInDirectory'],
        isTrue,
      );
    });

    test('admin unban does not clear a self-delete tombstone', () async {
      final sink = InMemoryAccountDeletionSink();
      final repo = repository(sinks: [sink]);
      await repo.softDeleteSelf(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        confirmed: true,
      );

      final admin = InMemoryAdminBanningRepository();
      addTearDown(admin.dispose);
      await admin.banUser(
        userId: 'member-1',
        displayName: 'Fellow Member',
        email: 'tester@example.com',
        bannedByAdminEmail: 'organizer@belongonthespectrum.com',
      );
      await admin.unbanUser('member-1');

      expect(await admin.isUserBanned('member-1'), isFalse);
      expect(await repo.isSignInBlocked('member-1'), isTrue);
    });

    test('password sign-in works again after the member restores', () async {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final email = 'tester-return-$stamp@example.com';
      final repo = AccountDeletionRepository(sinks: [InMemoryAccountDeletionSink()], flavor: 'dev');
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          accountDeletionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authRepositoryProvider);
      await auth.registerWithPassword(
        email: email,
        password: 'password1',
        displayName: 'Fellow Member',
        icocChurchAffiliation: 'Chicago Church of Christ',
      );
      final userId = auth.currentSession().userId;
      await repo.softDeleteSelf(
        userId: userId,
        displayName: 'Fellow Member',
        email: email,
        confirmed: true,
      );
      await auth.signOut();

      expect(
        () => auth.signInWithPassword(email: email, password: 'password1'),
        throwsA(isA<AuthException>().having((error) => error.userId, 'userId', userId)),
      );

      await repo.restoreSelf(userId: userId, confirmed: true);
      final session = await auth.signInWithPassword(email: email, password: 'password1');
      expect(session.isSignedIn, isTrue);
      expect(session.email, email);
    });
  });
}
