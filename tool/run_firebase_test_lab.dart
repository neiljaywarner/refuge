/// # Firebase Test Lab & Patrol Android Runner (`tool/run_firebase_test_lab.dart`)
///
/// Builds a **dev-only** debug APK pair and optionally uploads to Firebase Test
/// Lab on project `belongonthespectrum`.
///
/// Every build uses `lib/main_dev.dart`, `FLAVOR=dev`, and
/// `ENABLE_SERVERPOD=false`. Upload is refused unless `aapt dump badging`
/// reports `com.belongonthespectrum.refuge.dev` and label `[DEV] Belong on the Spectrum`.
///
/// ## Usage
/// ```bash
/// dart run tool/run_firebase_test_lab.dart --dry-run
/// dart run tool/run_firebase_test_lab.dart --build-only
/// dart run tool/run_firebase_test_lab.dart --target integration_test/patrol_hello_world_test.dart
/// ```
library;

import 'dart:io';

import 'firebase_test_lab_support.dart';

const _defaultProject = 'belongonthespectrum';
const _defaultTarget = 'integration_test/patrol_hello_world_test.dart';
const _defaultDevice =
    'model=panther,version=33,locale=en,orientation=portrait';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final dryRun = args.contains('--dry-run');
  final buildOnly = args.contains('--build-only');
  final target = _getArg(args, '--target') ?? _defaultTarget;
  final project =
      _getArg(args, '--project') ??
      Platform.environment['FIREBASE_PROJECT_ID'] ??
      _defaultProject;
  final device = _getArg(args, '--device') ?? _defaultDevice;
  final timeout = _getArg(args, '--timeout') ?? '10m';

  if (project != _defaultProject) {
    stderr.writeln(
      'Refusing run: --project must be $_defaultProject for Test Lab safety.',
    );
    exit(64);
  }

  _log('============================================================');
  _log('Belong on the Spectrum — Firebase Test Lab (dev APK only)');
  _log('============================================================');
  _log('Target Test : $target');
  _log('Project     : $project');
  _log('Device Spec : $device');
  _log('Dry Run     : $dryRun');
  _log('Build Only  : $buildOnly');
  _log('Timeout     : $timeout');
  _log('------------------------------------------------------------');

  final testFile = File(target);
  if (!testFile.existsSync()) {
    stderr.writeln('Target test file not found: $target');
    exit(64);
  }
  _log('Verified target test file: ${testFile.path}');

  final repoRoot = Directory.current.path;
  final appApk = resolveExistingApk(repoRoot, appApkRelativePaths());
  final testApk = File('$repoRoot/$androidTestApkRelativePath');

  _log('\nPhase 1: Dev debug APK assembly');
  _log('flutter ${devFlutterApkBuildArgs().join(' ')}');
  _log(
    'cd android && ./gradlew app:assembleDebugAndroidTest '
    '-Ptarget=${integrationTestGradleTarget(target)}',
  );

  if (!dryRun) {
    final flutter = await _resolveFlutterExecutable();
    if (flutter == null) {
      stderr.writeln('flutter executable not found on PATH.');
      exit(127);
    }

    _log('Running flutter build apk (dev, Serverpod off)...');
    final flutterBuild = await Process.run(
      flutter,
      devFlutterApkBuildArgs(),
      workingDirectory: repoRoot,
    );
    if (flutterBuild.exitCode != 0) {
      stderr.writeln('flutter build apk failed (${flutterBuild.exitCode}).');
      stderr.write(flutterBuild.stderr);
      stdout.write(flutterBuild.stdout);
      exit(flutterBuild.exitCode);
    }

    final androidDir = Directory('$repoRoot/android');
    if (!androidDir.existsSync()) {
      stderr.writeln('android/ directory not found.');
      exit(65);
    }

    _log('Running Gradle assembleDebugAndroidTest...');
    final gradleCmd = Platform.isWindows ? 'gradlew.bat' : './gradlew';
    final gradleProcess = await Process.run(gradleCmd, [
      'app:assembleDebugAndroidTest',
      '-Ptarget=${integrationTestGradleTarget(target)}',
    ], workingDirectory: androidDir.path);
    if (gradleProcess.exitCode != 0) {
      stderr.writeln(
        'Gradle assembleDebugAndroidTest failed (${gradleProcess.exitCode}).',
      );
      stderr.write(gradleProcess.stderr);
      stdout.write(gradleProcess.stdout);
      exit(gradleProcess.exitCode);
    }
    _log('Dev APK pair built.');
  } else {
    _log('[Dry Run] Skipped flutter and Gradle builds.');
  }

  final resolvedAppApk =
      resolveExistingApk(repoRoot, appApkRelativePaths()) ?? appApk;
  final resolvedTestApk = testApk.existsSync() ? testApk : null;

  if (resolvedAppApk == null) {
    stderr.writeln('App APK not found after build. Expected one of:');
    for (final path in appApkRelativePaths()) {
      stderr.writeln('  $path');
    }
    exit(65);
  }
  if (resolvedTestApk == null && !dryRun) {
    stderr.writeln('AndroidTest APK not found: $androidTestApkRelativePath');
    exit(65);
  }

  _log('App APK      : ${resolvedAppApk.path}');
  _log('AndroidTest  : ${resolvedTestApk?.path ?? '(dry-run placeholder)'}');

  if (!dryRun) {
    final refusal = await _devApkRefusalForFile(resolvedAppApk);
    if (refusal != null) {
      stderr.writeln(refusal);
      exit(65);
    }
    _log(
      'Verified package $devAndroidPackageId and label $devAndroidApplicationLabel.',
    );
  }

  if (buildOnly) {
    _log('Build complete (--build-only). Exiting.');
    return;
  }

  _log('\nPhase 2: Firebase Test Lab cloud execution');
  final gcloudArgs = gcloudFirebaseTestAndroidRunArgs(
    appApkPath: resolvedAppApk.path,
    testApkPath:
        resolvedTestApk?.path ?? '$repoRoot/$androidTestApkRelativePath',
    device: device,
    project: project,
    timeout: timeout,
  );

  final gcloud = resolveGcloudExecutable();
  final gcloudInvocation = gcloud == null
      ? 'gcloud ${gcloudArgs.join(' ')}'
      : '$gcloud ${gcloudArgs.join(' ')}';
  _log('GCloud command:');
  _log('  $gcloudInvocation\n');

  if (dryRun) {
    _log('[Dry Run] Command verified.');
    stdout.writeln('\n  $gcloudInvocation\n');
    _log('Firebase Test Lab console:');
    stdout.writeln(
      '  https://console.firebase.google.com/project/$project/testlab\n',
    );
    return;
  }

  if (gcloud == null) {
    stderr.writeln('gcloud CLI not found in PATH or ~/google-cloud-sdk/bin.');
    stderr.writeln('Install: https://cloud.google.com/sdk/docs/install');
    stderr.writeln('Then authenticate: gcloud auth login');
    stderr.writeln('Dry-run the command above after install.');
    exit(127);
  }

  _log('Dispatching to Firebase Test Lab...');
  final testProcess = await Process.run(gcloud, gcloudArgs);
  stdout.write(testProcess.stdout);
  if (testProcess.exitCode != 0) {
    stderr.writeln('Test Lab run failed (${testProcess.exitCode}):');
    stderr.write(testProcess.stderr);
    exit(testProcess.exitCode);
  }

  _log('Test run completed.');
  _log('Results: https://console.firebase.google.com/project/$project/testlab');
}

