import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A second WebRTC peer must receive screenshare video bytes.
///
/// Skips when this machine has no Chrome, so CI without a browser stays
/// green. The script launches headless Chrome with
/// `--use-fake-ui-for-media-stream` and
/// `--auto-select-desktop-capture-source=Entire screen`.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
void main() {
  test('a second peer receives screenshare video bytes', () async {
    final chrome = _chrome();
    if (chrome == null) {
      markTestSkipped('Chrome is not installed. The screenshare peer check did not run.');
      return;
    }
    final script = File('tool/screen_share_peer.mjs');
    expect(script.existsSync(), isTrue);
    final result = await Process.run('node', [script.path], environment: {'CHROME_PATH': chrome});
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final decoded = jsonDecode(result.stdout as String) as Map<String, Object?>;
    expect(decoded['ok'], isTrue);
    expect(decoded['bytesReceived'], greaterThan(0));
  });
}

String? _chrome() {
  const candidates = [
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}
