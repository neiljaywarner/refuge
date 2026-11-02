import 'errors.dart';

/// Firestore paths the Flutter app uses, and the Appwrite table each one maps to.
///
/// Taken from `lib/` and `firestore.rules` on `main`. This is not a console export.
enum BackupSyncShape { topLevel, subcollection, skipped }

/// One collection or subcollection in the backup inventory.
class const BackupCollection({
  required final String key,
  required final String firestorePath,
  required final String tableId,
  required final BackupSyncShape shape,
  required final String dartSource,
  required final String why,
  required final String idStrategy,
  final String? parentCollection,
  final String? subcollectionId,
  final bool memberContent = false,
  final bool sensitive = false,
}) {
  /// Top-level document path. Subcollections must supply `sourcePath` instead.
  String childPath(String id) {
    if (shape != BackupSyncShape.topLevel) {
      throw FormatException(
        '$key needs a sourcePath because it is not a top-level collection',
      );
    }
    return '$key/$id';
  }

  Map<String, Object?> toJson() => {
    'key': key,
    'firestorePath': firestorePath,
    'tableId': tableId,
    'shape': shape.name,
    'idStrategy': idStrategy,
    'dartSource': dartSource,
    'why': why,
    'memberContent': memberContent,
    'sensitive': sensitive,
    if (parentCollection != null) 'parentCollection': parentCollection,
    if (subcollectionId != null) 'subcollectionId': subcollectionId,
  };
}

const docIdOrHash = 'doc-id-or-hash';
const pathHash = 'path-hash';
const notSynced = 'none';

