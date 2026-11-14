import 'package:cloud_firestore/cloud_firestore.dart';

/// Private record that this member has a care reaction on a reflection.
///
/// The feed count lives on the reflection. This row only remembers the
/// member's own taps so a later tap on this device, or another one, removes
/// the reaction instead of adding a second one. Other members cannot read it.
class CareReactionMarks {
  const CareReactionMarks({required this.environment});

  final String environment;

  static const collectionId = 'care_reactions';

  /// Firestore document id for [postId] in this dev/prod partition.
  static String docId({required String environment, required String postId}) {
    final safe = postId.replaceAll('/', '_');
    return '${environment}_$safe';
  }

  DocumentReference<Map<String, dynamic>>? _ref({
    required FirebaseFirestore? firestore,
    required String accountId,
    required String postId,
  }) {
    final uid = accountId.trim();
    if (firestore == null || uid.isEmpty || uid == 'guest' || postId.trim().isEmpty) {
      return null;
    }
    return firestore
        .collection('users')
        .doc(uid)
        .collection(collectionId)
        .doc(docId(environment: environment, postId: postId));
  }

  Future<bool> contains({
    required FirebaseFirestore? firestore,
    required String accountId,
    required String postId,
    required String type,
  }) async {
    final types = await typesFor(firestore: firestore, accountId: accountId, postId: postId);
    return types.contains(type);
  }

  Future<Set<String>> typesFor({
    required FirebaseFirestore? firestore,
    required String accountId,
    required String postId,
  }) async {
    final ref = _ref(firestore: firestore, accountId: accountId, postId: postId);
    if (ref == null) return const {};
    try {
      final snap = await ref.get().timeout(const Duration(seconds: 2));
      if (!snap.exists) return const {};
      final raw = snap.data()?['types'];
      if (raw is! List) return const {};
      return {for (final item in raw) item.toString()};
    } catch (_) {
      return const {};
    }
  }

  Future<void> record({
    required FirebaseFirestore? firestore,
    required String accountId,
    required String postId,
    required String type,
    required bool active,
  }) async {
    final ref = _ref(firestore: firestore, accountId: accountId, postId: postId);
    if (ref == null || type.trim().isEmpty) return;
    final next = await typesFor(firestore: firestore, accountId: accountId, postId: postId);
    final types = Set<String>.from(next);
    if (active) {
      types.add(type);
    } else {
      types.remove(type);
    }
    try {
      if (types.isEmpty) {
        await ref.delete().timeout(const Duration(seconds: 2));
        return;
      }
      await ref.set({'types': types.toList()}).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
