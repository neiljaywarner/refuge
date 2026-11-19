import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Church and preview fields stored on `users/{uid}`.
///
/// Dev and prod share this collection. Flavor isolation does not apply here.
class const MemberProfileCloudFields({
  final String? displayName,
  final String? bio,
  final String? icocChurchAffiliation,
  final List<String>? comfortBadges,
  final String? avatarUrl,
  final bool? previewFeaturesEnabled,
}) {
  factory MemberProfileCloudFields.fromMap(Map<String, dynamic> data) {
    final badges = data['comfortBadges'];
    return MemberProfileCloudFields(
      displayName: data['displayName'] as String?,
      bio: data['bio'] as String?,
      icocChurchAffiliation: data['icocChurchAffiliation'] as String?,
      comfortBadges: badges is List ? badges.map((item) => item.toString()).toList() : null,
      avatarUrl: data['avatarUrl'] as String?,
      previewFeaturesEnabled: data['previewFeaturesEnabled'] as bool?,
    );
  }

  Map<String, dynamic> toMergeMap() => {
    if (displayName != null) 'displayName': displayName,
    if (bio != null) 'bio': bio,
    if (icocChurchAffiliation != null) 'icocChurchAffiliation': icocChurchAffiliation,
    if (comfortBadges != null) 'comfortBadges': comfortBadges,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (previewFeaturesEnabled != null) 'previewFeaturesEnabled': previewFeaturesEnabled,
  };
}

/// Read and merge the signed-in member document at `users/{uid}`.
abstract class MemberProfileCloudStore {
  Future<void> merge(String uid, MemberProfileCloudFields fields);

  Future<MemberProfileCloudFields?> load(String uid);
}

/// In-memory stand-in so tests can prove a reload reads the same document.
class MemoryMemberProfileCloudStore implements MemberProfileCloudStore {
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<void> merge(String uid, MemberProfileCloudFields fields) async {
    final current = documents.putIfAbsent(uid, () => <String, dynamic>{});
    current.addAll(fields.toMergeMap());
  }

  @override
  Future<MemberProfileCloudFields?> load(String uid) async {
    final data = documents[uid];
    if (data == null) return null;
    return MemberProfileCloudFields.fromMap(data);
  }
}

/// Firestore implementation. No-ops when Firebase is not initialized.
///
/// Uses the existing owner write on `users/{uid}`. No rules change.
class FirestoreMemberProfileCloudStore implements MemberProfileCloudStore {
  static const collectionPath = 'users';

  @override
  Future<void> merge(String uid, MemberProfileCloudFields fields) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final map = fields.toMergeMap();
      if (map.isEmpty) return;
      map['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(uid)
          .set(map, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<MemberProfileCloudFields?> load(String uid) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final snap = await FirebaseFirestore.instance.collection(collectionPath).doc(uid).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return MemberProfileCloudFields.fromMap(data);
    } catch (_) {
      return null;
    }
  }
}
