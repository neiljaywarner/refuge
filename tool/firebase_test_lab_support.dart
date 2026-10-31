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

/// Repository secret that holds the Firebase CI service-account JSON.
///
/// Daily Test Lab (`.github/workflows/firebase-test-lab-daily.yml`) and Hosting
/// deploy both pass this secret to `google-github-actions/auth`.
const firebaseCiServiceAccountSecretName = 'FIREBASE_SERVICE_ACCOUNT';

/// Placeholder for `client_email` in printed gcloud commands.
///
/// The real address lives only in the [firebaseCiServiceAccountSecretName]
/// JSON. Do not commit it.
const firebaseCiServiceAccountMemberPlaceholder = 'CLIENT_EMAIL';

/// Google Cloud IAM page for [project].
String googleCloudIamConsoleUrl(String project) =>
    'https://console.cloud.google.com/iam-admin/iam?project=$project';

/// `gcloud projects add-iam-policy-binding` for [role] on [project].
///
/// The member is [firebaseCiServiceAccountMemberPlaceholder], not a real address.
String gcloudProjectIamBinding({required String project, required String role}) =>
    'gcloud projects add-iam-policy-binding $project \\\n'
    '  --member="serviceAccount:$firebaseCiServiceAccountMemberPlaceholder" \\\n'
    '  --role="$role"';

/// `gcloud storage buckets add-iam-policy-binding` for [role] on [bucketUrl].
///
/// [bucketUrl] may be `gs://name` or a bare bucket name. The member is
/// [firebaseCiServiceAccountMemberPlaceholder], not a real address.
String gcloudBucketIamBinding({required String bucketUrl, required String role}) {
  final bucket = bucketUrl.startsWith('gs://') ? bucketUrl : 'gs://$bucketUrl';
  return 'gcloud storage buckets add-iam-policy-binding $bucket \\\n'
      '  --member="serviceAccount:$firebaseCiServiceAccountMemberPlaceholder" \\\n'
      '  --role="$role"';
}

final _copyDestinationBucket = RegExp(r'to \[gs://([A-Za-z0-9._-]+)');

/// Bucket name from a gcloud "Could not copy … to [gs://…] " line, without `gs://`.
String? storageBucketFromStderr(String stderrText) =>
    _copyDestinationBucket.firstMatch(stderrText)?.group(1);

/// Whether [bucketName] is the Firebase-owned default Test Lab bucket.
bool isDefaultTestLabBucket(String? bucketName) =>
    bucketName == null || bucketName.startsWith('test-lab-');

/// Whether [stderrText] is a Test Lab authorization or Storage denial.
bool firebaseTestLabAuthFailure(String stderrText) =>
    stderrText.contains('storage.objects.create') ||
    stderrText.contains('Not authorized for project') ||
    stderrText.contains('ResponseError 403') ||
    stderrText.contains('PERMISSION_DENIED');

