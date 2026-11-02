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

  /// Firebase uid for [userId] or [displayName], when a `users` row identifies one account.
  ///
  /// Returns null when no single uid can be chosen. Sample names without a
  /// `users` document stay name-only and cannot be blocked in security rules.
  Future<String?> resolveAccountUid({required String userId, required String displayName});

  /// Records that the ban exists and content erase still needs another attempt.
  Future<void> markErasePending({
    required String userId,
    required String displayName,
    required List<String> failedSteps,
  });

  /// Clears the retry flag after posts, comments, and messages are gone.
  Future<void> clearErasePending({required String userId, required String displayName});
}

/// Firebase Auth uids are long and have no spaces. Display names do not qualify.
bool isImmutableAccountUid(String value) {
  final id = value.trim();
  return id.length >= 20 && !id.contains(' ') && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);
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

  @override
  Future<String?> resolveAccountUid({required String userId, required String displayName}) async {
    final trimmed = userId.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<void> markErasePending({
    required String userId,
    required String displayName,
    required List<String> failedSteps,
  }) async {
    _replaceMatching(
      userId: userId,
      displayName: displayName,
      update: (user) =>
          user.copyWith(erasePending: true, eraseErrors: List<String>.from(failedSteps)),
    );
  }

  @override
  Future<void> clearErasePending({required String userId, required String displayName}) async {
    _replaceMatching(
      userId: userId,
      displayName: displayName,
      update: (user) => user.copyWith(erasePending: false, eraseErrors: const []),
    );
  }

  void _replaceMatching({
    required String userId,
    required String displayName,
    required SoftDeletedUser Function(SoftDeletedUser user) update,
  }) {
    final id = userId.trim().toLowerCase();
    final name = displayName.trim().toLowerCase();
    final keys = _bannedUsers.entries
        .where(
          (entry) =>
              entry.key == id ||
              entry.key == name ||
              entry.value.userId.toLowerCase() == id ||
              entry.value.displayName.toLowerCase() == name,
        )
        .map((entry) => entry.key)
        .toList();
    for (final key in keys) {
      _bannedUsers[key] = update(_bannedUsers[key]!);
    }
    if (keys.isNotEmpty) {
      _controller.add(_bannedUsers.values.toSet().toList());
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Cloud ban row for `soft_deleted_users`.
///
/// Every signed-in member can read that collection, so the document must not
/// carry an email address. The in-memory repository may still keep one on
/// this device. Rules reject `email` and `bannedByAdminEmail` on create.
Map<String, dynamic> firestoreBanDocument({
  required String userId,
  required String displayName,
  required String reason,
  Map<String, dynamic>? additionalData,
}) {
  final original = Map<String, dynamic>.from(additionalData ?? const {});
  const stripped = ['email', 'bannedByAdminEmail', 'contactEmail', 'phone', 'phoneNumber'];
  for (final key in stripped) {
    original.remove(key);
  }
  return {
    'userId': userId,
    'displayName': displayName,
    'bannedAt': FieldValue.serverTimestamp(),
    'reason': reason,
    'softDeleted': true,
    'originalData': original,
  };
}

/// Production implementation storing soft-deleted records in Cloud Firestore
/// collection `soft_deleted_users`.
class FirestoreAdminBanningRepository implements AdminBanningRepository {
  FirestoreAdminBanningRepository({this.customFirestore, InMemoryAdminBanningRepository? fallback})
    : _fallback = fallback ?? InMemoryAdminBanningRepository();

  final FirebaseFirestore? customFirestore;
  final InMemoryAdminBanningRepository _fallback;

  static const String collectionName = 'soft_deleted_users';
  static const String bannedUidCollection = 'banned_uids';

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
    final payload = firestoreBanDocument(
      userId: userId,
      displayName: displayName,
      reason: sanitizedReason,
      additionalData: additionalData,
    );

    if (fs != null) {
      final batch = fs.batch();
      batch.set(fs.collection(collectionName).doc(userId), payload);
      final name = displayName.trim();
      if (name.isNotEmpty && name != userId) {
        batch.set(fs.collection(collectionName).doc(name), payload);
      }
      if (isImmutableAccountUid(userId)) {
        batch.set(fs.collection(bannedUidCollection).doc(userId), {
          'uid': userId,
          'banned': true,
          'bannedAt': FieldValue.serverTimestamp(),
          'displayName': name,
        });
      }
      await batch.commit();
      AppLogger.info('Moved user "$displayName" ($userId) into remote soft-delete collection');
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
      final uids = <String>{};
      final direct = fs.collection(collectionName).doc(key);
      final directSnap = await direct.get();
      if (directSnap.exists) {
        await direct.update(updates);
        final storedUid = directSnap.data()?['userId'];
        if (storedUid is String && storedUid.isNotEmpty) uids.add(storedUid);
        if (isImmutableAccountUid(key)) uids.add(key);
      }
      final byName = await fs.collection(collectionName).where('displayName', isEqualTo: key).get();
      for (final doc in byName.docs) {
        if (doc.data()['softDeleted'] == true) {
          await doc.reference.update(updates);
          final storedUid = doc.data()['userId'];
          if (storedUid is String && storedUid.isNotEmpty) uids.add(storedUid);
        }
      }
      for (final uid in uids) {
        if (!isImmutableAccountUid(uid)) continue;
        await fs.collection(bannedUidCollection).doc(uid).set({
          'uid': uid,
          'banned': false,
          'displayName': key,
        }, SetOptions(merge: true));
      }
      return;
    }
    await _fallback.unbanUser(userId);
  }

  @override
  Future<String?> resolveAccountUid({required String userId, required String displayName}) async {
    final fs = firestore;
    if (fs == null) return _fallback.resolveAccountUid(userId: userId, displayName: displayName);
    final trimmedId = userId.trim();
    if (trimmedId.isNotEmpty) {
      final direct = await fs.collection('users').doc(trimmedId).get();
      if (direct.exists) {
        final stored = direct.data()?['uid'];
        if (stored is String && stored.trim().isNotEmpty) return stored.trim();
        return direct.id;
      }
    }
    final name = displayName.trim();
    if (name.isNotEmpty) {
      final matches = await fs
          .collection('users')
          .where('displayName', isEqualTo: name)
          .limit(2)
          .get();
      if (matches.docs.length > 1) {
        throw BanTargetAmbiguousException(name);
      }
      if (matches.docs.length == 1) {
        final doc = matches.docs.single;
        final stored = doc.data()['uid'];
        if (stored is String && stored.trim().isNotEmpty) return stored.trim();
        return doc.id;
      }
    }
    if (isImmutableAccountUid(trimmedId)) return trimmedId;
    return null;
  }

  @override
  Future<void> markErasePending({
    required String userId,
    required String displayName,
    required List<String> failedSteps,
  }) async {
    final fs = firestore;
    if (fs == null) {
      await _fallback.markErasePending(
        userId: userId,
        displayName: displayName,
        failedSteps: failedSteps,
      );
      return;
    }
    final payload = {'erasePending': true, 'eraseErrors': failedSteps};
    await fs.collection(collectionName).doc(userId).set(payload, SetOptions(merge: true));
    final name = displayName.trim();
    if (name.isNotEmpty && name != userId) {
      await fs.collection(collectionName).doc(name).set(payload, SetOptions(merge: true));
    }
  }

  @override
  Future<void> clearErasePending({required String userId, required String displayName}) async {
    final fs = firestore;
    if (fs == null) {
      await _fallback.clearErasePending(userId: userId, displayName: displayName);
      return;
    }
    const payload = {'erasePending': false, 'eraseErrors': <String>[]};
    await fs.collection(collectionName).doc(userId).set(payload, SetOptions(merge: true));
    final name = displayName.trim();
    if (name.isNotEmpty && name != userId) {
      await fs.collection(collectionName).doc(name).set(payload, SetOptions(merge: true));
    }
  }
}

/// More than one `users` row shares this public name, so a ban must not guess a uid.
class BanTargetAmbiguousException implements Exception {
  BanTargetAmbiguousException(this.displayName);

  final String displayName;

  @override
  String toString() =>
      'More than one account uses the name "$displayName". Ban the member from their account id.';
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

/// Stays true after a banned sign-in is refused, so the lockout copy remains
/// on screen once that Firebase session has ended.
final banRefusalVisibleProvider = StateProvider<bool>((ref) => false);

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
