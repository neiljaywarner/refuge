// Summarize and prune Appwrite `client_session_audits` rows.
//
// Keeps at most 2000 raw rows and at most 8 weeks (56 days), whichever
// comes first. Rows that will be deleted are folded into
// `client_session_weekly_summaries` first.
//
// This is not an Appwrite Function. Free projects allow 2 functions.
// dm-push and dm-mirror are the live ones. A schedule would not run while
// the project is paused. Run it weekly, or when the raw count passes 1600.
//
//   export APPWRITE_API_KEY='...'   # server key, rows read + write. Do not commit.
//   dart run tool/prune_client_session_audits.dart
//   dart run tool/prune_client_session_audits.dart --apply
//   dart run tool/prune_client_session_audits.dart --example
//
// Default is a dry run. --apply writes summaries, then deletes raw rows.

import 'dart:convert';
import 'dart:io';

import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_retention.dart';

const _help = '''
Summarize and prune client_session_audits.

  dart run tool/prune_client_session_audits.dart [--apply] [--now=<ISO-8601>]
  dart run tool/prune_client_session_audits.dart --example

Reads APPWRITE_API_KEY from the environment. Endpoint, project, and database
come from AppwriteConfig (override with APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID,
and APPWRITE_DATABASE_ID dart-defines when you compile the script).

Without --apply, prints the plan and does not write. --example uses synthetic
rows and does not call Appwrite.
''';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    exit(0);
  }
  if (args.contains('--example')) {
    stdout.writeln(describeSessionRetention(_exampleDecision()));
    exit(0);
  }

  final now = _readNow(args) ?? DateTime.now().toUtc();
  final apiKey = Platform.environment['APPWRITE_API_KEY']?.trim() ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln(
      'Missing APPWRITE_API_KEY. Export a server API key that can read and '
      'write rows in belong_community_db. Do not commit the key.',
    );
    exit(2);
  }

  final config = AppwriteConfig.fromEnvironment;
  final store = AppwriteSessionAuditStore(
    endpoint: config.endpoint,
    projectId: config.projectId,
    databaseId: config.databaseId,
    apiKey: apiKey,
  );

  try {
    final rows = await store.listRawSessions();
    final decision = planSessionAuditRetention(rows: rows, now: now);
    stdout.writeln(describeSessionRetention(decision));
    if (!args.contains('--apply')) {
      if (decision.hasWork) {
        stdout.writeln('dry run. Pass --apply to write summaries and delete raw rows.');
      }
      exit(0);
    }
    if (!decision.hasWork) exit(0);

    final result = await applySessionAuditRetention(store: store, now: now);
    stdout.writeln(
      'wrote ${result.summarizedWeeks} summaries and deleted ${result.deletedRows} rows.',
    );
    if (!result.ok) {
      for (final error in result.errors) {
        stderr.writeln(error);
      }
      exit(1);
    }
  } catch (error) {
    stderr.writeln('session audit retention failed: ${_publicError(error, apiKey)}');
    exit(1);
  }
}

DateTime? _readNow(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--now=')) continue;
    final parsed = DateTime.tryParse(arg.substring('--now='.length));
    if (parsed == null) {
      stderr.writeln('--now must be an ISO-8601 timestamp.');
      exit(2);
    }
    return parsed.toUtc();
  }
  return null;
}

String _publicError(Object error, String apiKey) {
  final text = error.toString();
  if (apiKey.isEmpty) return text;
  return text.replaceAll(apiKey, '[redacted]');
}

SessionRetentionDecision _exampleDecision() {
  final now = DateTime.utc(2026, 11, 2);
  return planSessionAuditRetention(
    now: now,
    rows: [
      RawSessionAuditRow(
        id: 'old-web',
        startedAt: now.subtract(const Duration(days: 70)),
        platform: 'web',
        osName: 'web',
        appVersion: '0.9.2',
        city: 'US',
      ),
      RawSessionAuditRow(
        id: 'old-android',
        startedAt: now.subtract(const Duration(days: 69)),
        platform: 'android',
        osName: 'android',
        appVersion: '0.9.2',
        city: 'US',
      ),
      RawSessionAuditRow(
        id: 'recent',
        startedAt: now.subtract(const Duration(days: 1)),
        platform: 'ios',
        osName: 'ios',
        appVersion: '0.9.2',
      ),
    ],
  );
}

