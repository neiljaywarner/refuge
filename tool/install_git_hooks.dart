import 'dart:io';

/// Points this clone at `.githooks` without committing machine-local git config.
///
/// ```bash
/// dart run tool/install_git_hooks.dart
/// ```
void main() {
  final root = Directory.current;
  final hooks = Directory('${root.path}/.githooks');
  if (!hooks.existsSync()) {
    stderr.writeln('No .githooks directory. Run this from the repository root.');
    exit(1);
  }
  final result = Process.runSync('git', ['config', 'core.hooksPath', '.githooks']);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }
  stdout.writeln('Git hooks path set to .githooks for this clone.');
  stdout.writeln('Pre-commit formats and analyzes staged Dart files.');
  stdout.writeln('Pre-push runs the privacy scan.');
  stdout.writeln('Set REFUGE_PRE_PUSH_TESTS=1 to also run a small Flutter test slice.');
}
