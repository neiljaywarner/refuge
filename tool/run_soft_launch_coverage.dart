import 'dart:io';

/// Runs the CI widget/unit manifest with line coverage, then prints a
/// soft-launch slice report.
///
/// No device and no live Firebase or Appwrite. Patrol widget tests in the
/// manifest (`patrolWidgetTest`) are included. Device `patrol test` and
/// Maestro stay outside this command.
///
/// ```bash
/// dart run tool/run_soft_launch_coverage.dart
/// dart run tool/check_line_coverage.dart --min 40
/// ```
///
/// Extra arguments are appended to `flutter test` (for example a single file).
Future<void> main(List<String> args) async {
  final manifest = File('tool/ci_widget_test_manifest.txt');
  if (!manifest.existsSync()) {
    stderr.writeln('Missing ${manifest.path}');
    exit(1);
  }

  final files = [
    for (final line in manifest.readAsLinesSync())
      if (line.trim().isNotEmpty && !line.trim().startsWith('#')) line.trim(),
  ];
  if (files.isEmpty) {
    stderr.writeln('Coverage manifest has no test files.');
    exit(1);
  }

  final flutter = Platform.environment['FLUTTER_BIN'] ?? 'flutter';
  stdout.writeln('Running ${files.length} test files with --coverage');
  final test = await Process.start(flutter, [
    'test',
    '--coverage',
    '--reporter',
    'compact',
    ...files,
    ...args,
  ], mode: ProcessStartMode.inheritStdio);
  final testCode = await test.exitCode;
  if (testCode != 0) {
    exit(testCode);
  }

  final summary = await Process.start('dart', [
    'run',
    'tool/lcov_summary.dart',
    '--file',
    'coverage/lcov.info',
  ], mode: ProcessStartMode.inheritStdio);
  final summaryCode = await summary.exitCode;
  if (summaryCode != 0) exit(summaryCode);

  final floor = await Process.start('dart', [
    'run',
    'tool/check_line_coverage.dart',
    '--min',
    '40',
    '--file',
    'coverage/lcov.info',
  ], mode: ProcessStartMode.inheritStdio);
  exit(await floor.exitCode);
}
