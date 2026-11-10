import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app manifest keeps the Android 14 media-projection permission.
///
/// stream_video_flutter merges the same permission. Declaring it here means
/// a later manifest tool that strips plugin permissions cannot drop screen
/// share by accident.
///
/// https://getstream.io/video/docs/flutter/advanced/background-modes/
void main() {
  test('Android declares the media projection foreground service', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION'));
    expect(manifest, contains('android.permission.FOREGROUND_SERVICE'));
    expect(manifest, contains('.intent.action.STREAM_CALL'));
    expect(manifest, isNot(contains('secret')));
    expect(manifest, isNot(contains('eyJ')));
  });
}
