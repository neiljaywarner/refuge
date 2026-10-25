import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Belong launcher icons and splash logo exist as valid PNGs', () async {
    const requiredAssets = <String, int>{
      'assets/images/belong_logo.png': 1024,
      'android/app/src/main/res/drawable/launch_logo.png': 288,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-512.png': 512,
    };

    for (final entry in requiredAssets.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: 'Expected ${entry.key} to exist');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, entry.value, reason: entry.key);
      expect(frame.image.height, entry.value, reason: entry.key);
    }
  });

  test('Android launch splash references calm sanctuary colors', () {
    final launchBg = File('android/app/src/main/res/drawable/launch_background.xml')
        .readAsStringSync();
    expect(launchBg, contains('@color/launch_background'));
    expect(launchBg, contains('@drawable/launch_logo'));

    final colors = File('android/app/src/main/res/values/ic_launcher_background.xml')
        .readAsStringSync();
    expect(colors, contains('launch_background'));
    expect(colors, contains('#F2EEE2'));
  });
}
