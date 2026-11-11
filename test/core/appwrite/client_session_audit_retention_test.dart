import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_retention.dart';

void main() {
  final now = DateTime.utc(2026, 11, 2, 12);

  RawSessionAuditRow row({
    required String id,
    required DateTime startedAt,
    String platform = 'web',
    String osName = 'web',
    String appVersion = '0.9.2',
    String? city = 'US',
  }) => RawSessionAuditRow(
    id: id,
    startedAt: startedAt,
    platform: platform,
    osName: osName,
    appVersion: appVersion,
    city: city,
  );

  group('planSessionAuditRetention', () {
    test('summarizes rows older than 8 weeks and keeps newer rows', () {
      final edge = now.subtract(const Duration(days: sessionAuditRetentionDays));
      final decision = planSessionAuditRetention(
        now: now,
        rows: [
          row(id: 'aged', startedAt: edge.subtract(const Duration(seconds: 1))),
          row(id: 'edge', startedAt: edge),
          row(id: 'recent', startedAt: now.subtract(const Duration(days: 1)), city: null),
        ],
      );

      expect(decision.deleteRows.map((item) => item.id), ['aged']);
      expect(decision.summaries, hasLength(1));
      expect(decision.summaries.single.sessionCount, 1);
      expect(decision.summaries.single.cityCounts, {'US': 1});
      expect(decision.summaries.single.rowId, startsWith('week-'));
      expect(decision.approachingCap, isFalse);
    });

    test('deletes the oldest rows once the table passes 2000', () {
      final rows = [
        for (var index = 0; index < sessionAuditMaxRawRows + 1; index++)
          row(
            id: 'row-${index.toString().padLeft(4, '0')}',
            startedAt: now.subtract(Duration(minutes: sessionAuditMaxRawRows + 1 - index)),
          ),
      ];
      final decision = planSessionAuditRetention(now: now, rows: rows);

      expect(decision.deleteRows, hasLength(1));
      expect(decision.deleteRows.single.id, 'row-0000');
      expect(decision.approachingCap, isTrue);
      expect(decision.summaries.single.rawRowsSummarized, 1);
    });

    test('a count over 1600 with only recent rows does not delete yet', () {
      final rows = [
        for (var index = 0; index < sessionAuditEarlyReviewCount + 1; index++)
          row(
            id: 'row-$index',
            startedAt: now.subtract(Duration(minutes: index + 1)),
          ),
      ];
      final decision = planSessionAuditRetention(now: now, rows: rows);

      expect(decision.hasWork, isFalse);
      expect(decision.approachingCap, isTrue);
      expect(describeSessionRetention(decision), contains('nothing to prune'));
      expect(describeSessionRetention(decision), contains('over $sessionAuditEarlyReviewCount'));
    });
  });

  test('weekly summaries merge counts for the same week', () {
    final week = utcWeekStart(DateTime.utc(2026, 8, 3));
    final first = WeeklySessionSummary.fromRows(
      weekStart: week,
      rows: [row(id: 'a', startedAt: week.add(const Duration(hours: 1)), platform: 'web')],
    );
    final second = WeeklySessionSummary.fromRows(
      weekStart: week,
      rows: [
        row(
          id: 'b',
          startedAt: week.add(const Duration(days: 2)),
          platform: 'android',
          osName: 'android',
          city: null,
        ),
      ],
    );

    final merged = first.merge(second);
    expect(merged.sessionCount, 2);
    expect(merged.rawRowsSummarized, 2);
    expect(merged.platformCounts, {'web': 1, 'android': 1});
    expect(merged.cityCounts, {'US': 1, 'unknown': 1});
    expect(merged.rowId, first.rowId);
    expect(merged.toRowData()['platformCountsJson'], '{"android":1,"web":1}');
  });

  test('parsers read nested rows and ignore an email city', () {
    final parsed = parseRawSessionRows({
      'rows': [
        {
          r'$id': 'row-1',
          'data': {
            'sessionStartedAt': '2026-11-01T00:00:00.000Z',
            'platform': 'ios',
            'osName': 'ios',
            'appVersion': '0.9.2',
            'city': 'tester@example.com',
          },
        },
      ],
    });

    expect(parsed, hasLength(1));
    expect(parsed.single.platform, 'ios');
    expect(parsed.single.city, isNull);
    expect(parsed.single.startedAt, DateTime.utc(2026, 11, 1));

    final summary = WeeklySessionSummary.fromRows(
      weekStart: utcWeekStart(parsed.single.startedAt),
      rows: parsed,
    );
    final roundTrip = parseWeeklySummaryRow({
      'weekStart': summary.weekStart.toIso8601String(),
      'weekEnd': summary.weekEnd.toIso8601String(),
      ...summary.toRowData(),
    });
    expect(roundTrip?.sessionCount, 1);
    expect(roundTrip?.platformCounts, {'ios': 1});
    expect(roundTrip?.cityCounts, {'unknown': 1});
  });

  test('a failed summary write does not delete that week', () async {
    final store = _MemoryStore()
      ..raw = [
        row(id: 'old', startedAt: now.subtract(const Duration(days: 70))),
        row(id: 'keep', startedAt: now.subtract(const Duration(days: 2))),
      ]
      ..failWrite = true;

    final result = await applySessionAuditRetention(store: store, now: now);

    expect(result.ok, isFalse);
    expect(result.deletedRows, 0);
    expect(store.raw.map((item) => item.id), ['old', 'keep']);
    final expectedId = WeeklySessionSummary.fromRows(
      weekStart: utcWeekStart(store.raw.first.startedAt),
      rows: [store.raw.first],
    ).rowId;
    expect(store.operations, ['write $expectedId']);
  });

  test('apply writes the summary before deleting raw rows', () async {
    final store = _MemoryStore()
      ..raw = [
        row(id: 'old-1', startedAt: now.subtract(const Duration(days: 70)), platform: 'web'),
        row(
          id: 'old-2',
          startedAt: now.subtract(const Duration(days: 69)),
          platform: 'android',
          osName: 'android',
        ),
        row(id: 'keep', startedAt: now.subtract(const Duration(days: 1))),
      ];
    final agedStart = now.subtract(const Duration(days: 70));
    final existing = WeeklySessionSummary.fromRows(
      weekStart: utcWeekStart(agedStart),
      rows: [row(id: 'already', startedAt: agedStart)],
    );
    store.summaries[existing.rowId] = existing;

    final result = await applySessionAuditRetention(store: store, now: now);

    expect(result.ok, isTrue);
    expect(result.deletedRows, 2);
    expect(store.raw.map((item) => item.id), ['keep']);
    expect(store.operations.first, 'write ${existing.rowId}');
    expect(store.operations.sublist(1), ['delete old-1', 'delete old-2']);
    expect(store.summaries[existing.rowId]?.sessionCount, 3);
  });
}

class _MemoryStore implements SessionAuditRetentionStore {
  List<RawSessionAuditRow> raw = [];
  final summaries = <String, WeeklySessionSummary>{};
  final operations = <String>[];
  bool failWrite = false;

  @override
  Future<List<RawSessionAuditRow>> listRawSessions() async => raw;

  @override
  Future<WeeklySessionSummary?> readSummary(String rowId) async => summaries[rowId];

  @override
  Future<void> writeSummary(WeeklySessionSummary summary) async {
    operations.add('write ${summary.rowId}');
    if (failWrite) throw StateError('write failed');
    summaries[summary.rowId] = summary;
  }

  @override
  Future<void> deleteRawSession(String rowId) async {
    operations.add('delete $rowId');
    raw = [
      for (final item in raw)
        if (item.id != rowId) item,
    ];
  }
}
