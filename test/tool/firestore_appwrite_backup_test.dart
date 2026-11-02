import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/firestore_appwrite_backup/catalog.dart';
import '../../tool/firestore_appwrite_backup/cli.dart';
import '../../tool/firestore_appwrite_backup/codec.dart';
import '../../tool/firestore_appwrite_backup/config.dart';
import '../../tool/firestore_appwrite_backup/engine.dart';
import '../../tool/firestore_appwrite_backup/transport.dart';

void main() {
  final clock = DateTime.utc(2026, 11, 2, 2, 11);
  final config = BackupConfig.fromEnvironment(const {
    'APPWRITE_API_KEY': 'test-api-key',
    'FIRESTORE_ACCESS_TOKEN': 'test-token',
  });

  test(
    'inventory lists app collections and the paths the app does not write',
    () {
      final byKey = {
        for (final collection in backupCollections) collection.key: collection,
      };
      expect(byKey['users']!.tableId, 'backup_users');
      expect(byKey['reflections']!.tableId, 'backup_reflections');
      expect(byKey['reflections']!.tableId, isNot('reflection_posts'));
      expect(byKey['direct_messages']!.tableId, 'backup_direct_messages');
      expect(byKey['direct_messages']!.tableId, isNot('direct_messages'));
      expect(byKey['posts']!.shape, BackupSyncShape.skipped);
      expect(byKey['directory_members']!.shape, BackupSyncShape.skipped);
      expect(byKey['auth']!.shape, BackupSyncShape.skipped);
      expect(byKey['storage']!.shape, BackupSyncShape.skipped);
      expect(byKey['saved_posts']!.idStrategy, pathHash);
      expect(byKey['feature_votes']!.idStrategy, docIdOrHash);
    },
  );

  test('row ids keep a legal document id and hash everything else', () {
    expect(
      backupRowId(
        sourcePath: 'feature_votes/planned-native-store-apps',
        topLevel: true,
      ),
      'planned-native-store-apps',
    );
    final nested = 'users/uid_example/saved_posts/post-1';
    final digest = sha256
        .convert(utf8.encode(nested))
        .toString()
        .substring(0, 32);
    expect(backupRowId(sourcePath: nested, topLevel: false), 'b$digest');
    expect(
      backupRowId(sourcePath: 'soft_deleted_users/bad id', topLevel: true),
      isNot('bad id'),
    );
    expect(
      backupRowId(sourcePath: 'soft_deleted_users/bad id', topLevel: true),
      hasLength(33),
    );
  });

  test('sourceUpdatedAt prefers the Firestore document updateTime', () {
    final fields = {
      'lastVotedAt': {'stringValue': '2026-10-01T00:00:00.000Z'},
    };
    expect(
      sourceUpdatedAt(updateTime: '2026-11-01T00:00:00.000Z', fields: fields),
      '2026-11-01T00:00:00.000Z',
    );
    expect(sourceUpdatedAt(fields: fields), '2026-10-01T00:00:00.000Z');
  });

  test('dry-run sync of feature votes, users, reflections, and messages sends nothing', () async {
    final transport = _ScriptedTransport(
      (request) => throw StateError(request.url.toString()),
    );
    for (final example in _examples) {
      final report = await syncCollection(
        collection: requireBackupCollection(example.key),
        config: config,
        transport: transport,
        dryRun: true,
        mirroredAt: clock,
        inputText: jsonEncode({'documents': example.documents}),
      );
      expect(transport.requests, isEmpty);
      expect(report.tableId, example.tableId);
      expect(report.rows, hasLength(1));
      expect(report.rows.single.rowId, example.rowId);
      expect(report.rows.single.data['mirroredAt'], '2026-11-02T02:11:00.000Z');
      expect(
        report.rows.single.data['sourceUpdatedAt'],
        '2026-11-01T00:00:00.000Z',
      );
      final payload =
          jsonDecode(report.rows.single.data['payload']! as String) as Map;
      expect(
        payload['title'] ??
            payload['displayName'] ??
            payload['content'] ??
            payload['subject'],
        isNotNull,
      );
    }
  });

  test(
    'live sync upserts feature_votes with an empty permission list',
    () async {
      final transport = _ScriptedTransport(
        (_) => const BackupResponse(statusCode: 200, body: '{}'),
      );
      final report = await syncCollection(
        collection: requireBackupCollection('feature_votes'),
        config: config,
        transport: transport,
        dryRun: false,
        mirroredAt: clock,
        inputText: File('test/fixtures/backup/feature_votes.json')
            .readAsStringSync(),
      );
      expect(report.rows.single.rowId, 'planned-native-store-apps');
      expect(transport.requests, hasLength(1));
      final request = transport.requests.single;
      expect(request.method, 'PUT');
      expect(
        request.url.path,
        contains('/tables/backup_feature_votes/rows/planned-native-store-apps'),
      );
      expect(request.headers['X-Appwrite-Key'], 'test-api-key');
      final body = jsonDecode(request.body!) as Map<String, Object?>;
      expect(body['permissions'], isEmpty);
      expect(body.toString(), isNot(contains('test-api-key')));
      final data = body['data']! as Map<String, Object?>;
      final payload = jsonDecode(data['payload']! as String) as Map;
      expect(payload['votes'], {'integerValue': '2'});
    },
  );

  test(
    '--since skips an older document and still copies one with no time',
    () async {
      final transport = _ScriptedTransport(
        (_) => const BackupResponse(statusCode: 200, body: '{}'),
      );
      final report = await syncCollection(
        collection: requireBackupCollection('feature_votes'),
        config: config,
        transport: transport,
        dryRun: true,
        mirroredAt: clock,
        since: DateTime.utc(2026, 11, 1),
        inputText: jsonEncode({
          'documents': [
            {
              'id': 'planned-google-sign-in',
              'updateTime': '2026-10-01T00:00:00.000Z',
              'data': {'votes': 1},
            },
            {
              'id': 'planned-autistic-events',
              'data': {'votes': 0},
            },
          ],
        }),
      );
      expect(report.rows.map((row) => row.rowId), ['planned-autistic-events']);
      expect(report.skipped.single.reason, 'older than --since');
    },
  );

  test('a live list walks pages and then each parent saved_posts subcollection', () async {
    final transport = _ScriptedTransport((request) {
      final path = request.url.path;
      if (path.endsWith('/documents/users')) {
        final token = request.url.queryParameters['pageToken'];
        if (token == null) {
          return const BackupResponse(
            statusCode: 200,
            body: '{"documents":[{"name":"projects/belongonthespectrum/databases/(default)/documents/users/uid_a","updateTime":"2026-11-01T00:00:00.000Z","fields":{"displayName":{"stringValue":"Fellow Member"}}}],"nextPageToken":"page-2"}',
          );
        }
        return const BackupResponse(
          statusCode: 200,
          body: '{"documents":[{"name":"projects/belongonthespectrum/databases/(default)/documents/users/uid_b","fields":{"displayName":{"stringValue":"David M."}}}]}',
        );
      }
      expect(path, contains('/saved_posts'));
      final owner = path.contains('uid_a') ? 'uid_a' : 'uid_b';
      return BackupResponse(
        statusCode: 200,
        body:
            '{"documents":[{"name":"projects/belongonthespectrum/databases/(default)/documents/users/$owner/saved_posts/post-1","fields":{"id":{"stringValue":"post-1"}}}]}',
      );
    });
    final report = await syncCollection(
      collection: requireBackupCollection('saved_posts'),
      config: config,
      transport: transport,
      dryRun: true,
      mirroredAt: clock,
    );
    expect(
      transport.requests.where((request) => request.method == 'PUT'),
      isEmpty,
    );
    expect(report.rows, hasLength(2));
    expect(report.rows.map((row) => row.rowId).toSet(), hasLength(2));
    expect(
      report.rows.first.data['sourcePath'],
      'users/uid_a/saved_posts/post-1',
    );
  });

  test('restore dry-run rebuilds the typed Firestore fields', () async {
    final transport = _ScriptedTransport(
      (request) => throw StateError(request.method),
    );
    final synced = await syncCollection(
      collection: requireBackupCollection('feature_votes'),
      config: config,
      transport: transport,
      dryRun: true,
      mirroredAt: clock,
      inputText: File('test/fixtures/backup/feature_votes.json')
          .readAsStringSync(),
    );
    final report = await restoreCollection(
      collection: requireBackupCollection('feature_votes'),
      config: config,
      transport: transport,
      dryRun: true,
      inputText: jsonEncode(synced.toJson(includeRows: true)),
    );
    expect(
      report.patches.single.sourcePath,
      'feature_votes/planned-native-store-apps',
    );
    expect(report.patches.single.fields['votes'], {'integerValue': '2'});
  });

  test(
    'restore --write patches Firestore and recreates an empty allowlist doc',
    () async {
      final transport = _ScriptedTransport(
        (_) => const BackupResponse(statusCode: 200, body: '{}'),
      );
      await restoreCollection(
        collection: requireBackupCollection('feature_votes'),
        config: config,
        transport: transport,
        dryRun: false,
        inputText: jsonEncode({
          'rows': [
            {
              'data': {
                'sourcePath': 'feature_votes/planned-native-store-apps',
                'payload': jsonEncode({
                  'votes': {'integerValue': '2'},
                }),
              },
            },
          ],
        }),
      );
      final patch = transport.requests.single;
      expect(patch.method, 'PATCH');
      expect(
        patch.url.toString(),
        contains('documents/feature_votes/planned-native-store-apps'),
      );
      expect(patch.url.queryParametersAll['updateMask.fieldPaths'], ['votes']);
      expect(patch.headers['Authorization'], 'Bearer test-token');

      transport.requests.clear();
      await restoreCollection(
        collection: requireBackupCollection('rules_admins'),
        config: config,
        transport: transport,
        dryRun: false,
        inputText: jsonEncode({
          'rows': [
            {
              'data': {
                'sourcePath': 'rules_admins/uid_example',
                'payload': '{}',
              },
            },
          ],
        }),
      );
      expect(transport.requests.single.method, 'POST');
      expect(
        transport.requests.single.url.queryParameters['documentId'],
        'uid_example',
      );
    },
  );

  test(
    'provision treats an existing table as success and never grants guests',
    () async {
      final transport = _ScriptedTransport((request) {
        if (request.url.path.endsWith('/tables')) {
          return const BackupResponse(statusCode: 409, body: 'exists');
        }
        return const BackupResponse(statusCode: 202, body: '{}');
      });
      await provisionCollection(
        collection: requireBackupCollection('users'),
        config: config,
        transport: transport,
      );
      expect(transport.requests, hasLength(6));
      final table =
          jsonDecode(transport.requests.first.body!) as Map<String, Object?>;
      expect(table['permissions'], isEmpty);
      expect(table['rowSecurity'], isTrue);
      expect(transport.requests.last.url.path, endsWith('/columns/longtext'));
    },
  );

  test('CLI dry-run, usage, missing key, and repo output guard', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    final fixture = 'test/fixtures/backup/feature_votes.json';
    final code = await runFirestoreAppwriteBackup(
      [
        'sync',
        '--collection',
        'feature_votes',
        '--dry-run',
        '--input',
        fixture,
      ],
      stdoutSink: out,
      stderrSink: err,
      environment: const {},
    );
    expect(code, 0);
    expect(out.toString(), contains('backup_feature_votes'));
    expect(err.toString(), contains('dry-run'));

    expect(
      await runFirestoreAppwriteBackup(
        ['sync', '--collection', 'posts', '--dry-run', '--input', fixture],
        stdoutSink: StringBuffer(),
        stderrSink: StringBuffer(),
        environment: const {},
      ),
      64,
    );
    expect(
      await runFirestoreAppwriteBackup(
        ['sync', '--collection', 'users', '--input', fixture],
        stdoutSink: StringBuffer(),
        stderrSink: StringBuffer(),
        environment: const {},
      ),
      64,
    );
    expect(
      await runFirestoreAppwriteBackup(
        ['sync', '--collection', 'users', '--write', '--input', fixture],
        stdoutSink: StringBuffer(),
        stderrSink: StringBuffer(),
        environment: const {},
      ),
      78,
    );

    final repo = await Directory.systemTemp.createTemp('backup-repo-');
    final inside = await runFirestoreAppwriteBackup(
      [
        'sync',
        '--collection',
        'feature_votes',
        '--dry-run',
        '--input',
        fixture,
        '--output',
        'inside.json',
      ],
      stdoutSink: StringBuffer(),
      stderrSink: StringBuffer(),
      environment: const {},
      workingDirectory: repo.path,
    );
    expect(inside, 78);

    final outside = File(
      '${Directory.systemTemp.path}/backup-out-${clock.microsecondsSinceEpoch}.json',
    );
    final written = await runFirestoreAppwriteBackup(
      [
        'sync',
        '--collection',
        'feature_votes',
        '--dry-run',
        '--input',
        fixture,
        '--output',
        outside.path,
      ],
      stdoutSink: StringBuffer(),
      stderrSink: StringBuffer(),
      environment: const {},
      workingDirectory: repo.path,
    );
    expect(written, 0);
    expect(outside.readAsStringSync(), contains('planned-native-store-apps'));
    await outside.delete();
    await repo.delete(recursive: true);
  });
}

