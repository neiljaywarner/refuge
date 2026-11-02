import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'catalog.dart';

/// Appwrite custom ids: max 36 chars, cannot start with a special character.
final RegExp appwriteIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$');

bool isAppwriteRowId(String value) => appwriteIdPattern.hasMatch(value);

/// Row id for one Firestore document.
///
/// Top-level collections keep the Firestore document id when it is already a
/// legal Appwrite id. Every other path uses `b` plus 32 hex chars of
/// SHA-256(sourcePath), which fits in 36 characters and does not collide when
/// two parents share a child id.
String backupRowId({required String sourcePath, required bool topLevel}) {
  final sourceId = sourceIdOf(sourcePath);
  if (topLevel && isAppwriteRowId(sourceId)) return sourceId;
  final digest = sha256.convert(utf8.encode(sourcePath));
  return 'b${digest.toString().substring(0, 32)}';
}

String sourceIdOf(String sourcePath) {
  final slash = sourcePath.lastIndexOf('/');
  return slash < 0 ? sourcePath : sourcePath.substring(slash + 1);
}

/// One Firestore document, fields kept in the REST typed shape so restore can
/// write them back without guessing integer vs string.
class const FirestoreDocument({
  required final String sourcePath,
  required final Map<String, Object?> fields,
  final String? updateTime,
}) {
  String get sourceId => sourceIdOf(sourcePath);
}

const List<String> sourceTimeKeys = [
  'updatedAt',
  'lastVotedAt',
  'submittedAt',
  'sentAt',
  'timestamp',
  'createdAt',
  'savedAt',
  'deletedAt',
  'bannedAt',
  'restoredAt',
];

/// Prefer the document `updateTime`. Fall back to a field the app actually writes.
String? sourceUpdatedAt({
  String? updateTime,
  required Map<String, Object?> fields,
}) {
  if (updateTime != null && updateTime.isNotEmpty) return updateTime;
  for (final key in sourceTimeKeys) {
    final iso = isoFromFirestoreValue(fields[key]);
    if (iso != null) return iso;
  }
  return null;
}

String? isoFromFirestoreValue(Object? value) {
  if (value is! Map) return null;
  final timestamp = value['timestampValue'];
  if (timestamp is String && timestamp.isNotEmpty) return timestamp;
  final stringValue = value['stringValue'];
  if (stringValue is String && stringValue.isNotEmpty) return stringValue;
  final integerValue = value['integerValue'];
  if (integerValue is String) {
    final millis = int.tryParse(integerValue);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        millis,
        isUtc: true,
      ).toIso8601String();
    }
  }
  return null;
}

Map<String, Object?> stringKeyed(Object? value) {
  if (value is! Map) throw const FormatException('Expected a JSON object');
  return {
    for (final entry in value.entries)
      entry.key.toString(): entry.value as Object?,
  };
}

FirestoreDocument documentFromRest(Map<String, Object?> json) {
  final name = json['name'];
  if (name is! String || !name.contains('/documents/')) {
    throw const FormatException('Firestore document is missing name');
  }
  final fields = json['fields'];
  final updateTime = json['updateTime'];
  return FirestoreDocument(
    sourcePath: name.split('/documents/').last,
    fields: fields is Map ? stringKeyed(fields) : const {},
    updateTime: updateTime is String ? updateTime : null,
  );
}

FirestoreDocument documentFromJson(
  Map<String, Object?> json,
  BackupCollection collection,
) {
  final fieldsRaw = json['fields'];
  final dataRaw = json['data'];
  final Map<String, Object?> fields;
  if (fieldsRaw is Map) {
    fields = stringKeyed(fieldsRaw);
  } else if (dataRaw is Map) {
    fields = encodePlainFields(stringKeyed(dataRaw));
  } else {
    throw const FormatException('Each document needs fields or data');
  }

  final sourcePath = json['sourcePath'];
  final name = json['name'];
  final id = json['id'];
  final String path;
  if (sourcePath is String && sourcePath.isNotEmpty) {
    path = sourcePath;
  } else if (name is String && name.contains('/documents/')) {
    path = name.split('/documents/').last;
  } else if (id is String && id.isNotEmpty) {
    path = collection.childPath(id);
  } else {
    throw const FormatException('Each document needs name, sourcePath, or id');
  }
  final updateTime = json['updateTime'];
  return FirestoreDocument(
    sourcePath: path,
    fields: fields,
    updateTime: updateTime is String ? updateTime : null,
  );
}

Map<String, Object?> encodePlainFields(Map<String, Object?> data) => {
  for (final entry in data.entries) entry.key: encodePlainValue(entry.value),
};

Object encodePlainValue(Object? value) => switch (value) {
  null => {'nullValue': null},
  final bool flag => {'booleanValue': flag},
  final int number => {'integerValue': '$number'},
  final double number => {'doubleValue': number},
  final String text => {'stringValue': text},
  final List<Object?> list => {
    'arrayValue': {
      'values': [for (final item in list) encodePlainValue(item)],
    },
  },
  final Map map => {
    'mapValue': {'fields': encodePlainFields(stringKeyed(map))},
  },
  _ => {'stringValue': '$value'},
};

List<FirestoreDocument> documentsFromInput(
  String jsonText,
  BackupCollection collection,
) {
  final decoded = jsonDecode(jsonText);
  final List<Object?> items;
  if (decoded is List) {
    items = decoded.cast<Object?>();
  } else if (decoded is Map && decoded['documents'] is List) {
    items = (decoded['documents'] as List).cast<Object?>();
  } else if (decoded is Map && decoded['rows'] is List) {
    throw const FormatException(
      'This file is a mirror snapshot. Pass it to restore, not sync.',
    );
  } else {
    throw const FormatException(
      'Input JSON must be a documents array or {"documents": [...]}',
    );
  }
  final documents = <FirestoreDocument>[];
  for (final item in items) {
    if (item is! Map) {
      throw const FormatException('Each document must be an object');
    }
    documents.add(documentFromJson(stringKeyed(item), collection));
  }
  return documents;
}

/// Reject path segments that could escape the Firestore documents prefix.
String encodeFirestorePath(String sourcePath) {
  final segments = sourcePath.split('/');
  if (segments.isEmpty ||
      segments.any(
        (segment) => segment.isEmpty || segment == '.' || segment == '..',
      )) {
    throw FormatException('Unsafe sourcePath "$sourcePath"');
  }
  return segments.map(Uri.encodeComponent).join('/');
}

Map<String, Object?> fieldsFromPayload(Object? payload) {
  if (payload is String) {
    final decoded = jsonDecode(payload);
    if (decoded is Map) return stringKeyed(decoded);
    throw const FormatException('payload was not a JSON object');
  }
  if (payload is Map) return stringKeyed(payload);
  throw const FormatException('row is missing payload');
}