/// Appwrite row ids are at most 36 characters and match `^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$`.
///
/// `doc-id-or-hash`: use the Firestore document id when it already fits.
/// Otherwise `b` plus 32 hex chars of SHA-256(`sourcePath`).
/// `path-hash`: always hash the full path. The same child id can exist under
/// two parents (`saved_posts/{postId}`, `notification_settings/push`).
/// `sourcePath` and `sourceId` are stored on every row so restore does not
/// depend on reversing the hash.
const List<BackupCollection> backupCollections = [
  BackupCollection(
    key: 'users',
    firestorePath: 'users/{uid}',
    tableId: 'backup_users',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/profile/data/member_directory_store.dart, '
        'lib/src/features/profile/data/profile_storage_service.dart, '
        'lib/src/features/account_deletion/data/account_deletion_sinks.dart',
    why:
        'Directory profile, bio, and soft-delete flags. Rules forbid email and '
        'push tokens on this document. Mention fallbacks may add outboundNotices.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'reflections',
    firestorePath: 'reflections/{postId}',
    tableId: 'backup_reflections',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/reflections/data/appwrite_post_repository.dart',
    why:
        'Production reflection feed. New ids look like post-<millis>. This table '
        'is not the disabled product table reflection_posts.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'reflections_dev',
    firestorePath: 'reflections_dev/{postId}',
    tableId: 'backup_reflections_dev',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/reflections/data/appwrite_post_repository.dart',
    why: 'Dev-flavor reflections. Kept off the production backup table.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'direct_messages',
    firestorePath: 'direct_messages/{messageId}',
    tableId: 'backup_direct_messages',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource: 'lib/src/features/messages/data/direct_message_mailbox.dart',
    why:
        'Full Firestore message documents. The live function dm-mirror still '
        'writes the narrower table direct_messages. This CLI does not touch that table.',
    memberContent: true,
    sensitive: true,
  ),
  BackupCollection(
    key: 'comments',
    firestorePath: 'comments/{commentId}',
    tableId: 'backup_comments',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/reflections/data/local_comment_repository.dart',
    why: 'Production thread comments and replies.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'comments_dev',
    firestorePath: 'comments_dev/{commentId}',
    tableId: 'backup_comments_dev',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/reflections/data/local_comment_repository.dart',
    why: 'Dev-flavor comments.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'feature_votes',
    firestorePath: 'feature_votes/{featureId}',
    tableId: 'backup_feature_votes',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource: 'lib/src/features/feedback/data/feature_voting_repository.dart',
    why:
        'Seeded roadmap votes (planned-autistic-events, planned-google-sign-in, '
        'planned-native-store-apps). Smallest safe collection to try first.',
  ),
  BackupCollection(
    key: 'member_feedback',
    firestorePath: 'member_feedback/{feedbackId}',
    tableId: 'backup_member_feedback',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource: 'lib/src/features/feedback/data/feature_voting_repository.dart',
    why:
        'Private notes. May include contactEmail and a base64 screenshot. '
        'Auto ids are created by Firestore.',
    memberContent: true,
    sensitive: true,
  ),
  BackupCollection(
    key: 'member_notifications',
    firestorePath: 'member_notifications/{notificationId}',
    tableId: 'backup_member_notifications',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/notifications/data/member_notification_store.dart',
    why: 'Cross-account bell items. Direct-message text is not copied onto the public user document.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'soft_deleted_users',
    firestorePath: 'soft_deleted_users/{userId}',
    tableId: 'backup_soft_deleted_users',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource: 'lib/src/features/admin/data/admin_banning_repository.dart',
    why:
        'Organizer bans. The document id is the member uid. Create rules reject '
        'email fields. originalData is an open map.',
    memberContent: true,
    sensitive: true,
  ),
  BackupCollection(
    key: 'self_deleted_accounts',
    firestorePath: 'self_deleted_accounts/{flavor}_{uid}',
    tableId: 'backup_self_deleted_accounts',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource:
        'lib/src/features/account_deletion/data/account_deletion_sinks.dart',
    why: 'Self-service tombstones. The id is flavor_uid. The document includes an email field.',
    memberContent: true,
    sensitive: true,
  ),
  BackupCollection(
    key: 'rules_admins',
    firestorePath: 'rules_admins/{uid}',
    tableId: 'backup_rules_admins',
    shape: BackupSyncShape.topLevel,
    idStrategy: docIdOrHash,
    dartSource: 'firestore.rules',
    why:
        'Organizer allowlist. Clients cannot read or write it. Existence of the '
        'document is the permission. Sync only with an admin token.',
    sensitive: true,
  ),
  BackupCollection(
    key: 'saved_posts',
    firestorePath: 'users/{uid}/saved_posts/{postId}',
    tableId: 'backup_saved_posts',
    shape: BackupSyncShape.subcollection,
    idStrategy: pathHash,
    parentCollection: 'users',
    subcollectionId: 'saved_posts',
    dartSource: 'lib/src/features/reflections/data/saved_posts_store.dart',
    why: 'Owner-only bookmarks. The child id is the post id, so the row id hashes the full path.',
    memberContent: true,
  ),
  BackupCollection(
    key: 'notification_settings',
    firestorePath: 'users/{uid}/notification_settings/{docId}',
    tableId: 'backup_notification_settings',
    shape: BackupSyncShape.subcollection,
    idStrategy: pathHash,
    parentCollection: 'users',
    subcollectionId: 'notification_settings',
    dartSource:
        'lib/src/features/notifications/data/push_preference_store.dart',
    why:
        'Owner-only push preference. The current document id is push and it can '
        'hold an fcmToken. Row permissions stay empty.',
    sensitive: true,
  ),
  BackupCollection(
    key: 'posts',
    firestorePath: 'posts/{postId}',
    tableId: '-',
    shape: BackupSyncShape.skipped,
    idStrategy: notSynced,
    dartSource: 'firestore.rules',
    why:
        'Rules allow posts, but the app writes reflections and reflections_dev. '
        'home_screen.dart ids such as post-<millis> go to those collections.',
  ),
  BackupCollection(
    key: 'directory_members',
    firestorePath: 'directory_members/{uid}',
    tableId: '-',
    shape: BackupSyncShape.skipped,
    idStrategy: notSynced,
    dartSource: 'firestore.rules',
    why: 'Rules allow it. MemberDirectoryStore writes users/{uid}, not this collection.',
  ),
  BackupCollection(
    key: 'auth',
    firestorePath: '(Firebase Auth, not Firestore)',
    tableId: '-',
    shape: BackupSyncShape.skipped,
    idStrategy: notSynced,
    dartSource: 'lib/src/features/auth/data/auth_repository.dart',
    why: 'Password hashes, refresh tokens, and the Auth user export are out of scope.',
  ),
  BackupCollection(
    key: 'storage',
    firestorePath: '(Cloud Storage blobs, not Firestore)',
    tableId: '-',
    shape: BackupSyncShape.skipped,
    idStrategy: notSynced,
    dartSource: 'storage.rules',
    why:
        'Avatar, post-media, feedback, and diagnostic bytes are not copied. '
        'URL fields already stored on Firestore documents travel inside those documents.',
  ),
];

BackupCollection? backupCollectionByKey(String key) {
  for (final collection in backupCollections) {
    if (collection.key == key) return collection;
  }
  return null;
}

BackupCollection requireBackupCollection(String key) {
  final collection = backupCollectionByKey(key);
  if (collection == null) {
    throw BackupCliException(
      'Unknown collection "$key". Run: dart run tool/firestore_appwrite_backup.dart inventory',
      64,
    );
  }
  return collection;
}

void requireSyncable(BackupCollection collection) {
  if (collection.shape == BackupSyncShape.skipped) {
    throw BackupCliException(
      '${collection.key} is out of scope. ${collection.why}',
      64,
    );
  }
}
