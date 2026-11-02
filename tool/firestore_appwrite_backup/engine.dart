import 'dart:convert';

import 'catalog.dart';
import 'codec.dart';
import 'config.dart';
import 'errors.dart';
import 'transport.dart';

const maxPayloadChars = 1000000;
const _pageSize = 100;

class const MirrorRow({
  required final String rowId,
  required final String tableId,
  required final Map<String, Object?> data,
}) {
  Map<String, Object?> toJson() => {'rowId': rowId, 'tableId': tableId, 'data': data};
}

class const SkipNote({required final String sourcePath, required final String reason}) {
  Map<String, Object?> toJson() => {'sourcePath': sourcePath, 'reason': reason};
}

class const SyncReport({
  required final String collectionKey,
  required final String tableId,
  required final bool dryRun,
  required final List<MirrorRow> rows,
  required final List<SkipNote> skipped,
}) {
  Map<String, Object?> toJson({required bool includeRows}) => {
    'collection': collectionKey,
    'tableId': tableId,
    'dryRun': dryRun,
    'wrote': rows.length,
    'skipped': [for (final note in skipped) note.toJson()],
    if (includeRows) 'rows': [for (final row in rows) row.toJson()],
  };
}

class const FirestorePatch({
  required final String sourcePath,
  required final Map<String, Object?> fields,
}) {
  Map<String, Object?> toJson() => {'sourcePath': sourcePath, 'fields': fields};
}

class const RestoreReport({
  required final String collectionKey,
  required final bool dryRun,
  required final List<FirestorePatch> patches,
}) {
  Map<String, Object?> toJson({required bool includePatches}) => {
    'collection': collectionKey,
    'dryRun': dryRun,
    'patches': includePatches ? [for (final patch in patches) patch.toJson()] : patches.length,
  };
}

MirrorRow buildMirrorRow({
  required BackupCollection collection,
  required FirestoreDocument document,
  required DateTime mirroredAt,
}) {
  final updated = sourceUpdatedAt(updateTime: document.updateTime, fields: document.fields);
  final payload = jsonEncode(document.fields);
  return MirrorRow(
    rowId: backupRowId(
      sourcePath: document.sourcePath,
      topLevel: collection.shape == BackupSyncShape.topLevel,
    ),
    tableId: collection.tableId,
    data: {
      'sourcePath': document.sourcePath,
      'sourceId': document.sourceId,
      'sourceUpdatedAt': ?updated,
      'mirroredAt': mirroredAt.toUtc().toIso8601String(),
      'payload': payload,
    },
  );
}

bool isOlderThan(String? updated, DateTime since) {
  if (updated == null || updated.isEmpty) return false;
  final parsed = DateTime.tryParse(updated);
  if (parsed == null) return false;
  return parsed.toUtc().isBefore(since.toUtc());
}

List<BackupRequest> provisionRequests(BackupCollection collection, BackupConfig config) {
  requireSyncable(collection);
  config.requireHttps();
  final root = '${config.normalizedEndpoint}/tablesdb/${config.databaseId}/tables';
  final headers = _appwriteHeaders(config, includeKey: false);
  final table = BackupRequest(
    method: 'POST',
    url: Uri.parse(root),
    headers: headers,
    body: jsonEncode({
      'tableId': collection.tableId,
      'name': 'Backup ${collection.key}',
      'permissions': <String>[],
      'rowSecurity': true,
      'enabled': true,
    }),
  );
  BackupRequest column(String kind, Map<String, Object?> body) => BackupRequest(
    method: 'POST',
    url: Uri.parse('$root/${collection.tableId}/columns/$kind'),
    headers: headers,
    body: jsonEncode(body),
  );
  return [
    table,
    column('varchar', {'key': 'sourcePath', 'size': 768, 'required': true}),
    column('varchar', {'key': 'sourceId', 'size': 256, 'required': true}),
    column('varchar', {'key': 'sourceUpdatedAt', 'size': 64, 'required': false}),
    column('varchar', {'key': 'mirroredAt', 'size': 64, 'required': true}),
    column('longtext', {'key': 'payload', 'required': true}),
  ];
}

