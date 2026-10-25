import 'package:flutter_test/flutter_test.dart';

import '../../tool/firebase_test_lab_support.dart';

void main() {
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
