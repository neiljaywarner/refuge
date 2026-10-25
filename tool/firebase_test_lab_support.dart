/// Shared helpers for [`run_firebase_test_lab.dart`]: dev-only APK gates and
/// `gcloud firebase test android run` argument assembly.
library;

import 'dart:io';

import 'package:refuge4serverpod/src/core/build/release_build_stamp.dart';
import 'package:refuge4serverpod/src/core/config/native_launcher_labels.dart';

/// Production Android application id — uploads with this package are refused.
const prodAndroidPackageId = 'com.belongonthespectrum.refuge';

/// Required debug dev package for Firebase Test Lab on project belongonthespectrum.
const devAndroidPackageId = 'com.belongonthespectrum.refuge.dev';

/// Required launcher label for dev builds (VGV-style `[DEV]` prefix).
const devAndroidApplicationLabel = devLauncherTitle;

const devMainEntrypoint = 'lib/main_dev.dart';

/// `flutter build apk --debug` arguments for a safe Test Lab app APK.
List<String> devFlutterApkBuildArgs() => [
  'build',
  'apk',
  '--debug',
  '-t',
  devMainEntrypoint,
  '--dart-define=FLAVOR=dev',
  '--dart-define=ENABLE_SERVERPOD=false',
];

/// `flutter build apk --release` arguments for CI / App Distribution dev APKs.
List<String> devReleaseFlutterApkBuildArgs({
  required ReleaseBuildStamp stamp,
  List<String> extraDefines = const [],
}) => stamp.flutterArgs(
  'apk',
  targetFile: devMainEntrypoint,
  flavor: 'dev',
  extraDefines: ['--dart-define=ENABLE_SERVERPOD=false', ...extraDefines],
);

/// Candidate release dev APK paths (Flutter vs legacy Gradle output).
List<String> devReleaseApkRelativePaths() => [
  'build/app/outputs/flutter-apk/app-release.apk',
  'build/app/outputs/apk/release/app-release.apk',
];

