import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../profile/domain/member_profile.dart';
import '../domain/ban_standing.dart';
import '../domain/soft_deleted_user.dart';

/// Pluggable interface for community administrators to manage moderation and
/// soft-delete / ban disruptive users into the remote DB `soft_deleted_users` table (#356).
abstract interface class AdminBanningRepository {
  /// Moves a user's details into the remote DB soft-delete table.
  Future<void> banUser({
    required String userId,
    required String displayName,
    String? email,
    required String bannedByAdminEmail,
    String? reason,
    Map<String, dynamic>? additionalData,
  });

  /// Checks if the given user ID or display name is currently banned/soft-deleted.
  Future<bool> isUserBanned(String userIdOrName);

  /// Reactively observes the full collection of soft-deleted users.
  Stream<List<SoftDeletedUser>> watchBannedUsers();

  /// Restores a soft-deleted user back to active standing.
  Future<void> unbanUser(String userId);
}

/// In-Memory implementation of [AdminBanningRepository] for deterministic,
/// zero-network tests, previews, and offline operation.
class InMemoryAdminBanningRepository implements AdminBanningRepository {
  InMemoryAdminBanningRepository([List<SoftDeletedUser>? initial]) {
    if (initial != null) {
      for (final u in initial) {
        _bannedUsers[u.userId.toLowerCase()] = u;
      }
    }
    _controller.add(_bannedUsers.values.toList());
  }

  final Map<String, SoftDeletedUser> _bannedUsers = {};
  final StreamController<List<SoftDeletedUser>> _controller =
      StreamController<List<SoftDeletedUser>>.broadcast();

  @override
  Future<void> banUser({
    required String userId,
    required String displayName,
    String? email,
    required String bannedByAdminEmail,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = SoftDeletedUser(
      userId: userId,
      displayName: displayName,
      email: email,
      bannedAt: DateTime.now(),
      bannedByAdminEmail: bannedByAdminEmail,
      reason: reason ?? 'Violating calm community guidelines',
      softDeleted: true,
      originalData: additionalData ?? const {},
    );
    _bannedUsers[userId.toLowerCase()] = user;
    _bannedUsers[displayName.toLowerCase()] = user;
    _controller.add(_bannedUsers.values.toSet().toList());
  }

  @override
  Future<bool> isUserBanned(String userIdOrName) async =>
      _bannedUsers.containsKey(userIdOrName.trim().toLowerCase());

  @override
  Stream<List<SoftDeletedUser>> watchBannedUsers() async* {
    yield _bannedUsers.values.toSet().toList();
    yield* _controller.stream;
  }

  @override
  Future<void> unbanUser(String userId) async {
    final q = userId.trim().toLowerCase();
    _bannedUsers.removeWhere(
      (key, u) => key == q || u.userId.toLowerCase() == q || u.displayName.toLowerCase() == q,
    );
    _controller.add(_bannedUsers.values.toSet().toList());
  }

  void dispose() {
    _controller.close();
  }
}

/// Production implementation storing soft-deleted records in Cloud Firestore
/// collection `soft_deleted_users`.
class FirestoreAdminBanningRepository implements AdminBanningRepository {
  FirestoreAdminBanningRepository({this.customFirestore, InMemoryAdminBanningRepository? fallback})
    : _fallback = fallback ?? InMemoryAdminBanningRepository();

  final FirebaseFirestore? customFirestore;
  final InMemoryAdminBanningRepository _fallback;

  static const String collectionName = 'soft_deleted_users';

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> banUser({
    required String userId,
    required String displayName,
    String? email,
    required String bannedByAdminEmail,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    final fs = firestore;
    final sanitizedReason = reason ?? 'Violating calm community guidelines';
    final payload = {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedByAdminEmail': bannedByAdminEmail,
      'reason': sanitizedReason,
      'softDeleted': true,
      'originalData': additionalData ?? {},
    };

    if (fs != null) {
      await fs.collection(collectionName).doc(userId).set(payload);
      AppLogger.info(
        'Moved user "$displayName" ($userId) into remote soft-delete collection by $bannedByAdminEmail',
      );
      return;
    }

    await _fallback.banUser(
      userId: userId,
      displayName: displayName,
      email: email,
      bannedByAdminEmail: bannedByAdminEmail,
      reason: sanitizedReason,
      additionalData: additionalData,
    );
  }

  @override
  Future<bool> isUserBanned(String userIdOrName) async {
    final fs = firestore;
    if (fs != null) {
      final key = userIdOrName.trim();
      if (key.isEmpty) return false;
      final doc = await fs.collection(collectionName).doc(key).get();
      if (doc.exists && doc.data()?['softDeleted'] == true) {
        return true;
      }
      final byName = await fs
          .collection(collectionName)
          .where('displayName', isEqualTo: key)
          .limit(8)
          .get();
      if (byName.docs.any((d) => d.data()['softDeleted'] == true)) {
        return true;
      }
      final byEmail = await fs
          .collection(collectionName)
          .where('email', isEqualTo: key)
          .limit(8)
          .get();
      return byEmail.docs.any((d) => d.data()['softDeleted'] == true);
    }
    return _fallback.isUserBanned(userIdOrName);
  }

  @override
  Stream<List<SoftDeletedUser>> watchBannedUsers() {
    final fs = firestore;
    if (fs != null) {
      return fs
          .collection(collectionName)
          .where('softDeleted', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => SoftDeletedUser.fromMap(doc.data(), id: doc.id))
                .toList(),
          );
    }
    return _fallback.watchBannedUsers();
  }

  @override
  Future<void> unbanUser(String userId) async {
    final fs = firestore;
    if (fs != null) {
      final key = userId.trim();
      final updates = {'softDeleted': false, 'unbannedAt': FieldValue.serverTimestamp()};
      final direct = fs.collection(collectionName).doc(key);
      final directSnap = await direct.get();
      if (directSnap.exists) {
        await direct.update(updates);
      }
      final byName = await fs.collection(collectionName).where('displayName', isEqualTo: key).get();
      for (final doc in byName.docs) {
        if (doc.data()['softDeleted'] == true) {
          await doc.reference.update(updates);
        }
      }
      return;
    }
    await _fallback.unbanUser(userId);
  }
}

/// Provider supplying the [AdminBanningRepository] singleton.
final adminBanningRepositoryProvider = Provider<AdminBanningRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreAdminBanningRepository();
  }
  return InMemoryAdminBanningRepository();
});

/// Reactive stream provider for all currently soft-deleted / banned users.
final bannedUsersStreamProvider = StreamProvider<List<SoftDeletedUser>>((ref) {
  final repo = ref.watch(adminBanningRepositoryProvider);
  return repo.watchBannedUsers();
});

/// Evaluates if a given member display name, email, or user ID is soft-deleted.
final isMemberBannedProvider = Provider.family<bool, String>((ref, memberNameOrId) {
  final listAsync = ref.watch(bannedUsersStreamProvider);
  final list = listAsync.value ?? const <SoftDeletedUser>[];
  return isIdentityBanned(
    bans: list,
    userId: memberNameOrId,
    email: memberNameOrId,
    displayName: memberNameOrId,
  );
});

/// True when the signed-in member matches a standing ban.
final isCurrentMemberBannedProvider = Provider<bool>((ref) {
  final profile = ref.watch(memberProfileProvider);
  if (!profile.isSignedIn) return false;
  final list = ref.watch(bannedUsersStreamProvider).value ?? const <SoftDeletedUser>[];
  return isIdentityBanned(
    bans: list,
    userId: profile.userId,
    email: profile.email,
    displayName: profile.displayName,
  );
});
