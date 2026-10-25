import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final webBuildDir = Directory('build/web');

  group(
    'PWA Release Bundle & Smoke Verification (#396)',
    () {
      test('build/web directory and core entrypoints exist', () {
        expect(
          webBuildDir.existsSync(),
          isTrue,
          reason: 'build/web must exist after flutter build web --release',
        );

        final indexHtml = File('build/web/index.html');
        expect(indexHtml.existsSync(), isTrue);

        final mainJs = File('build/web/main.dart.js');
        expect(mainJs.existsSync(), isTrue);
        expect(
          mainJs.lengthSync(),
          greaterThan(1000000),
          reason: 'main.dart.js should be a compiled production bundle (> 1MB)',
        );

        final bootstrapJs = File('build/web/flutter_bootstrap.js');
        expect(bootstrapJs.existsSync(), isTrue);

        final manifestFile = File('build/web/manifest.json');
        expect(manifestFile.existsSync(), isTrue);

        final versionFile = File('build/web/version.json');
        expect(versionFile.existsSync(), isTrue);
      });

      test('index.html contains expected PWA headers and bootstrap script', () {
        final content = File('build/web/index.html').readAsStringSync();
        expect(content, contains('<meta name="description"'));
        expect(content, contains('<link rel="manifest" href="manifest.json">'));
        expect(content, contains('<script src="flutter_bootstrap.js" async>'));
        expect(content, contains('Belong on the Spectrum'));
      });

      test('manifest.json specifies valid PWA manifest fields and icons', () {
        final manifestRaw = File('build/web/manifest.json').readAsStringSync();
        final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;

        expect(manifest['name'], equals('Belong on the Spectrum'));
        expect(manifest['short_name'], equals('Belong'));
        expect(manifest['display'], equals('standalone'));
        expect(manifest['start_url'], equals('.'));

        final icons = manifest['icons'] as List<dynamic>;
        expect(icons, isNotEmpty);
        for (final icon in icons) {
          final iconMap = icon as Map<String, dynamic>;
          final src = iconMap['src'] as String;
          final iconFile = File('build/web/$src');
          expect(
            iconFile.existsSync(),
            isTrue,
            reason: 'Icon $src declared in manifest.json must exist on disk',
          );
        }
      });

      test('service worker and offline cache assets are generated', () {
        final swFile = File('build/web/flutter_service_worker.js');
        expect(swFile.existsSync(), isTrue);
        expect(swFile.lengthSync(), greaterThan(100));
      });
    },
    skip: !webBuildDir.existsSync()
        ? 'Skipped: build/web does not exist (run flutter build web --release before running smoke tests)'
        : null,
  );
}