/// Relative Gradle target for the hello-world instrumentation APK.
String integrationTestGradleTarget(String targetPath) {
  final normalized = targetPath.replaceAll(r'\', '/');
  if (normalized.startsWith('integration_test/')) {
    return '../$normalized';
  }
  return normalized;
}

/// Candidate app APK paths (Flutter vs legacy Gradle output).
List<String> appApkRelativePaths() => [
  'build/app/outputs/flutter-apk/app-debug.apk',
  'build/app/outputs/apk/debug/app-debug.apk',
];

const androidTestApkRelativePath =
    'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk';

/// LeanCode Patrol CLI args for a dev-safe instrumentation build.
///
/// See https://patrol.leancode.co/documentation/native/setup
List<String> patrolBuildAndroidArgs({required String target}) => [
  'build',
  'android',
  '-t',
  target,
  '--dart-define=FLAVOR=dev',
  '--dart-define=ENABLE_SERVERPOD=false',
  '--no-uninstall',
];

/// Parsed `aapt dump badging` fields used for the dev upload gate.
class ApkBadging {
  const ApkBadging({required this.packageName, required this.applicationLabel});

  final String packageName;
  final String applicationLabel;
}

ApkBadging? parseAaptBadging(String aaptOutput) {
  final packageMatch = RegExp(r"package: name='([^']+)'").firstMatch(aaptOutput);
  final labelMatch = RegExp(r"application-label:'([^']+)'").firstMatch(aaptOutput);
  if (packageMatch == null || labelMatch == null) {
    return null;
  }
  return ApkBadging(packageName: packageMatch.group(1)!, applicationLabel: labelMatch.group(1)!);
}

/// Returns a human-readable refusal reason, or null when the APK is safe to upload.
String? devApkUploadRefusal(ApkBadging badging) {
  if (badging.packageName == prodAndroidPackageId) {
    return 'Refusing upload: package is $prodAndroidPackageId (production). '
        'Rebuild with -t $devMainEntrypoint and --dart-define=FLAVOR=dev.';
  }
  if (badging.packageName != devAndroidPackageId) {
    return 'Refusing upload: expected package $devAndroidPackageId, '
        'got ${badging.packageName}.';
  }
  if (badging.applicationLabel != devAndroidApplicationLabel) {
    return 'Refusing upload: expected label "$devAndroidApplicationLabel", '
        'got "${badging.applicationLabel}".';
  }
  return null;
}

/// Returns a refusal reason when [apk] is not a safe dev package, or null when OK.
Future<String?> devApkUploadRefusalForFile(File apk) async {
  final aapt = resolveAaptExecutable();
  if (aapt == null) {
    return 'Could not locate aapt (set ANDROID_HOME or ANDROID_SDK_ROOT).';
  }
  final result = await Process.run(aapt, ['dump', 'badging', apk.path]);
  if (result.exitCode != 0) {
    return 'aapt dump badging failed for ${apk.path}.';
  }
  final badging = parseAaptBadging(result.stdout.toString());
  if (badging == null) {
    return 'Could not parse aapt badging for ${apk.path}.';
  }
  return devApkUploadRefusal(badging);
}

/// Builds the `gcloud firebase test android run` argument list (no shell quoting).
List<String> gcloudFirebaseTestAndroidRunArgs({
  required String appApkPath,
  required String testApkPath,
  required String device,
  required String project,
  required String timeout,
}) => [
  'firebase',
  'test',
  'android',
  'run',
  '--type',
  'instrumentation',
  '--app',
  appApkPath,
  '--test',
  testApkPath,
  '--device',
  device,
  '--project',
  project,
  '--timeout',
  timeout,
];

/// Resolves `aapt` from [androidHome] build-tools (newest version first).
String? resolveAaptExecutable({String? androidHome}) {
  final sdkRoot =
      androidHome ??
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (sdkRoot == null || sdkRoot.isEmpty) {
    return null;
  }
  final buildTools = Directory('$sdkRoot/build-tools');
  if (!buildTools.existsSync()) {
    return null;
  }
  final versions = buildTools.listSync().whereType<Directory>().map((dir) => dir.path).toList();
  versions.sort((a, b) => b.compareTo(a));
  for (final dir in versions) {
    final candidate = File('$dir/aapt');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  return null;
}

/// First existing file from [relativePaths] under [repoRoot].
File? resolveExistingApk(String repoRoot, List<String> relativePaths) {
  for (final relative in relativePaths) {
    final file = File('$repoRoot/$relative');
    if (file.existsSync()) {
      return file;
    }
  }
  return null;
}

/// Well-known `gcloud` install paths (Homebrew, manual SDK, PATH segments).
List<String> gcloudCandidatePaths({String? pathEnv, String? home}) {
  final paths = <String>[];
  final path = pathEnv ?? Platform.environment['PATH'] ?? '';
  for (final segment in path.split(Platform.pathSeparator)) {
    if (segment.isEmpty) continue;
    paths.add('$segment/gcloud');
  }
  final homeDir = home ?? Platform.environment['HOME'];
  if (homeDir != null) {
    paths.addAll([
      '$homeDir/google-cloud-sdk/bin/gcloud',
      '/opt/homebrew/bin/gcloud',
      '/opt/homebrew/share/google-cloud-sdk/bin/gcloud',
      '/usr/local/bin/gcloud',
      '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/gcloud',
    ]);
  }
  return paths;
}

/// Locates the `patrol` CLI (Patrol native instrumentation builds).
String? resolvePatrolExecutable() {
  final home = Platform.environment['HOME'];
  final candidates = <String>[
    if (home != null) '$home/.pub-cache/bin/patrol',
    '/opt/homebrew/bin/patrol',
  ];
  final pathEnv = Platform.environment['PATH'] ?? '';
  for (final segment in pathEnv.split(Platform.pathSeparator)) {
    if (segment.isEmpty) continue;
    candidates.add('$segment/patrol');
  }
  for (final candidatePath in candidates) {
    final candidate = File(candidatePath);
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  return null;
}

/// Locates `gcloud` on PATH or common install locations.
String? resolveGcloudExecutable() {
  for (final candidatePath in gcloudCandidatePaths()) {
    final candidate = File(candidatePath);
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  return null;
}
