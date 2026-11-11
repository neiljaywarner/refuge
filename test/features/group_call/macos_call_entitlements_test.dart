import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sandboxed macOS builds can open outgoing call connections', () {
    for (final path in const [
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text, contains('com.apple.security.app-sandbox'));
      expect(text, contains('com.apple.security.network.client'));
    }
  });
}
