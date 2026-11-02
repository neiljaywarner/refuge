import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/lcov_summary.dart' as lcov;

void main() {
  test('parseLcov counts hit lines and soft-launch slices', () {
    const sample = '''
SF:lib/src/features/auth/presentation/auth_gate.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/src/home_screen.dart
DA:10,2
DA:11,0
DA:12,0
end_of_record
SF:lib/src/features/feedback/data/member_feedback_bridge.dart
DA:3,1
end_of_record
''';
    final report = lcov.parseLcov(sample);
    expect(report.files, hasLength(3));
    expect(report.hit, 3);
    expect(report.found, 6);
    expect(report.percent, closeTo(50, 0.1));

    final auth = report.slice(lcov.softLaunchSlices['auth']!);
    expect(auth.hit, 1);
    expect(auth.found, 2);

    final home = report.slice(lcov.softLaunchSlices['home']!);
    expect(home.found, 3);
    expect(home.hit, 1);

    final text = lcov.formatLcovReport(report);
    expect(text, contains('50.0%'));
    expect(text, contains('auth: 50.0%'));
    expect(text, contains('home: 33.3%'));
    expect(text, contains('spaces: not loaded'));
  });

  test('the summary command prints the report for a fixture file', () {
    final file = File('${Directory.systemTemp.path}/belong_lcov_summary.lcov');
    file.writeAsStringSync(
      'SF:lib/src/features/auth/domain/auth_access_policy.dart\nDA:1,1\nDA:2,1\n',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final result = Process.runSync('dart', ['run', 'tool/lcov_summary.dart', '--file', file.path]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('100.0%'));
    expect(result.stdout, contains('auth: 100.0%'));
  });

  test('coverage manifest lists the soft-launch additions', () {
    final manifest = File('tool/ci_widget_test_manifest.txt').readAsStringSync();
    expect(manifest, contains('test/features/feedback/appwrite_feedback_forward_nock_test.dart'));
    expect(manifest, contains('test/features/reflections/appwrite_tablesdb_nock_test.dart'));
    expect(
      manifest,
      contains('test/features/soft_launch/soft_launch_critical_path_patrol_test.dart'),
    );
    expect(
      manifest,
      contains('test/features/fellowship_spaces/spaces_links_directory_widget_test.dart'),
    );
    expect(manifest, contains('test/features/auth/soft_verify_banner_widget_test.dart'));
    expect(manifest, contains('test/features/auth/firebase_auth_repository_mocktail_test.dart'));
  });
}
