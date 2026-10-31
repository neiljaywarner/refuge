import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/firebase_test_lab_support.dart';

void main() {
  group('patrolBuildAndroidArgs', () {
    test('pins dev defines and target file', () {
      expect(patrolBuildAndroidArgs(target: 'integration_test/patrol_ftl_home_shell_test.dart'), [
        'build',
        'android',
        '-t',
        'integration_test/patrol_ftl_home_shell_test.dart',
        '--dart-define=FLAVOR=dev',
        '--dart-define=ENABLE_SERVERPOD=false',
        '--no-uninstall',
      ]);
    });
  });

  group('devFlutterApkBuildArgs', () {
    test('pins dev entrypoint, flavor, and Serverpod off', () {
      expect(devFlutterApkBuildArgs(), [
        'build',
        'apk',
        '--debug',
        '-t',
        'lib/main_dev.dart',
        '--dart-define=FLAVOR=dev',
        '--dart-define=ENABLE_SERVERPOD=false',
      ]);
    });
  });

  group('parseAaptBadging', () {
    test('reads package and label from aapt output', () {
      const sample = '''
package: name='com.belongonthespectrum.refuge.dev' versionCode='2'
application-label:'[DEV] Belong on the Spectrum'
application: label='[DEV] Belong on the Spectrum' icon='res/mipmap-anydpi-v26/ic_launcher.xml'
''';
      final parsed = parseAaptBadging(sample);
      expect(parsed?.packageName, devAndroidPackageId);
      expect(parsed?.applicationLabel, devAndroidApplicationLabel);
    });
  });

  group('devApkUploadRefusal', () {
    test('refuses production package id', () {
      final reason = devApkUploadRefusal(
        ApkBadging(packageName: prodAndroidPackageId, applicationLabel: 'Belong'),
      );
      expect(reason, contains('production'));
    });

    test('accepts dev package and label', () {
      expect(
        devApkUploadRefusal(
          ApkBadging(
            packageName: devAndroidPackageId,
            applicationLabel: devAndroidApplicationLabel,
          ),
        ),
        isNull,
      );
    });
  });

  group('resolveGcloudExecutable', () {
    test('finds Homebrew gcloud when present', () {
      const homebrew = '/opt/homebrew/bin/gcloud';
      if (!File(homebrew).existsSync()) {
        return;
      }
      expect(resolveGcloudExecutable(), homebrew);
    });

    test('gcloudCandidatePaths includes Homebrew locations', () {
      expect(
        gcloudCandidatePaths(pathEnv: '/bin', home: '/tmp'),
        contains('/opt/homebrew/bin/gcloud'),
      );
    });

    test('splitPathSegments parses colon-separated paths on POSIX', () {
      final segments = splitPathSegments('/usr/bin:/bin:/custom/google-cloud-sdk/bin:');
      if (Platform.isWindows) {
        expect(segments, ['/usr/bin:/bin:/custom/google-cloud-sdk/bin:']);
      } else {
        expect(segments, ['/usr/bin', '/bin', '/custom/google-cloud-sdk/bin']);
      }
    });

    test('gcloudCandidatePaths splits multi-entry colon PATH', () {
      final paths = gcloudCandidatePaths(
        pathEnv: '/usr/local/bin:/custom/google-cloud-sdk/bin',
        home: '/tmp',
      );
      if (!Platform.isWindows) {
        expect(paths, contains('/custom/google-cloud-sdk/bin/gcloud'));
        expect(paths, contains('/usr/local/bin/gcloud'));
      }
    });
  });

  group('gcloudFirebaseTestAndroidRunArgs', () {
    test('assembles instrumentation run flags', () {
      expect(
        gcloudFirebaseTestAndroidRunArgs(
          appApkPath: 'app.apk',
          testApkPath: 'test.apk',
          device: 'model=panther,version=33',
          project: 'belongonthespectrum',
          timeout: '10m',
        ),
        [
          'firebase',
          'test',
          'android',
          'run',
          '--type',
          'instrumentation',
          '--app',
          'app.apk',
          '--test',
          'test.apk',
          '--device',
          'model=panther,version=33',
          '--project',
          'belongonthespectrum',
          '--timeout',
          '10m',
        ],
      );
    });

    test('appends a normalized results bucket when set', () {
      expect(
        gcloudFirebaseTestAndroidRunArgs(
          appApkPath: 'app.apk',
          testApkPath: 'test.apk',
          device: 'model=panther,version=33',
          project: 'belongonthespectrum',
          timeout: '10m',
          resultsBucket: 'gs://belongonthespectrum-ftl-results/',
        ),
        containsAllInOrder(['--results-bucket', 'belongonthespectrum-ftl-results']),
      );
    });
  });

  group('normalizeResultsBucket', () {
    test('strips gs:// and a trailing slash', () {
      expect(
        normalizeResultsBucket('  gs://belongonthespectrum-ftl-results/ '),
        'belongonthespectrum-ftl-results',
      );
    });

    test('returns null for blank input', () {
      expect(normalizeResultsBucket(null), isNull);
      expect(normalizeResultsBucket('   '), isNull);
    });
  });

  group('firebaseTestLabIamDiagnostic', () {
    const storageDenied = '''
ERROR: (gcloud.firebase.test.android.run) Could not copy [app-debug.apk] to [gs://test-lab-examplebucket/2026-10-31_16:38:16.250541_FfNa/] ResponseError 403: does not have storage.objects.create access to the Google Cloud Storage object. Permission 'storage.objects.create' denied on resource.
''';

    test('names the secret, Editor, and the Test Lab bucket without a real address', () {
      final message = firebaseTestLabIamDiagnostic(
        stderrText: storageDenied,
        project: 'belongonthespectrum',
      );
      expect(message, isNotNull);
      expect(message, contains('FIREBASE_SERVICE_ACCOUNT'));
      expect(message, contains('serviceAccount:$firebaseCiServiceAccountMemberPlaceholder'));
      expect(message, contains('not stored in git'));
      expect(message, contains('storage.objects.create'));
      expect(message, contains('gs://test-lab-examplebucket'));
      expect(message, contains('--role="roles/editor"'));
      expect(message, contains('workaround'));
      expect(message, isNot(contains('--role="roles/storage.objectAdmin"')));
      expect(message, contains('--role="roles/cloudtestservice.testAdmin"'));
      expect(
        message,
        contains('https://console.cloud.google.com/iam-admin/iam?project=belongonthespectrum'),
      );
      expect(
        message,
        contains('roles/cloudtestservice.editor and roles/toolresults.editor are not'),
      );
    });

    test('catalog 403 points at Test Lab Admin rather than Storage Editor', () {
      const catalogDenied = '''
ERROR: (gcloud.firebase.test.android.run) Unable to access the test environment catalog: ResponseError 403: Not authorized for project belongonthespectrum
''';
      final message = firebaseTestLabIamDiagnostic(
        stderrText: catalogDenied,
        project: 'belongonthespectrum',
      );
      expect(message, contains('--role="roles/cloudtestservice.testAdmin"'));
      expect(message, contains('testing.googleapis.com'));
      expect(message, isNot(contains('cloudtesting.googleapis.com')));
      expect(message, contains('toolresults.googleapis.com'));
      expect(message, isNot(contains('--role="roles/storage.objectAdmin"')));
      expect(message, isNot(contains('--role="roles/cloudtestservice.editor"')));
    });

    test('custom results bucket denial does not grant project Editor', () {
      const customDenied = '''
ERROR: (gcloud.firebase.test.android.run) Could not copy [app-debug.apk] to [gs://belongonthespectrum-ftl-results/2026-10-31_16:38:16.250541_FfNa/] ResponseError 403: does not have storage.objects.create access to the Google Cloud Storage object.
''';
      final message = firebaseTestLabIamDiagnostic(
        stderrText: customDenied,
        project: 'belongonthespectrum',
        resultsBucket: 'gs://belongonthespectrum-ftl-results/',
      );
      expect(message, contains('gs://belongonthespectrum-ftl-results'));
      expect(message, contains('--role="roles/storage.objectAdmin"'));
      expect(message, contains('--role="roles/cloudtestservice.testAdmin"'));
      expect(message, contains('--role="roles/firebase.analyticsViewer"'));
      expect(message, isNot(contains('--role="roles/editor"')));
      expect(message, isNot(contains('gs://test-lab-')));
    });

    test('returns null for an unrelated gcloud failure', () {
      expect(
        firebaseTestLabIamDiagnostic(
          stderrText: 'ERROR: Invalid value for [--device]',
          project: 'belongonthespectrum',
        ),
        isNull,
      );
    });
  });
}
