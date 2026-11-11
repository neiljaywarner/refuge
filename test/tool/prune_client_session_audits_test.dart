import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/client_session_audit_retention.dart';

import '../../tool/prune_client_session_audits.dart';

void main() {
  test('reads every page and refuses a listing that is still full at the ceiling', () async {
    final pages = [
      [_row('a'), _row('b')],
      [_row('c')],
    ];
    final rows = await collectSessionAuditPages(
      pageSize: 2,
      maxPages: 5,
      fetch: (cursor) async {
        if (cursor == null) return pages.first;
        return pages[1];
      },
    );
    expect(rows.map((row) => row.id), ['a', 'b', 'c']);

    await expectLater(
      collectSessionAuditPages(pageSize: 1, maxPages: 1, fetch: (_) async => [_row('only')]),
      throwsA(isA<SessionAuditListingTruncated>()),
    );
  });
}

RawSessionAuditRow _row(String id) => RawSessionAuditRow(
  id: id,
  startedAt: DateTime.utc(2026, 11, 2),
  platform: 'web',
  osName: 'web',
  appVersion: '0.9.2',
);
