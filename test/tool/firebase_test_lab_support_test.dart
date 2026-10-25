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
  });
}
