import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the session-audit wiki states the pause deadline and prune recovery', () {
    final text = File('docs/wiki/Appwrite-Free-Tier-Inactivity-and-Session-Audit.md')
        .readAsStringSync();
    final runbook = text.split('### Runbook').last;

    expect(text, contains('90 days'));
    expect(text, contains('https://appwrite.io/changelog/entry/2026-06-29'));
    expect(text, contains('upgrade the organization to a paid plan'));
    expect(text, isNot(contains('Check the week row, then rerun')));
    expect(text, contains('Do not run `--apply` again until that row is reconciled'));
    expect(text, contains('subtract the leftover row'));
    expect(runbook, contains('.env.session-audit-prune'));
    expect(runbook, isNot(contains('.env.session-audit\n')));
    expect(text, contains('. ./.env.session-audit\n'));
  });
}