class _Example {
  const _Example({
    required this.key,
    required this.tableId,
    required this.rowId,
    required this.documents,
  });

  final String key;
  final String tableId;
  final String rowId;
  final List<Map<String, Object?>> documents;
}

const _examples = [
  _Example(
    key: 'feature_votes',
    tableId: 'backup_feature_votes',
    rowId: 'planned-native-store-apps',
    documents: [
      {
        'id': 'planned-native-store-apps',
        'updateTime': '2026-11-01T00:00:00.000Z',
        'data': {
          'title': 'Native iOS App Store and Google Play Apps',
          'votes': 2,
        },
      },
    ],
  ),
  _Example(
    key: 'users',
    tableId: 'backup_users',
    rowId: 'uid_example',
    documents: [
      {
        'id': 'uid_example',
        'updateTime': '2026-11-01T00:00:00.000Z',
        'data': {'displayName': 'Fellow Member', 'listedInDirectory': true},
      },
    ],
  ),
  _Example(
    key: 'reflections',
    tableId: 'backup_reflections',
    rowId: 'post-1730000000000',
    documents: [
      {
        'id': 'post-1730000000000',
        'updateTime': '2026-11-01T00:00:00.000Z',
        'data': {
          'content': 'A short synthetic reflection.',
          'authorName': 'Fellow Member',
        },
      },
    ],
  ),
  _Example(
    key: 'direct_messages',
    tableId: 'backup_direct_messages',
    rowId: 'message_example',
    documents: [
      {
        'id': 'message_example',
        'updateTime': '2026-11-01T00:00:00.000Z',
        'data': {
          'subject': 'Hello',
          'content': 'Synthetic message text.',
          'senderId': 'uid_example',
        },
      },
    ],
  ),
];

class _ScriptedTransport implements BackupTransport {
  _ScriptedTransport(this.handler);

  final BackupResponse Function(BackupRequest request) handler;
  final requests = <BackupRequest>[];

  @override
  Future<BackupResponse> send(BackupRequest request) async {
    requests.add(request);
    return handler(request);
  }
}
