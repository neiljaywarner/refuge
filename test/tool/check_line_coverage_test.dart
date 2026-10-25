import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coverage floor passes when enough lines were hit', () {
    final file = File('${Directory.systemTemp.path}/belong_coverage_ok.lcov');
    file.writeAsStringSync('DA:1,1\nDA:2,1\nDA:3,0\n');
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final result = Process.runSync('dart', [
      'run',
      'tool/check_line_coverage.dart',
      '--min',
      '40',
      '--file',
      file.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('66.7%'));
  });

  test('coverage floor fails under the threshold', () {
    final file = File('${Directory.systemTemp.path}/belong_coverage_low.lcov');
    file.writeAsStringSync('DA:1,1\nDA:2,0\nDA:3,0\nDA:4,0\n');
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final result = Process.runSync('dart', [
      'run',
      'tool/check_line_coverage.dart',
      '--min',
      '40',
      '--file',
      file.path,
    ]);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('below the floor'));
  });
}
