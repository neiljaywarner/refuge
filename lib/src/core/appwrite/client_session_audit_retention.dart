import 'dart:convert';

/// Raw `client_session_audits` rows kept until this count or [sessionAuditRetentionDays].
const sessionAuditMaxRawRows = 2000;

/// Run the retention tool when the raw table passes this count, before the cap.
const sessionAuditEarlyReviewCount = 1600;

/// Eight weeks. Rows older than this are summarized, then deleted.
const sessionAuditRetentionDays = 56;

/// One raw session row the retention tool is allowed to read.
class RawSessionAuditRow({
  required final String id,
  required final DateTime startedAt,
  required final String platform,
  required final String osName,
  required final String appVersion,
  final String? city,
});

/// Monday 00:00 UTC of the week that contains [instant].
DateTime utcWeekStart(DateTime instant) {
  final utc = instant.toUtc();
  final midnight = DateTime.utc(utc.year, utc.month, utc.day);
  return midnight.subtract(Duration(days: midnight.weekday - 1));
}

/// The following Monday 00:00 UTC.
DateTime utcWeekEnd(DateTime weekStart) => weekStart.toUtc().add(const Duration(days: 7));

/// Counts for one ISO week in `client_session_weekly_summaries`.
class WeeklySessionSummary({
  required final DateTime weekStart,
  required final DateTime weekEnd,
  required final int sessionCount,
  required final Map<String, int> platformCounts,
  required final Map<String, int> osCounts,
  required final Map<String, int> appVersionCounts,
  required final Map<String, int> cityCounts,
  required final int rawRowsSummarized,
}) {
  String get rowId {
    final start = weekStart.toUtc();
    final year = start.year.toString().padLeft(4, '0');
    final month = start.month.toString().padLeft(2, '0');
    final day = start.day.toString().padLeft(2, '0');
    return 'week-$year-$month-$day';
  }

  bool containsInstant(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(weekStart.toUtc()) && utc.isBefore(weekEnd.toUtc());
  }

  WeeklySessionSummary merge(WeeklySessionSummary incoming) => WeeklySessionSummary(
    weekStart: weekStart,
    weekEnd: weekEnd,
    sessionCount: sessionCount + incoming.sessionCount,
    platformCounts: _addCounts(platformCounts, incoming.platformCounts),
    osCounts: _addCounts(osCounts, incoming.osCounts),
    appVersionCounts: _addCounts(appVersionCounts, incoming.appVersionCounts),
    cityCounts: _addCounts(cityCounts, incoming.cityCounts),
    rawRowsSummarized: rawRowsSummarized + incoming.rawRowsSummarized,
  );

  Map<String, Object> toRowData() => {
    'weekStart': weekStart.toUtc().toIso8601String(),
    'weekEnd': weekEnd.toUtc().toIso8601String(),
    'sessionCount': sessionCount,
    'platformCountsJson': jsonEncode(_sorted(platformCounts)),
    'osCountsJson': jsonEncode(_sorted(osCounts)),
    'appVersionCountsJson': jsonEncode(_sorted(appVersionCounts)),
    'cityCountsJson': jsonEncode(_sorted(cityCounts)),
    'rawRowsSummarized': rawRowsSummarized,
  };

  static WeeklySessionSummary fromRows({
    required DateTime weekStart,
    required List<RawSessionAuditRow> rows,
  }) {
    final platforms = <String, int>{};
    final osNames = <String, int>{};
    final versions = <String, int>{};
    final cities = <String, int>{};
    for (final row in rows) {
      _bump(platforms, row.platform);
      _bump(osNames, row.osName);
      _bump(versions, row.appVersion);
      _bump(cities, row.city ?? 'unknown');
    }
    final start = weekStart.toUtc();
    return WeeklySessionSummary(
      weekStart: start,
      weekEnd: utcWeekEnd(start),
      sessionCount: rows.length,
      platformCounts: platforms,
      osCounts: osNames,
      appVersionCounts: versions,
      cityCounts: cities,
      rawRowsSummarized: rows.length,
    );
  }
}

