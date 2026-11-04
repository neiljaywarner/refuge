import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public fellowship directory entry. The full email address is never stored.
class DirectoryMember {
  const DirectoryMember({
    required this.uid,
    required this.displayName,
    required this.handle,
    required this.tagline,
  });

  final String uid;
  final String displayName;

  /// Plus-tag only, such as `sampletag` from `member+sampletag@example.com`.
  final String handle;
  final String tagline;
}

/// Local-part plus-tag, lowercased. Returns null when the address has no tag.
///
/// The full address is never returned and must not be written to Firestore.
String? publicHandleFromEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return null;
  final local = email.substring(0, at);
  final plus = local.lastIndexOf('+');
  if (plus < 0 || plus >= local.length - 1) return null;
  final tag = local.substring(plus + 1).trim().toLowerCase();
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(tag)) return null;
  return tag;
}

/// Name shown in the directory and the message picker.
///
/// Firebase UI often leaves the display name empty, which the app stores as
/// "Fellowship Member". When that happens and a plus-tag exists, the tag is
/// the public name so two accounts can be told apart.
String publicDisplayName({required String displayName, required String email}) {
  final trimmed = displayName.trim();
  final handle = publicHandleFromEmail(email);
  if (handle != null && (trimmed.isEmpty || trimmed == 'Fellowship Member')) {
    return handle;
  }
  return trimmed.isEmpty ? 'Fellowship Member' : trimmed;
}

/// Checks whether a member account is eligible to be listed in public directories
/// and the direct message recipient picker (#813).
///
/// An account is eligible ONLY if:
/// 1. The account is not hidden via opt-out ([listedInDirectory] != false).
/// 2. The UID is not in [excludedUids] (banned or soft/self-deleted accounts).
/// 3. The account does not have [banned] or [softDeleted] set to true.
/// 4. The UID is not equal to [currentUserId] (if supplied).
bool isMemberEligibleForDirectory({
  required String uid,
  required Map<String, dynamic> userData,
  Set<String> excludedUids = const {},
  String? currentUserId,
}) {
  if (uid.isEmpty) return false;
  if (currentUserId != null && uid == currentUserId) return false;
  if (excludedUids.contains(uid)) return false;
  if (userData['banned'] == true || userData['softDeleted'] == true) return false;
  if (userData[MemberDirectoryStore.listedField] == false) return false;
  return true;
}

/// Signed-in members published for the message picker.
///
/// Documents live at `users/{uid}`, which production rules already allow the
/// owner to write and anyone to read. The document stores the uid, public
/// name, plus-tag handle, and tagline. The email address is never written.
class MemberDirectoryStore {
  MemberDirectoryStore({this.customFirestore});

  /// Deployed Firestore rules allow owner writes on this collection.
  static const collectionPath = 'users';

  static const listedField = 'listedInDirectory';

  final FirebaseFirestore? customFirestore;

  FirebaseFirestore? get firestore {
    if (customFirestore != null) return customFirestore;
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> publishSignedInMember({
    required String uid,
    required String displayName,
    required String email,
    String? tagline,
  }) async {
    if (uid.isEmpty || uid == 'guest') return;
    final fs = firestore;
    if (fs == null) return;
    final handle = publicHandleFromEmail(email) ?? '';
    final name = publicDisplayName(displayName: displayName, email: email);
    try {
      await fs.collection(collectionPath).doc(uid).set({
        'uid': uid,
        'displayName': name,
        'handle': handle,
        'tagline': (tagline ?? '').trim(),
        listedField: true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<List<DirectoryMember>> watchDirectoryMembers({Set<String> excludedUids = const {}}) {
    final fs = firestore;
    if (fs == null) return Stream.value(const []);
    try {
      return fs.collection(collectionPath).where(listedField, isEqualTo: true).snapshots().map((
        snapshot,
      ) {
        final members = <DirectoryMember>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final uid = (data['uid'] as String?) ?? doc.id;
          if (!isMemberEligibleForDirectory(
            uid: uid,
            userData: data,
            excludedUids: excludedUids,
          )) {
            continue;
          }
          members.add(
            DirectoryMember(
              uid: uid,
              displayName: (data['displayName'] as String?)?.trim().isNotEmpty == true
                  ? (data['displayName'] as String).trim()
                  : 'Fellowship Member',
              handle: (data['handle'] as String?)?.trim().toLowerCase() ?? '',
              tagline: (data['tagline'] as String?)?.trim() ?? '',
            ),
          );
        }
        members.sort((a, b) => a.displayName.compareTo(b.displayName));
        return members;
      });
    } catch (_) {
      return Stream.value(const []);
    }
  }
}

final memberDirectoryStoreProvider = Provider<MemberDirectoryStore>(
  (ref) => MemberDirectoryStore(),
);

final directoryMembersProvider = StreamProvider<List<DirectoryMember>>(
  (ref) => ref.watch(memberDirectoryStoreProvider).watchDirectoryMembers(),
);
