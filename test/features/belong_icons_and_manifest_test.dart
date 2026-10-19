import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BDD Feature: Belong Multi-Platform Icons & PWA Manifest (#19)', () {
    test('PWA manifest.json uses Belong branding and cream/navy palette', () {
      final manifestFile = File('web/manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['name'], 'Belong on the Spectrum');
      expect(manifest['short_name'], 'Belong');
      expect(manifest['background_color'], '#F3EFE6');
      expect(manifest['theme_color'], '#112334');
      expect(manifest['display'], 'standalone');

      final icons = manifest['icons'] as List<dynamic>;
      expect(icons.length, greaterThanOrEqualTo(4));
    });

    test('Android API 26+ adaptive icon XMLs and foreground mipmaps exist', () {
      expect(
        File(
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/values/ic_launcher_background.xml',
        ).readAsStringSync(),
        contains('#F3EFE6'),
      );
      expect(
        File(
          'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png',
        ).existsSync(),
        isTrue,
      );
    });

    test('iOS 1024x1024 App Store icon and macOS 1024x1024 icon exist', () {
      final ios1024 = File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      );
      final macos1024 = File(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
      );
      expect(ios1024.existsSync(), isTrue);
      expect(ios1024.lengthSync(), greaterThan(10000));
      expect(macos1024.existsSync(), isTrue);
      expect(macos1024.lengthSync(), greaterThan(10000));
    });
  });
}
