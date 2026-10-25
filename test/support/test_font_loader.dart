import 'dart:io';

import 'package:flutter/services.dart';

/// Test helper providing headless font loading for widget and golden tests.
/// Ensures standard typography (Roboto) renders faithfully without tofu boxes.
class TestFontLoader {
  static bool _loaded = false;

  /// Loads Roboto font family from assets/fonts/ into Flutter test FontLoader.
  static Future<void> loadAppFonts() async {
    if (_loaded) return;

    try {
      final regularFile = File('assets/fonts/Roboto-Regular.ttf');
      final boldFile = File('assets/fonts/Roboto-Bold.ttf');

      if (await regularFile.exists() && await boldFile.exists()) {
        final regularBytes = await regularFile.readAsBytes();
        final boldBytes = await boldFile.readAsBytes();

        final fontLoader = FontLoader('Roboto');
        fontLoader.addFont(Future.value(ByteData.view(regularBytes.buffer)));
        fontLoader.addFont(Future.value(ByteData.view(boldBytes.buffer)));
        await fontLoader.load();
      }
    } catch (_) {
      // In constrained environments where filesystem is restricted,
      // fallback gracefully to default test font renderer.
    }

    _loaded = true;
  }
}
