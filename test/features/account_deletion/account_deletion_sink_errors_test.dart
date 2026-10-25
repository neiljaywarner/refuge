import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockAccount extends Mock implements Account {}

class _ThrowingSink implements AccountDeletionSink {
  _ThrowingSink(this.name);

  @override
  final String name;

  int calls = 0;

  @override
  Future<void> softDelete(AccountDeletionRecord record) async {
    calls += 1;
    throw Exception('$name unavailable');
  }

  @override
  Future<bool> isSoftDeleted({
    required String userId,
    required String flavor,
  }) async {
    return false;
  }
}

void main() {
  final deletedAt = DateTime.utc(2026, 10, 24, 18);
  final record = AccountDeletionRecord(
    userId: 'member-1',
    displayName: 'Fellow Member',
    email: 'tester@example.com',
    flavor: 'dev',
    deletedAt: deletedAt,
  );

  setUpAll(() {
    registerFallbackValue(record);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
  });

  group('FirestoreAccountDeletionSink errors', () {
    test('reports a permission failure and does not claim success', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollection();
      final document = MockDocument();
      when(() => firestore.collection(any())).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(document);
      when(() => document.set(any(), any()))
          .thenThrow(Exception('permission-denied'));

      final sink = FirestoreAccountDeletionSink(injectedFirestore: firestore);

      expect(
        () => sink.softDelete(record),
        throwsA(isA<AccountDeletionSinkException>()),
      );
      verify(() => document.set(any(), any())).called(1);
    });

    test('reads a soft-deleted tombstone back from Firestore', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollection();
      final document = MockDocument();
      final snapshot = MockSnapshot();
      when(() => firestore.collection(any())).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(document);
      when(() => document.set(any(), any())).thenAnswer((_) async {});
      when(() => document.get()).thenAnswer((_) async => snapshot);
      when(() => snapshot.data()).thenReturn({
        'softDeleted': true,
        'flavor': 'dev',
        'deletionKind': 'soft',
      });

      final sink = FirestoreAccountDeletionSink(injectedFirestore: firestore);
      await sink.softDelete(record);

      expect(
        await sink.isSoftDeleted(userId: 'member-1', flavor: 'dev'),
        isTrue,
      );
      verify(() => document.set(record.toMap(), any())).called(1);
      verify(() => document.set(record.profilePatch(), any())).called(1);
    });
  });

  group('AppwriteAccountDeletionSink errors', () {
    test('surfaces a prefs update failure', () async {
      final account = MockAccount();
      when(() => account.updatePrefs(prefs: any(named: 'prefs')))
          .thenThrow(Exception('appwrite unavailable'));
      final remote = AppwritePrefsAccountDeletionRemote(account);

      expect(
        () => remote.markSoftDeleted(record),
        throwsA(isA<AccountDeletionSinkException>()),
      );
    });

    test('a mirror failure leaves the member able to retry', () async {
      final memory = InMemoryAccountDeletionSink();
      final appwrite = _ThrowingSink('appwrite');
      final repo = AccountDeletionRepository(
        sinks: [
          memory,
          AppwriteAccountDeletionSink(remote: _RemoteFromSink(appwrite)),
        ],
        flavor: 'dev',
        clock: () => deletedAt,
      );

      await expectLater(
        repo.softDeleteSelf(
          userId: 'member-1',
          displayName: 'Fellow Member',
          email: 'tester@example.com',
          confirmed: true,
        ),
        throwsA(
          isA<AccountDeletionException>()
              .having((error) => error.code, 'code', 'backend-failed')
              .having((error) => error.backend, 'backend', 'appwrite'),
        ),
      );
      expect(memory.records.containsKey('dev_member-1'), isTrue);
      expect(await repo.isSignInBlocked('member-1'), isTrue);
      expect(await repo.isFullySoftDeleted('member-1'), isFalse);

      appwrite.calls = 0;
      await expectLater(
        repo.softDeleteSelf(
          userId: 'member-1',
          displayName: 'Fellow Member',
          email: 'tester@example.com',
          confirmed: true,
        ),
        throwsA(isA<AccountDeletionException>()),
      );
      expect(appwrite.calls, 1);
    });

    test('does not call later sinks when the primary write fails', () async {
      final primary = _ThrowingSink('firestore');
      final mirror = _ThrowingSink('appwrite');
      final repo = AccountDeletionRepository(
        sinks: [
          primary,
          AppwriteAccountDeletionSink(remote: _RemoteFromSink(mirror)),
        ],
        flavor: 'prod',
        clock: () => deletedAt,
      );

      await expectLater(
        repo.softDeleteSelf(
          userId: 'member-1',
          displayName: 'Fellow Member',
          email: 'tester@example.com',
          confirmed: true,
        ),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.backend,
            'backend',
            'firestore',
          ),
        ),
      );
      expect(primary.calls, 1);
      expect(mirror.calls, 0);
    });
  });
}

class _RemoteFromSink implements AppwriteAccountDeletionRemote {
  _RemoteFromSink(this._sink);

  final AccountDeletionSink _sink;

  @override
  Future<void> markSoftDeleted(AccountDeletionRecord record) {
    return _sink.softDelete(record);
  }

  @override
  Future<bool> isSoftDeleted({required String userId, required String flavor}) {
    return _sink.isSoftDeleted(userId: userId, flavor: flavor);
  }
}