Future<String?> _devApkRefusalForFile(File apk) async {
  final aapt = resolveAaptExecutable();
  if (aapt == null) {
    return 'aapt not found. Set ANDROID_HOME and install Android build-tools.';
  }
  final result = await Process.run(aapt, ['dump', 'badging', apk.path]);
  if (result.exitCode != 0) {
    return 'aapt dump badging failed (${result.exitCode}).';
  }
  final badging = parseAaptBadging(result.stdout as String);
  if (badging == null) {
    return 'Could not parse aapt dump badging output.';
  }
  return devApkUploadRefusal(badging);
}

Future<String?> _resolveFlutterExecutable() async {
  final pathEnv = Platform.environment['PATH'] ?? '';
  for (final segment in pathEnv.split(Platform.pathSeparator)) {
    if (segment.isEmpty) continue;
    final candidate = File('$segment/flutter');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    for (final relative in [
      '.puro/envs/default/flutter/bin/flutter',
      'fvm/default/bin/flutter',
      'development/flutter/bin/flutter',
    ]) {
      final candidate = File('$home/$relative');
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }
  }
  final which = await Process.run('bash', [
    '-lc',
    'command -v flutter',
  ], environment: Platform.environment);
  if (which.exitCode == 0) {
    final resolved = (which.stdout as String).trim();
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }
  return null;
}

String? _getArg(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx != -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  for (final a in args) {
    if (a.startsWith('$flag=')) {
      return a.substring(flag.length + 1);
    }
  }
  return null;
}

void _log(String msg) {
  final timestamp = DateTime.now().toIso8601String().substring(11, 19);
  stdout.writeln('[$timestamp] $msg');
}

void _printHelp() {
  stdout.writeln('''
Belong on the Spectrum — Firebase Test Lab runner (dev APK only)

Usage:
  dart run tool/run_firebase_test_lab.dart [flags]

Builds with -t lib/main_dev.dart, FLAVOR=dev, ENABLE_SERVERPOD=false.
Refuses upload unless the app package is com.belongonthespectrum.refuge.dev.

Flags:
  --dry-run             Print commands without building or uploading.
  --build-only          Build APKs and verify badging; do not upload.
  --target <path>       Integration test file. Default: $_defaultTarget
  --project <id>        Must be $_defaultProject.
  --device <spec>       Device matrix. Default: $_defaultDevice
  --timeout <duration>  Test Lab timeout. Default: 10m
  --help, -h            Show this help.

Examples:
  dart run tool/run_firebase_test_lab.dart --dry-run
  dart run tool/run_firebase_test_lab.dart --build-only
''');
}