class AppwriteSessionAuditStore implements SessionAuditRetentionStore {
  AppwriteSessionAuditStore({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.apiKey,
  });

  final String endpoint;
  final String projectId;
  final String databaseId;
  final String apiKey;

  static const _pageSize = 100;
  static const _maxPages = 40;

  @override
  Future<List<RawSessionAuditRow>> listRawSessions() async {
    final rows = <RawSessionAuditRow>[];
    final seen = <String>{};
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final queries = <String>[
        jsonEncode({
          'method': 'limit',
          'values': [_pageSize],
        }),
        jsonEncode({'method': 'orderAsc', 'attribute': 'sessionStartedAt'}),
        if (cursor != null)
          jsonEncode({
            'method': 'cursorAfter',
            'values': [cursor],
          }),
      ];
      final body = await _send('GET', _rows(AppwriteConfig.clientSessionAuditsTableId, queries));
      final batch = parseRawSessionRows(body);
      if (batch.isEmpty) break;
      for (final row in batch) {
        if (seen.add(row.id)) rows.add(row);
      }
      if (batch.length < _pageSize) break;
      final next = batch.last.id;
      if (next == cursor) break;
      cursor = next;
    }
    return rows;
  }

  @override
  Future<WeeklySessionSummary?> readSummary(String rowId) async {
    try {
      final body = await _send(
        'GET',
        _row(AppwriteConfig.clientSessionWeeklySummariesTableId, rowId),
      );
      return parseWeeklySummaryRow(body);
    } on _AppwriteStatus catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> writeSummary(WeeklySessionSummary summary) async {
    final tableId = AppwriteConfig.clientSessionWeeklySummariesTableId;
    final payload = {'data': summary.toRowData()};
    try {
      await _send('POST', _rows(tableId, const []), body: {'rowId': summary.rowId, ...payload});
    } on _AppwriteStatus catch (error) {
      if (error.statusCode != 409) rethrow;
      await _send('PATCH', _row(tableId, summary.rowId), body: payload);
    }
  }

  @override
  Future<void> deleteRawSession(String rowId) async {
    try {
      await _send('DELETE', _row(AppwriteConfig.clientSessionAuditsTableId, rowId));
    } on _AppwriteStatus catch (error) {
      if (error.statusCode == 404) return;
      rethrow;
    }
  }

  Uri _rows(String tableId, List<String> queries) {
    final root = _root();
    final path = '$root/tablesdb/$databaseId/tables/$tableId/rows';
    if (queries.isEmpty) return Uri.parse(path);
    final query = queries.map((item) => 'queries[]=${Uri.encodeQueryComponent(item)}').join('&');
    return Uri.parse('$path?$query');
  }

  Uri _row(String tableId, String rowId) {
    final encoded = Uri.encodeComponent(rowId);
    return Uri.parse('${_root()}/tablesdb/$databaseId/tables/$tableId/rows/$encoded');
  }

  String _root() {
    final trimmed = endpoint.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  Future<Map<String, Object?>> _send(String method, Uri uri, {Object? body}) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('X-Appwrite-Key', apiKey);
      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(const Duration(seconds: 30));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 300) {
        throw _AppwriteStatus(response.statusCode, _clip(text, 180));
      }
      if (text.trim().isEmpty) return {};
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
      return {};
    } finally {
      client.close(force: true);
    }
  }
}

class _AppwriteStatus implements Exception {
  _AppwriteStatus(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Appwrite HTTP $statusCode $body';
}

String _clip(String value, int max) {
  final trimmed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (trimmed.length <= max) return trimmed;
  return trimmed.substring(0, max);
}
