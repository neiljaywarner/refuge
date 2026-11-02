import 'dart:io';

/// One source file recorded in an LCOV trace.
class LcovFile {
  LcovFile(this.path);

  final String path;
  int hit = 0;
  int found = 0;

  double get percent => found == 0 ? 0 : hit * 100 / found;
}

/// Line totals parsed from `coverage/lcov.info`.
class LcovReport {
  final files = <LcovFile>[];

  int get hit => files.fold(0, (sum, file) => sum + file.hit);
  int get found => files.fold(0, (sum, file) => sum + file.found);
  double get percent => found == 0 ? 0 : hit * 100 / found;

  LcovFile slice(bool Function(String path) include) {
    final combined = LcovFile('slice');
    for (final file in files) {
      if (!include(file.path)) continue;
      combined.hit += file.hit;
      combined.found += file.found;
    }
    return combined;
  }
}

/// Parses DA records. A line counts as hit when its execution count is > 0.
LcovReport parseLcov(String text) {
  final report = LcovReport();
  LcovFile? current;
  for (final line in text.split('\n')) {
    if (line.startsWith('SF:')) {
      current = LcovFile(line.substring(3).trim());
      report.files.add(current);
    } else if (line.startsWith('DA:') && current != null) {
      current.found++;
      final count = int.tryParse(line.split(',').last) ?? 0;
      if (count > 0) current.hit++;
    }
  }
  return report;
}

/// Soft-launch areas printed after every coverage run.
final softLaunchSlices = <String, bool Function(String path)>{
  'auth': _under('lib/src/features/auth/'),
  'spaces': _under('lib/src/features/fellowship_spaces/'),
  'vote & feedback': _under('lib/src/features/feedback/'),
  'home': _isFile('lib/src/home_screen.dart'),
  'reflections': _under('lib/src/features/reflections/'),
  'appwrite': _under('lib/src/core/appwrite/'),
  'install links': _under('lib/src/features/install/'),
};

bool Function(String path) _under(String prefix) =>
    (path) => path.replaceAll('\\', '/').contains(prefix);

bool Function(String path) _isFile(String suffix) =>
    (path) => path.replaceAll('\\', '/').endsWith(suffix);

String formatLcovReport(LcovReport report) {
  final buffer = StringBuffer()
    ..writeln(
      'Line coverage ${report.percent.toStringAsFixed(1)}% '
      '(${report.hit}/${report.found}) across ${report.files.length} files.',
    )
    ..writeln('Soft-launch slices:');
  for (final entry in softLaunchSlices.entries) {
    final slice = report.slice(entry.value);
    if (slice.found == 0) {
      buffer.writeln('  ${entry.key}: not loaded');
      continue;
    }
    buffer.writeln(
      '  ${entry.key}: ${slice.percent.toStringAsFixed(1)}% '
      '(${slice.hit}/${slice.found})',
    );
  }
  return buffer.toString();
}

void main(List<String> args) {
  var path = 'coverage/lcov.info';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--file' && i + 1 < args.length) {
      path = args[++i];
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln('dart run tool/lcov_summary.dart [--file coverage/lcov.info]');
      return;
    } else if (!arg.startsWith('--') && i == 0) {
      path = arg;
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
  stdout.write(formatLcovReport(parseLcov(file.readAsStringSync())));
}
