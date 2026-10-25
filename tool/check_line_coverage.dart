import 'dart:io';

/// Fails when LCOV line coverage is below [--min] (default 40).
///
/// ```bash
/// dart run tool/check_line_coverage.dart --min 40
/// ```
void main(List<String> args) {
  var min = 40.0;
  var path = 'coverage/lcov.info';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--min' && i + 1 < args.length) {
      min = double.parse(args[++i]);
    } else if (arg == '--file' && i + 1 < args.length) {
      path = args[++i];
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln(
        'dart run tool/check_line_coverage.dart [--min 40] [--file coverage/lcov.info]',
      );
      return;
    } else {
      stderr.writeln('Unknown argument: $arg');
      exit(64);
    }
  }

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('No coverage file at $path');
    exit(1);
  }

  var hit = 0;
  var found = 0;
  for (final line in file.readAsLinesSync()) {
    if (!line.startsWith('DA:')) continue;
    found++;
    final count = int.tryParse(line.split(',').last) ?? 0;
    if (count > 0) hit++;
  }
  if (found == 0) {
    stderr.writeln('Coverage file has no line records.');
    exit(1);
  }

  final percent = hit * 100 / found;
  stdout.writeln(
    'Line coverage ${percent.toStringAsFixed(1)}% ($hit/$found). '
    'Floor ${min.toStringAsFixed(0)}%.',
  );
  if (percent + 1e-9 < min) {
    stderr.writeln('Coverage is below the floor.');
    exit(1);
  }
}
