/// # Firebase Test Lab & Patrol Android Runner (`tool/run_firebase_test_lab.dart`)
///
/// Builds a **dev-only** debug APK pair and optionally uploads to Firebase Test
/// Lab on project `belongonthespectrum`.
///
/// Every build uses `lib/main_dev.dart` and `FLAVOR=dev`.
/// Upload is refused unless `aapt dump badging`
/// reports `com.belongonthespectrum.refuge.dev` and label `[DEV] Belong on the Spectrum`.
///
/// CI authenticates with repository secret `FIREBASE_SERVICE_ACCOUNT`. The JSON
/// `client_email` stays in that secret. Do not commit the address.
/// A 403 `storage.objects.create` on the default `gs://test-lab-*` bucket needs
/// project `roles/editor` on that account (or `FTL_RESULTS_BUCKET` / `--results-bucket`).
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
const _defaultTarget = 'integration_test/patrol_ftl_full_free_tier_suite_test.dart';
const _defaultDevice = 'model=panther,version=33,locale=en,orientation=portrait';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final dryRun = args.contains('--dry-run');
  final buildOnly = args.contains('--build-only');
  final target = _getArg(args, '--target') ?? _defaultTarget;
  final project =
      _getArg(args, '--project') ?? Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProject;
  final device = _getArg(args, '--device') ?? _defaultDevice;
  final timeout = _getArg(args, '--timeout') ?? '10m';
  final resultsBucket = normalizeResultsBucket(
    _getArg(args, '--results-bucket') ?? Platform.environment['FTL_RESULTS_BUCKET'],
  );

  if (project != _defaultProject) {
    stderr.writeln('Refusing run: --project must be $_defaultProject for Test Lab safety.');
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
  _log('Results bucket: ${resultsBucket ?? '(default gs://test-lab-*)'}');
  _log('------------------------------------------------------------');

  final testFile = File(target);
  if (!testFile.existsSync()) {
    stderr.writeln('Target test file not found: $target');
    exit(64);
  }
  _log('Verified target test file: ${testFile.path}');
  final useOrchestrator = ftlTargetNeedsOrchestrator(testFile.readAsStringSync());
  _log(
    useOrchestrator
        ? 'Orchestrator   : on (more than one patrolTest; fresh process each)'
        : 'Orchestrator   : off (single patrolTest)',
  );

  final repoRoot = Directory.current.path;
  final appApk = resolveExistingApk(repoRoot, appApkRelativePaths());
  final testApk = File('$repoRoot/$androidTestApkRelativePath');

  _log('\nPhase 1: Dev debug APK assembly (Patrol native instrumentation)');
  _log('patrol ${patrolBuildAndroidArgs(target: target).join(' ')}');
  _log(
    'No Gradle fallback. A plain flutter build apk plus assembleDebugAndroidTest '
    'omits Patrol server ports and the test bundle. On Test Lab that pair waits '
    'until the device timeout (run 41346774462).',
  );

  if (!dryRun) {
    final patrol = resolvePatrolExecutable();
    if (patrol == null) {
      stderr.writeln(
        'patrol CLI not found. Install the version that matches package:patrol '
        '(patrol_cli 4.8.0 for patrol 4.10) and put it on PATH:',
      );
      stderr.writeln('  dart pub global activate patrol_cli 4.8.0');
      stderr.writeln('  export PATH="\$HOME/.pub-cache/bin:\$PATH"');
      exit(127);
    }

    _log('Running patrol build android...');
    final patrolBuild = await Process.run(
      patrol,
      patrolBuildAndroidArgs(target: target),
      workingDirectory: repoRoot,
    );
    if (patrolBuild.exitCode != 0) {
      stderr.writeln('patrol build android failed (${patrolBuild.exitCode}).');
      stderr.write(patrolBuild.stderr);
      stdout.write(patrolBuild.stdout);
      exit(patrolBuild.exitCode);
    }
    _log('Patrol dev APK pair built.');
  } else {
    _log('[Dry Run] Skipped patrol build android.');
  }

  final resolvedAppApk =
      resolveExistingApk(repoRoot, appApkRelativePaths()) ??
      (dryRun ? File('$repoRoot/${appApkRelativePaths().first}') : null);
  final resolvedTestApk = testApk.existsSync()
      ? testApk
      : (dryRun ? File('$repoRoot/$androidTestApkRelativePath') : null);

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
    _log('Verified package $devAndroidPackageId and label $devAndroidApplicationLabel.');
  }

  if (buildOnly) {
    _log('Build complete (--build-only). Exiting.');
    return;
  }

  _log('\nPhase 2: Firebase Test Lab cloud execution');
  final gcloudArgs = gcloudFirebaseTestAndroidRunArgs(
    appApkPath: resolvedAppApk.path,
    testApkPath: resolvedTestApk?.path ?? '$repoRoot/$androidTestApkRelativePath',
    device: device,
    project: project,
    timeout: timeout,
    resultsBucket: resultsBucket,
    useOrchestrator: useOrchestrator,
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
    stdout.writeln('  https://console.firebase.google.com/project/$project/testlab\n');
    return;
  }

  if (gcloud == null) {
    stderr.writeln('gcloud CLI not found (checked PATH, ~/google-cloud-sdk, and Homebrew).');
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
    final diagnostic = firebaseTestLabIamDiagnostic(
      stderrText: testProcess.stderr.toString(),
      project: project,
      resultsBucket: resultsBucket,
    );
    if (diagnostic != null) {
      stderr.write(diagnostic);
    }
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

Builds with -t lib/main_dev.dart and FLAVOR=dev.
Refuses upload unless the app package is com.belongonthespectrum.refuge.dev.

Flags:
  --dry-run             Print commands without building or uploading.
  --build-only          Build APKs and verify badging; do not upload.
  --target <path>       Integration test file. Default: $_defaultTarget
  --project <id>        Must be $_defaultProject.
  --device <spec>       Device matrix. Default: $_defaultDevice
  --timeout <duration>  Test Lab timeout. Default: 10m
  --results-bucket <b>  Project-owned Cloud Storage bucket. Avoids the default
                        gs://test-lab-* bucket, which requires roles/editor.
                        Falls back to env FTL_RESULTS_BUCKET. gs:// is stripped.
  --help, -h            Show this help.

CI secret: $firebaseCiServiceAccountSecretName
The service account address is client_email in that secret. Do not commit it.

Examples:
  dart run tool/run_firebase_test_lab.dart --dry-run
  dart run tool/run_firebase_test_lab.dart --build-only
''');
}