Future<SyncReport> syncCollection({
  required BackupCollection collection,
  required BackupConfig config,
  required BackupTransport transport,
  required bool dryRun,
  required DateTime mirroredAt,
  String? inputText,
  DateTime? since,
}) async {
  requireSyncable(collection);
  config.requireHttps();
  final documents = inputText != null
      ? documentsFromInput(inputText, collection)
      : await _fetchLive(collection, config, transport);
  final rows = <MirrorRow>[];
  final skipped = <SkipNote>[];
  for (final document in documents) {
    final row = buildMirrorRow(collection: collection, document: document, mirroredAt: mirroredAt);
    final updated = row.data['sourceUpdatedAt'] as String?;
    if (since != null && isOlderThan(updated, since)) {
      skipped.add(SkipNote(sourcePath: document.sourcePath, reason: 'older than --since'));
      continue;
    }
    final payload = row.data['payload'];
    if (payload is String && payload.length > maxPayloadChars) {
      skipped.add(
        SkipNote(
          sourcePath: document.sourcePath,
          reason: 'payload longer than $maxPayloadChars characters',
        ),
      );
      continue;
    }
    rows.add(row);
  }
  if (!dryRun) {
    _requireApiKey(config);
    for (final row in rows) {
      await _sendOk(
        transport,
        BackupRequest(
          method: 'PUT',
          url: Uri.parse(
            '${config.normalizedEndpoint}/tablesdb/${config.databaseId}/tables/'
            '${collection.tableId}/rows/${Uri.encodeComponent(row.rowId)}',
          ),
          headers: _appwriteHeaders(config, includeKey: true),
          body: jsonEncode({'data': row.data, 'permissions': <String>[]}),
        ),
        config,
        'Appwrite upsert ${row.rowId}',
      );
    }
  }
  return SyncReport(
    collectionKey: collection.key,
    tableId: collection.tableId,
    dryRun: dryRun,
    rows: rows,
    skipped: skipped,
  );
}

Future<void> provisionCollection({
  required BackupCollection collection,
  required BackupConfig config,
  required BackupTransport transport,
}) async {
  _requireApiKey(config);
  for (final request in provisionRequests(collection, config)) {
    final authed = BackupRequest(
      method: request.method,
      url: request.url,
      headers: _appwriteHeaders(config, includeKey: true),
      body: request.body,
    );
    final response = await transport.send(authed);
    if (response.statusCode == 409) continue;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = redactSecrets(response.body, config);
      final clipped = detail.length > 400 ? detail.substring(0, 400) : detail;
      throw BackupCliException('Appwrite provision failed (${response.statusCode}) $clipped', 70);
    }
  }
}

Future<RestoreReport> restoreCollection({
  required BackupCollection collection,
  required BackupConfig config,
  required BackupTransport transport,
  required bool dryRun,
  String? inputText,
}) async {
  requireSyncable(collection);
  config.requireHttps();
  final patches = inputText != null
      ? patchesFromMirrorJson(jsonDecode(inputText))
      : await _patchesFromAppwrite(collection, config, transport);
  if (!dryRun) {
    _requireFirestoreToken(config);
    for (final patch in patches) {
      await _writeFirestore(config, transport, patch);
    }
  }
  return RestoreReport(collectionKey: collection.key, dryRun: dryRun, patches: patches);
}

List<FirestorePatch> patchesFromMirrorJson(Object? decoded) {
  if (decoded is! Map || decoded['rows'] is! List) {
    throw const FormatException('Restore input must be a JSON object with a rows array.');
  }
  final patches = <FirestorePatch>[];
  for (final item in (decoded['rows'] as List).cast<Object?>()) {
    if (item is! Map) throw const FormatException('Each row must be an object');
    final row = stringKeyed(item);
    final nested = row['data'];
    final data = nested is Map ? stringKeyed(nested) : row;
    final sourcePath = data['sourcePath'];
    if (sourcePath is! String || sourcePath.isEmpty) {
      throw const FormatException('Each row needs sourcePath');
    }
    encodeFirestorePath(sourcePath);
    patches.add(FirestorePatch(sourcePath: sourcePath, fields: fieldsFromPayload(data['payload'])));
  }
  return patches;
}

Future<List<FirestoreDocument>> _fetchLive(
  BackupCollection collection,
  BackupConfig config,
  BackupTransport transport,
) async {
  _requireFirestoreToken(config);
  if (collection.shape == BackupSyncShape.topLevel) {
    return _listDocuments(config, transport, collection.key);
  }
  final parent = collection.parentCollection;
  final child = collection.subcollectionId;
  if (parent == null || child == null) {
    throw BackupCliException('${collection.key} is missing its parent path.', 70);
  }
  final parents = await _listDocuments(config, transport, parent);
  final documents = <FirestoreDocument>[];
  for (final parentDoc in parents) {
    documents.addAll(await _listDocuments(config, transport, '${parentDoc.sourcePath}/$child'));
  }
  return documents;
}

Future<List<FirestoreDocument>> _listDocuments(
  BackupConfig config,
  BackupTransport transport,
  String relativePath,
) async {
  final documents = <FirestoreDocument>[];
  String? pageToken;
  for (var page = 0; page < 10000; page++) {
    final query = <String, String>{'pageSize': '$_pageSize'};
    if (pageToken != null) query['pageToken'] = pageToken;
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${config.firestoreProjectId}'
      '/databases/(default)/documents/${encodeFirestorePath(relativePath)}',
    ).replace(queryParameters: query);
    final response = await transport.send(
      BackupRequest(
        method: 'GET',
        url: url,
        headers: {'Authorization': 'Bearer ${config.firestoreAccessToken}'},
      ),
    );
    if (response.statusCode == 404) return documents;
    if (response.statusCode != 200) {
      throw BackupCliException(
        'Firestore list $relativePath failed (${response.statusCode}). '
        'Use an admin access token. A member ID token cannot read other members\' documents.',
        70,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Firestore list was not an object');
    }
    final batch = decoded['documents'];
    if (batch is List) {
      for (final item in batch) {
        if (item is Map) documents.add(documentFromRest(stringKeyed(item)));
      }
    }
    final next = decoded['nextPageToken'];
    if (next is! String || next.isEmpty) break;
    pageToken = next;
  }
  return documents;
}

