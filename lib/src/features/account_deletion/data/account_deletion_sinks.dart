import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/account_deletion_exception.dart';
import '../domain/account_deletion_record.dart';

/// Deterministic sink for unit tests and offline sessions.
class InMemoryAccountDeletionSink implements AccountDeletionSink {
  final Map<String, AccountDeletionRecord> records = {};

  @override
  String get name => 'memory';

  @override
  Future<void> softDelete(AccountDeletionRecord record) async {
    records[record.documentId] = record;
  }

  @override
  Future<bool> isSoftDeleted({
    required String userId,
    required String flavor,
  }) async {
    final record = records['${flavor}_$userId'];
    return record != null && record.softDeleted && record.flavor == flavor;
  }

  @override
  Future<void> restore({
    required String userId,
    required String flavor,
    required DateTime restoredAt,
  }) async {
    final existing = records['${flavor}_$userId'];
    if (existing == null) return;
    records['${flavor}_$userId'] = AccountDeletionRecord(
      userId: existing.userId,
      displayName: existing.displayName,
      email: existing.email,
      flavor: existing.flavor,
      deletedAt: existing.deletedAt,
      deletionKind: existing.deletionKind,
      softDeleted: false,
      source: existing.source,
      accountStatus: 'active',
    );
  }
}

/// Writes `self_deleted_accounts/{flavor}_{userId}` and merges the profile.
class FirestoreAccountDeletionSink implements AccountDeletionSink {
  FirestoreAccountDeletionSink({this.injectedFirestore, this.firebaseReady});

  static const tombstoneCollection = 'self_deleted_accounts';
  static const usersCollection = 'users';

  final FirebaseFirestore? injectedFirestore;
  final bool Function()? firebaseReady;

  @override
  String get name => 'firestore';

  FirebaseFirestore? get firestore {
    if (injectedFirestore != null) return injectedFirestore;
    try {
      final ready = firebaseReady?.call() ?? Firebase.apps.isNotEmpty;
      if (ready) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> softDelete(AccountDeletionRecord record) async {
    final fs = firestore;
    if (fs == null) {
      throw const AccountDeletionSinkException(
        'Cloud Firestore is not ready on this device.',
      );
    }
    try {
      await fs
          .collection(tombstoneCollection)
          .doc(record.documentId)
          .set(record.toMap(), SetOptions(merge: true));
      await fs
          .collection(usersCollection)
          .doc(record.userId)
          .set(record.profilePatch(), SetOptions(merge: true));
    } catch (error) {
      if (error is AccountDeletionSinkException) rethrow;
      throw AccountDeletionSinkException(
        'Firestore could not save the deletion.',
      );
    }
  }

  @override
  Future<bool> isSoftDeleted({
    required String userId,
    required String flavor,
  }) async {
    final fs = firestore;
    if (fs == null) return false;
    try {
      final snapshot = await fs
          .collection(tombstoneCollection)
          .doc('${flavor}_$userId')
          .get();
      final data = snapshot.data();
      return data != null &&
          data['softDeleted'] == true &&
          data['flavor'] == flavor;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> restore({
    required String userId,
    required String flavor,
    required DateTime restoredAt,
  }) async {
    final fs = firestore;
    if (fs == null) {
      throw const AccountDeletionSinkException(
        'Cloud Firestore is not ready on this device.',
      );
    }
    final patch = AccountDeletionRecord.directoryRestorePatch(restoredAt);
    try {
      await fs.collection(tombstoneCollection).doc('${flavor}_$userId').set({
        ...patch,
        'userId': userId,
        'flavor': flavor,
      }, SetOptions(merge: true));
      await fs
          .collection(usersCollection)
          .doc(userId)
          .set(patch, SetOptions(merge: true));
    } catch (error) {
      if (error is AccountDeletionSinkException) rethrow;
      throw const AccountDeletionSinkException(
        'Firestore could not restore the account.',
      );
    }
  }
}

/// Admin or client operation that records the soft delete in Appwrite.
abstract interface class AppwriteAccountDeletionRemote {
  Future<void> markSoftDeleted(AccountDeletionRecord record);

  Future<bool> isSoftDeleted({required String userId, required String flavor});

  Future<void> clearSoftDeleted({
    required String userId,
    required String flavor,
    required DateTime restoredAt,
  });
}

/// Client-session prefs update. Blocking the user (`status: false`) is an
/// admin action and is not available to the signed-in member SDK.
class AppwritePrefsAccountDeletionRemote
    implements AppwriteAccountDeletionRemote {
  AppwritePrefsAccountDeletionRemote(this._account);

  final Account _account;

  @override
  Future<void> markSoftDeleted(AccountDeletionRecord record) async {
    try {
      await _account.get();
      await _account.updatePrefs(prefs: record.toMap());
    } on AccountDeletionSinkException {
      rethrow;
    } catch (error) {
      // Firebase Auth is the member session. Appwrite prefs exist only when
      // that same person also has an Appwrite session. A guest 401 must not
      // undo the Firestore tombstone or keep them signed in.
      if (_isMissingAppwriteSession(error)) return;
      throw const AccountDeletionSinkException(
        'Appwrite could not save the deletion.',
      );
    }
  }

  @override
  Future<bool> isSoftDeleted({
    required String userId,
    required String flavor,
  }) async {
    try {
      final user = await _account.get();
      final prefs = user.prefs.data;
      return prefs['softDeleted'] == true &&
          prefs['flavor'] == flavor &&
          prefs['userId'] == userId;
    } catch (error) {
      if (_isMissingAppwriteSession(error)) return true;
      return false;
    }
  }

  @override
  Future<void> clearSoftDeleted({
    required String userId,
    required String flavor,
    required DateTime restoredAt,
  }) async {
    try {
      await _account.get();
      await _account.updatePrefs(
        prefs: {
          ...AccountDeletionRecord.directoryRestorePatch(restoredAt),
          'userId': userId,
          'flavor': flavor,
        },
      );
    } on AccountDeletionSinkException {
      rethrow;
    } catch (error) {
      if (_isMissingAppwriteSession(error)) return;
      throw const AccountDeletionSinkException(
        'Appwrite could not restore the account.',
      );
    }
  }
}

bool _isMissingAppwriteSession(Object error) {
  if (error is! AppwriteException) return false;
  final code = error.code;
  return code == 401 || code == 403;
}

class AppwriteAccountDeletionSink implements AccountDeletionSink {
  AppwriteAccountDeletionSink({required this.remote});

  final AppwriteAccountDeletionRemote remote;

  @override
  String get name => 'appwrite';

  @override
  Future<void> softDelete(AccountDeletionRecord record) {
    return remote.markSoftDeleted(record);
  }

  @override
  Future<bool> isSoftDeleted({required String userId, required String flavor}) {
    return remote.isSoftDeleted(userId: userId, flavor: flavor);
  }

  @override
  Future<void> restore({
    required String userId,
    required String flavor,
    required DateTime restoredAt,
  }) {
    return remote.clearSoftDeleted(
      userId: userId,
      flavor: flavor,
      restoredAt: restoredAt,
    );
  }
}
