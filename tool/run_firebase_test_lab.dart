/// # Firebase Test Lab & Patrol Android Runner (`tool/run_firebase_test_lab.dart`)
///
/// Orchestrates running Patrol integration tests (`integration_test/*_test.dart`)
/// on **Firebase Test Lab** real and virtual Android devices.
///
/// ## Overview
/// 1. Verifies the test target exists (e.g. `integration_test/patrol_hello_world_test.dart`).
/// 2. Assembles the Android application APK and AndroidTest instrumentation APK
///    via Gradle (`./gradlew app:assembleDebug app:assembleDebugAndroidTest`).
/// 3. Dispatches the instrumentation test to Firebase Test Lab via `gcloud firebase test android run`
///    or prints the deterministic cloud execution command with `--dry-run`.
///
/// ## Usage
/// ```bash
/// dart run tool/run_firebase_test_lab.dart --dry-run
/// dart run tool/run_firebase_test_lab.dart --target integration_test/patrol_hello_world_test.dart
/// dart run tool/run_firebase_test_lab.dart --project belongonthespectrum --device model=panther,version=33
/// ```
library;

import 'dart:io';

const _defaultProject = 'belongonthespectrum';
const _defaultTarget = 'integration_test/patrol_hello_world_test.dart';
const _defaultDevice = 'model=panther,version=33,locale=en,orientation=portrait';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final dryRun = args.contains('--dry-run');
  final buildOnly = args.contains('--build-only');
  final target = _getArg(args, '--target') ?? _defaultTarget;
  final project = _getArg(args, '--project') ??
      Platform.environment['FIREBASE_PROJECT_ID'] ??
      _defaultProject;
  final device = _getArg(args, '--device') ?? _defaultDevice;
  final timeout = _getArg(args, '--timeout') ?? '10m';

  _log('============================================================');
  _log('🧪 Belong on the Spectrum — Firebase Test Lab & Patrol Runner');
  _log('============================================================');
  _log('Target Test : $target');
  _log('Project     : $project');
  _log('Device Spec : $device');
  _log('Dry Run     : $dryRun');
  _log('Build Only  : $buildOnly');
  _log('Timeout     : $timeout');
  _log('------------------------------------------------------------');

  // 1. Verify target exists
  final testFile = File(target);
  if (!testFile.existsSync()) {
    stderr.writeln('❌ Target test file not found: $target');
    exit(64);
  }
  _log('✅ Verified target test file exists: ${testFile.path}');

  // 2. APK Artifact Paths
  final appApk = File('build/app/outputs/apk/debug/app-debug.apk');
  final testApk = File('build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk');

  _log('App APK Target      : ${appApk.path}');
  _log('AndroidTest APK     : ${testApk.path}');

  // 3. Assemble Build Step
  final gradleCmd = Platform.isWindows ? 'gradlew.bat' : './gradlew';
  final gradleArgs = ['app:assembleDebug', 'app:assembleDebugAndroidTest'];

  _log('\n📦 Phase 1: Android Instrumentation APK Assembly');
  _log('Command: cd android && $gradleCmd ${gradleArgs.join(' ')}');

  if (!dryRun) {
    final androidDir = Directory('android');
    if (!androidDir.existsSync()) {
      stderr.writeln('❌ android/ directory not found. Must run from Flutter root.');
      exit(65);
    }

    _log('Executing Gradle build...');
    final gradleProcess = await Process.run(
      gradleCmd,
      gradleArgs,
      workingDirectory: androidDir.path,
    );

    if (gradleProcess.exitCode != 0) {
      stderr.writeln('❌ Gradle assembly failed with exit code ${gradleProcess.exitCode}');
      if ((gradleProcess.stderr as String).isNotEmpty) {
        stderr.writeln(gradleProcess.stderr);
      }
      if ((gradleProcess.stdout as String).isNotEmpty) {
        stdout.writeln(gradleProcess.stdout);
      }
      exit(gradleProcess.exitCode);
    }
    _log('✅ Android APKs built successfully.');
  } else {
    _log('ℹ️ [Dry Run] Skipped physical Gradle invocation.');
  }

  if (buildOnly) {
    _log('🎉 Build complete (--build-only specified). Exiting.');
    return;
  }

  // 4. Firebase Test Lab Execution
  _log('\n☁️ Phase 2: Firebase Test Lab Cloud Execution');
  final gcloudArgs = [
    'firebase',
    'test',
    'android',
    'run',
    '--type',
    'instrumentation',
    '--app',
    appApk.path,
    '--test',
    testApk.path,
    '--device',
    device,
    '--project',
    project,
    '--timeout',
    timeout,
  ];

  final fullGcloudCmd = 'gcloud ${gcloudArgs.join(' ')}';
  _log('GCloud Command:');
  _log('  $fullGcloudCmd\n');

  if (dryRun) {
    _log('ℹ️ [Dry Run] Command verified.');
    _log('To execute in your terminal with authenticated gcloud credentials:');
    stdout.writeln('\n  $fullGcloudCmd\n');
    _log('Firebase Test Lab Console URL:');
    stdout.writeln('  https://console.firebase.google.com/project/$project/testlab\n');
    return;
  }

  // Check if gcloud is installed before attempting invocation
  final gcloudCheck = await Process.run('which', ['gcloud']);
  if (gcloudCheck.exitCode != 0) {
    stderr.writeln('⚠️ gcloud CLI not found in PATH.');
    stderr.writeln('To install gcloud: https://cloud.google.com/sdk/docs/install');
    stderr.writeln('Or run this test locally using:');
    stderr.writeln('  flutter test $target');
    exit(127);
  }

  _log('Dispatching test run to Firebase Test Lab...');
  final testProcess = await Process.run('gcloud', gcloudArgs);
  stdout.writeln(testProcess.stdout);
  if (testProcess.exitCode != 0) {
    stderr.writeln('❌ Test Lab run exited with code ${testProcess.exitCode}:');
    stderr.writeln(testProcess.stderr);
    exit(testProcess.exitCode);
  }

  _log('🎉 Test run completed successfully!');
  _log('Inspect live results at: https://console.firebase.google.com/project/$project/testlab');
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
Belong on the Spectrum — Firebase Test Lab & Patrol Android Runner

Usage:
  dart run tool/run_firebase_test_lab.dart [flags]

Flags:
  --dry-run             Print the commands and configuration without executing.
  --target <path>       Target integration test file. Default: $_defaultTarget
  --project <id>        Firebase project ID. Default: $_defaultProject
  --device <spec>       Device matrix specification. Default: $_defaultDevice
  --timeout <duration>  Timeout for the test run. Default: 10m
  --build-only          Only build the Android APKs; do not submit to Test Lab.
  --help, -h            Show this help message.

Examples:
  dart run tool/run_firebase_test_lab.dart --dry-run
  dart run tool/run_firebase_test_lab.dart --target integration_test/patrol_hello_world_test.dart
  dart run tool/run_firebase_test_lab.dart --device model=oriole,version=32
''');
}