/// What a retention run would summarize and delete. It does not talk to Appwrite.
class SessionRetentionDecision({
  required final int rawCount,
  required final List<RawSessionAuditRow> deleteRows,
  required final List<WeeklySessionSummary> summaries,
  required final bool approachingCap,
}) {
  bool get hasWork => deleteRows.isNotEmpty;
}

SessionRetentionDecision planSessionAuditRetention({
  required List<RawSessionAuditRow> rows,
  required DateTime now,
}) {
  final cutoff = now.toUtc().subtract(const Duration(days: sessionAuditRetentionDays));
  final sorted = [...rows]
    ..sort((a, b) {
      final byTime = a.startedAt.compareTo(b.startedAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
  final doomed = <String>{};
  for (final row in sorted) {
    if (row.startedAt.toUtc().isBefore(cutoff)) doomed.add(row.id);
  }
  final survivors = [
    for (final row in sorted)
      if (!doomed.contains(row.id)) row,
  ];
  if (survivors.length > sessionAuditMaxRawRows) {
    final excess = survivors.length - sessionAuditMaxRawRows;
    for (final row in survivors.take(excess)) {
      doomed.add(row.id);
    }
  }
  final deleteRows = [
    for (final row in sorted)
      if (doomed.contains(row.id)) row,
  ];
  final grouped = <DateTime, List<RawSessionAuditRow>>{};
  for (final row in deleteRows) {
    grouped.putIfAbsent(utcWeekStart(row.startedAt), () => []).add(row);
  }
  final summaries = [
    for (final entry in grouped.entries)
      WeeklySessionSummary.fromRows(weekStart: entry.key, rows: entry.value),
  ];
  return SessionRetentionDecision(
    rawCount: rows.length,
    deleteRows: deleteRows,
    summaries: summaries,
    approachingCap: rows.length > sessionAuditEarlyReviewCount,
  );
}

String describeSessionRetention(SessionRetentionDecision decision) {
  final buffer = StringBuffer()
    ..writeln('raw rows: ${decision.rawCount}')
    ..writeln('delete: ${decision.deleteRows.length}')
    ..writeln('weekly summaries: ${decision.summaries.length}')
    ..writeln('approaching cap (>$sessionAuditEarlyReviewCount): ${decision.approachingCap}');
  for (final summary in decision.summaries) {
    buffer.writeln(
      '  ${summary.rowId} sessions=${summary.sessionCount} platforms=${summary.platformCounts}',
    );
  }
  if (!decision.hasWork) {
    buffer.writeln('nothing to prune (under $sessionAuditMaxRawRows rows and within 8 weeks).');
  }
  if (decision.approachingCap && !decision.hasWork) {
    buffer.writeln(
      'count is over $sessionAuditEarlyReviewCount. '
      'Run this tool again before the table passes $sessionAuditMaxRawRows.',
    );
  }
  return buffer.toString();
}

/// Reads and writes the two session-audit tables. The CLI supplies Appwrite.
abstract class SessionAuditRetentionStore {
  Future<List<RawSessionAuditRow>> listRawSessions();

  Future<WeeklySessionSummary?> readSummary(String rowId);

  Future<void> writeSummary(WeeklySessionSummary summary);

  Future<void> deleteRawSession(String rowId);
}

class SessionAuditRetentionApplyResult({
  required final int summarizedWeeks,
  required final int deletedRows,
  required final List<String> errors,
}) {
  bool get ok => errors.isEmpty;
}

/// Summarizes each doomed week, then deletes that week's raw rows.
///
/// A failed summary write skips deletes for that week so the raw rows remain.
Future<SessionAuditRetentionApplyResult> applySessionAuditRetention({
  required SessionAuditRetentionStore store,
  required DateTime now,
}) async {
  final rows = await store.listRawSessions();
  final decision = planSessionAuditRetention(rows: rows, now: now);
  if (!decision.hasWork) {
    return SessionAuditRetentionApplyResult(summarizedWeeks: 0, deletedRows: 0, errors: const []);
  }

  var summarizedWeeks = 0;
  var deletedRows = 0;
  final errors = <String>[];
  for (final summary in decision.summaries) {
    try {
      final existing = await store.readSummary(summary.rowId);
      await store.writeSummary(existing == null ? summary : existing.merge(summary));
      summarizedWeeks += 1;
    } catch (_) {
      errors.add('summary ${summary.rowId} was not written');
      continue;
    }
    for (final row in decision.deleteRows) {
      if (!summary.containsInstant(row.startedAt)) continue;
      try {
        await store.deleteRawSession(row.id);
        deletedRows += 1;
      } catch (_) {
        errors.add('row ${row.id} was not deleted');
      }
    }
  }
  return SessionAuditRetentionApplyResult(
    summarizedWeeks: summarizedWeeks,
    deletedRows: deletedRows,
    errors: errors,
  );
}

List<RawSessionAuditRow> parseRawSessionRows(Object? body) {
  final rows = _rowList(body);
  return [for (final row in rows) ?parseRawSessionRow(row)];
}

RawSessionAuditRow? parseRawSessionRow(Object? row) {
  if (row is! Map) return null;
  final data = _rowData(row);
  final id = row[r'$id'] ?? data[r'$id'];
  final startedRaw = data['sessionStartedAt'];
  if (id is! String || id.isEmpty || startedRaw is! String) return null;
  final startedAt = DateTime.tryParse(startedRaw);
  if (startedAt == null) return null;
  return RawSessionAuditRow(
    id: id,
    startedAt: startedAt.toUtc(),
    platform: _text(data['platform']),
    osName: _text(data['osName']),
    appVersion: _text(data['appVersion']),
    city: _optionalText(data['city']),
  );
}

WeeklySessionSummary? parseWeeklySummaryRow(Object? row) {
  if (row is! Map) return null;
  final data = _rowData(row);
  final startRaw = data['weekStart'];
  final endRaw = data['weekEnd'];
  if (startRaw is! String || endRaw is! String) return null;
  final weekStart = DateTime.tryParse(startRaw);
  final weekEnd = DateTime.tryParse(endRaw);
  if (weekStart == null || weekEnd == null) return null;
  return WeeklySessionSummary(
    weekStart: weekStart.toUtc(),
    weekEnd: weekEnd.toUtc(),
    sessionCount: _int(data['sessionCount']),
    platformCounts: _counts(data['platformCountsJson']),
    osCounts: _counts(data['osCountsJson']),
    appVersionCounts: _counts(data['appVersionCountsJson']),
    cityCounts: _counts(data['cityCountsJson']),
    rawRowsSummarized: _int(data['rawRowsSummarized']),
  );
}

Map<String, Object?> _rowData(Map<dynamic, dynamic> row) {
  final nested = row['data'];
  if (nested is Map) return Map<String, Object?>.from(nested);
  return Map<String, Object?>.from(row);
}

List<Object?> _rowList(Object? body) {
  if (body is! Map) return const [];
  final rows = body['rows'];
  if (rows is! List) return const [];
  return rows;
}

String _text(Object? value) {
  if (value is! String) return 'unknown';
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'unknown' : trimmed;
}

String? _optionalText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return null;
  return trimmed;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, int> _counts(Object? raw) {
  if (raw is! String || raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return {};
  final counts = <String, int>{};
  for (final entry in decoded.entries) {
    final key = _countKey(entry.key.toString());
    final value = entry.value;
    if (key == null || value is! num) continue;
    counts[key] = value.toInt();
  }
  return counts;
}

String? _countKey(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return null;
  if (trimmed.length <= 64) return trimmed;
  return trimmed.substring(0, 64);
}

void _bump(Map<String, int> counts, String raw) {
  final key = _countKey(raw) ?? 'unknown';
  counts[key] = (counts[key] ?? 0) + 1;
}

Map<String, int> _addCounts(Map<String, int> left, Map<String, int> right) {
  final sum = Map<String, int>.of(left);
  for (final entry in right.entries) {
    sum[entry.key] = (sum[entry.key] ?? 0) + entry.value;
  }
  return sum;
}

Map<String, int> _sorted(Map<String, int> counts) {
  final keys = counts.keys.toList()..sort();
  return {for (final key in keys) key: counts[key]!};
}
