import 'dart:io';

import 'package:flutter/services.dart';

/// Test helper providing headless font loading for widget and golden tests.
/// Ensures standard typography (Roboto) and MaterialIcons render faithfully
/// without Ahem tofu boxes, even inside `flutter_test` FakeAsync zones.
class TestFontLoader {
  static bool _loaded = false;

  /// Loads Roboto and MaterialIcons font families into Flutter test FontLoader.
  static Future<void> loadAppFonts() async {
    if (_loaded) return;

    try {
      final regularFile = File('assets/fonts/Roboto-Regular.ttf');
      final boldFile = File('assets/fonts/Roboto-Bold.ttf');

      if (regularFile.existsSync() && boldFile.existsSync()) {
        final regularBytes = regularFile.readAsBytesSync();
        final boldBytes = boldFile.readAsBytesSync();

        for (final family in [
          'Roboto',
          '.AppleSystemUIFont',
          '.SF UI Text',
          '.SF Pro Text',
          '.SF UI Display',
          'sans-serif',
        ]) {
          final fontLoader = FontLoader(family);
          fontLoader.addFont(Future.value(ByteData.view(regularBytes.buffer)));
          fontLoader.addFont(Future.value(ByteData.view(boldBytes.buffer)));
          await fontLoader.load();
        }
      }

      // Also load MaterialIcons from Flutter SDK cache if available
      final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
      final materialIconsFile = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (materialIconsFile.existsSync()) {
        final iconBytes = materialIconsFile.readAsBytesSync();
        final iconLoader = FontLoader('MaterialIcons');
        iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
        await iconLoader.load();
      }
    } catch (_) {
      // Fallback gracefully in restricted environments.
    }

    _loaded = true;
  }
}
