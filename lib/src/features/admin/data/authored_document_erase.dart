import 'package:cloud_firestore/cloud_firestore.dart';

/// Deletes documents whose author name or Firebase uid matches a ban.
///
/// Two queries, because Firestore has no OR across different fields. Callers
/// still need rules that allow each delete. This helper does not grant reads.
Future<void> deleteAuthoredDocuments({
  required CollectionReference<Map<String, dynamic>> collection,
  required String authorName,
  String? authorId,
  String nameField = 'authorName',
  String idField = 'authorId',
}) async {
  final refs = <String, DocumentReference<Map<String, dynamic>>>{};
  final name = authorName.trim();
  if (name.isNotEmpty) {
    final byName = await collection.where(nameField, isEqualTo: name).get();
    for (final doc in byName.docs) {
      refs[doc.id] = doc.reference;
    }
  }
  final uid = authorId?.trim() ?? '';
  if (uid.isNotEmpty && uid != name) {
    final byId = await collection.where(idField, isEqualTo: uid).get();
    for (final doc in byId.docs) {
      refs[doc.id] = doc.reference;
    }
  }
  for (final ref in refs.values) {
    await ref.delete();
  }
}