/// Builds the IAM guidance for a failed `gcloud firebase test android run`.
///
/// Returns `null` when [stderrText] is not an authorization failure.
/// A denial on the default `gs://test-lab-*` bucket names `roles/editor`.
/// When [resultsBucket] is set, or the denied bucket is not `test-lab-*`, the
/// text names object admin on that bucket and does not grant project Editor.
/// Other 403s name Firebase Test Lab Admin and the Testing APIs.
String? firebaseTestLabIamDiagnostic({
  required String stderrText,
  required String project,
  String? resultsBucket,
}) {
  if (!firebaseTestLabAuthFailure(stderrText)) {
    return null;
  }

  final buffer = StringBuffer()
    ..writeln()
    ..writeln('============================================================')
    ..writeln('IAM check for repository secret $firebaseCiServiceAccountSecretName')
    ..writeln(
      'Service account: client_email inside $firebaseCiServiceAccountSecretName. '
      'That address is not stored in git.',
    )
    ..writeln('Project: $project')
    ..writeln('IAM console: ${googleCloudIamConsoleUrl(project)}')
    ..writeln();

  if (stderrText.contains('storage.objects.create')) {
    final selected = normalizeResultsBucket(resultsBucket);
    final denied = storageBucketFromStderr(stderrText);
    final bucketName = selected ?? denied;
    final customBucket = selected != null || !isDefaultTestLabBucket(denied);
    final bucketUrl = bucketName == null ? null : 'gs://$bucketName';
    buffer
      ..writeln(
        'Cloud Storage denied storage.objects.create while uploading the dev APK '
        'to ${bucketUrl ?? 'the default Firebase Test Lab bucket'}.',
      )
      ..writeln(
        'roles/cloudtestservice.editor and roles/toolresults.editor are not Cloud '
        'IAM role IDs, and they do not grant this upload.',
      )
      ..writeln();
    if (customBucket && bucketUrl != null) {
      buffer
        ..writeln(
          'This run used a project-owned results bucket. Do not grant project '
          'Editor for this denial. Grant object admin on $bucketUrl, plus Firebase '
          'Test Lab Admin and Firebase Analytics Viewer:',
        )
        ..writeln('https://firebase.google.com/docs/test-lab/android/iam-permissions-reference')
        ..writeln()
        ..writeln(gcloudBucketIamBinding(bucketUrl: bucketUrl, role: 'roles/storage.objectAdmin'))
        ..writeln()
        ..writeln(
          gcloudProjectIamBinding(project: project, role: 'roles/cloudtestservice.testAdmin'),
        )
        ..writeln()
        ..writeln(
          gcloudProjectIamBinding(project: project, role: 'roles/firebase.analyticsViewer'),
        );
    } else {
      buffer
        ..writeln(
          'The default gs://test-lab-* bucket requires project Editor on this '
          'principal:',
        )
        ..writeln('https://firebase.google.com/docs/test-lab/android/analyzing-results')
        ..writeln()
        ..writeln(gcloudProjectIamBinding(project: project, role: 'roles/editor'))
        ..writeln()
        ..writeln(
          'That is the documented grant. A bucket-level roles/storage.objectAdmin '
          'binding is only a workaround if Editor is already present and the bucket '
          'policy still denies storage.objects.create.',
        )
        ..writeln()
        ..writeln(
          'Also grant Firebase Test Lab Admin. That role lists storage.objects.create, '
          'but the default bucket still requires Editor:',
        )
        ..writeln()
        ..writeln(
          gcloudProjectIamBinding(project: project, role: 'roles/cloudtestservice.testAdmin'),
        )
        ..writeln()
        ..writeln(
          'Narrower path (skip project Editor): create a bucket this project owns, '
          'grant roles/storage.objectAdmin on it, grant roles/cloudtestservice.testAdmin '
          'and roles/firebase.analyticsViewer, set repository variable FTL_RESULTS_BUCKET, '
          'and rerun. The runner passes that name as --results-bucket.',
        )
        ..writeln('https://firebase.google.com/docs/test-lab/android/iam-permissions-reference');
    }
  } else {
    buffer
      ..writeln('gcloud is not authorized for Cloud Test Lab on $project.')
      ..writeln()
      ..writeln('Grant Firebase Test Lab Admin (this role includes Tool Results):')
      ..writeln()
      ..writeln(gcloudProjectIamBinding(project: project, role: 'roles/cloudtestservice.testAdmin'))
      ..writeln()
      ..writeln('When using a custom results bucket, also grant Firebase Analytics Viewer:')
      ..writeln()
      ..writeln(gcloudProjectIamBinding(project: project, role: 'roles/firebase.analyticsViewer'))
      ..writeln()
      ..writeln(
        'The default gs://test-lab-* bucket additionally requires roles/editor. '
        'See docs/wiki/Firebase-Test-Lab-and-Patrol-Guide.md.',
      )
      ..writeln('Issue #649.');
  }

  buffer
    ..writeln()
    ..writeln('Enable APIs if they are still off:')
    ..writeln(
      'gcloud services enable testing.googleapis.com '
      'toolresults.googleapis.com --project=$project',
    )
    ..writeln('============================================================');
  return buffer.toString();
}

/// Returns a Cloud Storage bucket name suitable for `--results-bucket`.
///
/// Strips a `gs://` prefix, a trailing slash, and surrounding whitespace.
/// Returns `null` when [raw] is null or empty.
String? normalizeResultsBucket(String? raw) {
  if (raw == null) {
    return null;
  }
  var value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('gs://')) {
    value = value.substring('gs://'.length);
  }
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  if (value.isEmpty) {
    return null;
  }
  return value;
}

/// Builds the `gcloud firebase test android run` argument list (no shell quoting).
///
/// [resultsBucket] is optional. A `gs://` prefix is stripped. When omitted, gcloud
/// uploads to the Firebase-owned `gs://test-lab-*` bucket, which requires
/// `roles/editor` on the service account in [firebaseCiServiceAccountSecretName].
List<String> gcloudFirebaseTestAndroidRunArgs({
  required String appApkPath,
  required String testApkPath,
  required String device,
  required String project,
  required String timeout,
  String? resultsBucket,
}) {
  final bucket = normalizeResultsBucket(resultsBucket);
  return [
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
    if (bucket != null) ...['--results-bucket', bucket],
  ];
}

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

/// Splits a system PATH variable into directory segments.
///
/// On Windows, PATH entries are delimited by `;`.
/// On POSIX systems (Linux, macOS), PATH entries are delimited by `:`.
List<String> splitPathSegments(String pathEnv) {
  final delimiter = Platform.isWindows ? ';' : ':';
  return pathEnv.split(delimiter).where((segment) => segment.isNotEmpty).toList();
}

/// Well-known `gcloud` install paths (Homebrew, manual SDK, PATH segments).
List<String> gcloudCandidatePaths({String? pathEnv, String? home}) {
  final paths = <String>[];
  final rawPath = pathEnv ?? Platform.environment['PATH'] ?? '';
  for (final segment in splitPathSegments(rawPath)) {
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
  final rawPath = Platform.environment['PATH'] ?? '';
  for (final segment in splitPathSegments(rawPath)) {
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
