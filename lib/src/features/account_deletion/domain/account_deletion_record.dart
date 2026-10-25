import 'account_deletion_exception.dart';

/// Tombstone written when a member soft-deletes their own account.
///
/// The auth user, posts, and messages stay. [deletionKind] is always `soft`
/// until a later decision (#545) chooses a hard purge.
class AccountDeletionRecord {
  const AccountDeletionRecord({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.flavor,
    required this.deletedAt,
    this.deletionKind = 'soft',
    this.softDeleted = true,
    this.source = 'self_service',
    this.accountStatus = 'soft_deleted',
    this.acknowledgedBackends = const [],
  });

  final String userId;
  final String displayName;
  final String email;
  final String flavor;
  final DateTime deletedAt;
  final String deletionKind;
  final bool softDeleted;
  final String source;
  final String accountStatus;
  final List<String> acknowledgedBackends;

  /// Firestore document id. `dev` and `prod` share one Firebase project, so the
  /// flavor is part of the id.
  String get documentId => '${flavor}_$userId';

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'flavor': flavor,
    'deletedAt': deletedAt.toIso8601String(),
    'deletionKind': deletionKind,
    'softDeleted': softDeleted,
    'source': source,
    'accountStatus': accountStatus,
  };

  /// Fields merged onto `users/{userId}` so the directory can hide the member.
  Map<String, dynamic> profilePatch() => {
    'accountStatus': accountStatus,
    'deletedAt': deletedAt.toIso8601String(),
    'deletionKind': deletionKind,
    'flavor': flavor,
    'softDeleted': softDeleted,
  };

  AccountDeletionRecord withBackends(List<String> backends) {
    return AccountDeletionRecord(
      userId: userId,
      displayName: displayName,
      email: email,
      flavor: flavor,
      deletedAt: deletedAt,
      deletionKind: deletionKind,
      softDeleted: softDeleted,
      source: source,
      accountStatus: accountStatus,
      acknowledgedBackends: List.unmodifiable(backends),
    );
  }
}

/// One place that can record a soft delete (memory, Firestore, or Appwrite).
abstract interface class AccountDeletionSink {
  String get name;

  Future<void> softDelete(AccountDeletionRecord record);

  Future<bool> isSoftDeleted({required String userId, required String flavor});
}

/// Coordinates confirmation, tombstones, and sign-in blocking.
class AccountDeletionRepository {
  AccountDeletionRepository({
    required List<AccountDeletionSink> sinks,
    required this.flavor,
    DateTime Function()? clock,
  }) : sinks = List.unmodifiable(sinks),
       _clock = clock ?? DateTime.now;

  final List<AccountDeletionSink> sinks;
  final String flavor;
  final DateTime Function() _clock;

  /// Writes every sink. A later sink failure leaves earlier tombstones in
  /// place and does not count as a finished delete, so the caller stays
  /// signed in and can retry.
  Future<AccountDeletionRecord> softDeleteSelf({
    required String userId,
    required String displayName,
    required String email,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      throw const AccountDeletionException(
        code: 'confirmation-required',
        message: AccountDeletionMessages.confirmationRequired,
      );
    }

    final id = userId.trim();
    if (id.isEmpty || id == 'guest') {
      throw const AccountDeletionException(
        code: 'not-signed-in',
        message: AccountDeletionMessages.notSignedIn,
      );
    }

    if (sinks.isEmpty) {
      throw const AccountDeletionException(
        code: 'backend-failed',
        message: AccountDeletionMessages.backendFailed,
      );
    }

    if (await isFullySoftDeleted(id)) {
      throw const AccountDeletionException(
        code: 'already-deleted',
        message: AccountDeletionMessages.alreadyDeleted,
      );
    }

    final record = AccountDeletionRecord(
      userId: id,
      displayName: displayName.trim(),
      email: email.trim(),
      flavor: flavor,
      deletedAt: _clock(),
    );

    final acknowledged = <String>[];
    for (final sink in sinks) {
      try {
        await sink.softDelete(record);
        acknowledged.add(sink.name);
      } catch (error) {
        throw AccountDeletionException(
          code: 'backend-failed',
          message: AccountDeletionMessages.backendFailed,
          backend: sink.name,
          cause: error,
        );
      }
    }

    return record.withBackends(acknowledged);
  }

  /// True only when every configured backend has the tombstone.
  Future<bool> isFullySoftDeleted(String userId) async {
    if (sinks.isEmpty) return false;
    for (final sink in sinks) {
      try {
        final deleted = await sink.isSoftDeleted(
          userId: userId,
          flavor: flavor,
        );
        if (!deleted) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// Primary backend (the first sink) is enough to turn sign-in off.
  Future<bool> isSignInBlocked(String userId) async {
    if (sinks.isEmpty) return false;
    try {
      return await sinks.first.isSoftDeleted(userId: userId, flavor: flavor);
    } catch (_) {
      return false;
    }
  }
}