Future<List<FirestorePatch>> _patchesFromAppwrite(
  BackupCollection collection,
  BackupConfig config,
  BackupTransport transport,
) async {
  _requireApiKey(config);
  final patches = <FirestorePatch>[];
  String? cursor;
  for (var page = 0; page < 10000; page++) {
    final queries = <String>[
      jsonEncode({
        'method': 'limit',
        'values': [_pageSize],
      }),
    ];
    if (cursor != null) {
      queries.add(
        jsonEncode({
          'method': 'cursorAfter',
          'values': [cursor],
        }),
      );
    }
    final query = queries.map((item) => 'queries[]=${Uri.encodeQueryComponent(item)}').join('&');
    final url = Uri.parse(
      '${config.normalizedEndpoint}/tablesdb/${config.databaseId}/tables/${collection.tableId}/rows?$query',
    );
    final response = await _sendOk(
      transport,
      BackupRequest(method: 'GET', url: url, headers: _appwriteHeaders(config, includeKey: true)),
      config,
      'Appwrite list ${collection.tableId}',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['rows'] is! List) {
      throw const FormatException('Appwrite list was not a rows object');
    }
    final rows = (decoded['rows'] as List).cast<Object?>();
    if (rows.isEmpty) break;
    String? lastId;
    for (final item in rows) {
      if (item is! Map) continue;
      final row = stringKeyed(item);
      final id = row[r'$id'];
      if (id is String) lastId = id;
      final sourcePath = row['sourcePath'];
      if (sourcePath is! String) continue;
      patches.add(
        FirestorePatch(sourcePath: sourcePath, fields: fieldsFromPayload(row['payload'])),
      );
    }
    if (rows.length < _pageSize || lastId == null) break;
    cursor = lastId;
  }
  return patches;
}

Future<void> _writeFirestore(
  BackupConfig config,
  BackupTransport transport,
  FirestorePatch patch,
) async {
  final encodedPath = encodeFirestorePath(patch.sourcePath);
  final root =
      'https://firestore.googleapis.com/v1/projects/${config.firestoreProjectId}'
      '/databases/(default)/documents/$encodedPath';
  if (patch.fields.isEmpty) {
    final parentSlash = encodedPath.lastIndexOf('/');
    final parent = parentSlash < 0 ? '' : encodedPath.substring(0, parentSlash);
    final docId = parentSlash < 0 ? encodedPath : encodedPath.substring(parentSlash + 1);
    final createUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${config.firestoreProjectId}'
      '/databases/(default)/documents/$parent?documentId=$docId',
    );
    final response = await transport.send(
      BackupRequest(
        method: 'POST',
        url: createUrl,
        headers: {
          'Authorization': 'Bearer ${config.firestoreAccessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fields': <String, Object?>{}}),
      ),
    );
    if (response.statusCode == 409 || (response.statusCode >= 200 && response.statusCode < 300)) {
      return;
    }
    throw BackupCliException(
      'Firestore create ${patch.sourcePath} failed (${response.statusCode}).',
      70,
    );
  }
  final mask = patch.fields.keys
      .map((key) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(key)}')
      .join('&');
  final response = await transport.send(
    BackupRequest(
      method: 'PATCH',
      url: Uri.parse('$root?$mask'),
      headers: {
        'Authorization': 'Bearer ${config.firestoreAccessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': patch.fields}),
    ),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw BackupCliException(
      'Firestore restore ${patch.sourcePath} failed (${response.statusCode}).',
      70,
    );
  }
}

Map<String, String> _appwriteHeaders(BackupConfig config, {required bool includeKey}) => {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': config.projectId,
  'X-Appwrite-Response-Format': '1.8.0',
  if (includeKey && config.apiKey != null) 'X-Appwrite-Key': config.apiKey!,
};

void _requireApiKey(BackupConfig config) {
  if (!config.hasApiKey) {
    throw BackupCliException(
      'APPWRITE_API_KEY is not set. Put the key in the environment. Do not pass it as a flag.',
      78,
    );
  }
}

void _requireFirestoreToken(BackupConfig config) {
  if (!config.hasFirestoreToken) {
    throw BackupCliException(
      'FIRESTORE_ACCESS_TOKEN is not set. Obtain one with gcloud auth print-access-token '
      'from an account that can read Firestore as admin. Do not pass it as a flag.',
      78,
    );
  }
}

Future<BackupResponse> _sendOk(
  BackupTransport transport,
  BackupRequest request,
  BackupConfig config,
  String label,
) async {
  final response = await transport.send(request);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final detail = redactSecrets(response.body, config);
    final clipped = detail.length > 400 ? detail.substring(0, 400) : detail;
    throw BackupCliException('$label failed (${response.statusCode}) $clipped', 70);
  }
  return response;
}
