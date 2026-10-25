/// Shared helpers for [`run_firebase_test_lab.dart`]: dev-only APK gates and
/// `gcloud firebase test android run` argument assembly.
library;

import 'dart:io';

/// Production Android application id — uploads with this package are refused.
const prodAndroidPackageId = 'com.belongonthespectrum.refuge';

/// Required debug dev package for Firebase Test Lab on project belongonthespectrum.
const devAndroidPackageId = 'com.belongonthespectrum.refuge.dev';

/// Required launcher label for dev debug builds.
const devAndroidApplicationLabel = 'Belong (Dev)';

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

/// Parsed `aapt dump badging` fields used for the dev upload gate.
class ApkBadging {
  const ApkBadging({required this.packageName, required this.applicationLabel});

  final String packageName;
  final String applicationLabel;
}

ApkBadging? parseAaptBadging(String aaptOutput) {
  final packageMatch = RegExp(
    r"package: name='([^']+)'",
  ).firstMatch(aaptOutput);
  final labelMatch = RegExp(
    r"application-label:'([^']+)'",
  ).firstMatch(aaptOutput);
  if (packageMatch == null || labelMatch == null) {
    return null;
  }
  return ApkBadging(
    packageName: packageMatch.group(1)!,
    applicationLabel: labelMatch.group(1)!,
  );
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
  final versions = buildTools
      .listSync()
      .whereType<Directory>()
      .map((dir) => dir.path)
      .toList();
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

/// Locates `gcloud` on PATH or common install locations.
String? resolveGcloudExecutable() {
  final pathEnv = Platform.environment['PATH'] ?? '';
  for (final segment in pathEnv.split(Platform.pathSeparator)) {
    if (segment.isEmpty) continue;
    final candidate = File('$segment/gcloud');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  final home = Platform.environment['HOME'];
  if (home != null) {
    final sdkCandidate = File('$home/google-cloud-sdk/bin/gcloud');
    if (sdkCandidate.existsSync()) {
      return sdkCandidate.path;
    }
  }
  return null;
}
