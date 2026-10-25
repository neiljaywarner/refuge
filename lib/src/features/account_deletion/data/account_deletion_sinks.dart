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
}

/// Admin or client operation that records the soft delete in Appwrite.
abstract interface class AppwriteAccountDeletionRemote {
  Future<void> markSoftDeleted(AccountDeletionRecord record);

  Future<bool> isSoftDeleted({required String userId, required String flavor});
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
      await _account.updatePrefs(prefs: record.toMap());
    } catch (error) {
      throw AccountDeletionSinkException(
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
    } catch (_) {
      return false;
    }
  }
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
}
