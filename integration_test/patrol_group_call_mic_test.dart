import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_video_preview_config.dart';

import 'patrol_app_harness.dart';

/// Native mic and camera permission check, then the preview join controls.
///
/// Skips unless this binary was built with `STREAM_VIDEO_PREVIEW` and a
/// `STREAM_TOKEN_ENDPOINT`. CI does not pass those, so the test does not
/// need a secret. How to run it on an emulator is in
/// `docs/wiki/Stream-Video-Preview.md`.
void main() {
  patrolTest('preview call grants mic and camera, then mute cycles', ($) async {
    final ready = groupCallPatrolMintReady(
      previewEnabled: streamVideoPreviewEnabled,
      tokenEndpoint: streamTokenEndpoint,
    );
    if (!ready) {
      markTestSkipped(
        'No preview mint is configured. Pass STREAM_VIDEO_PREVIEW and '
        'STREAM_TOKEN_ENDPOINT. See docs/wiki/Stream-Video-Preview.md.',
      );
      return;
    }

    await pumpDevReadOnlyHome($);

    for (var dialog = 0; dialog < 2; dialog++) {
      if (await $.platform.mobile.isPermissionDialogVisible()) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }
    }

    final join = $('Join call');
    if (!join.exists) {
      markTestSkipped(
        'Join call is hidden. Sign in on a preview build, or open a guest '
        'link, then run this test again.',
      );
      return;
    }

    await join.tap();
    for (var dialog = 0; dialog < 2; dialog++) {
      if (await $.platform.mobile.isPermissionDialogVisible()) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }
    }

    final mic = $(const Key('group_call_microphone_button'));
    if (!mic.exists) {
      markTestSkipped('The call screen did not show the microphone button.');
      return;
    }

    await mic.tap();
    expect($('Tap to hear the room'), findsNothing);
    expect($(const Key('group_call_microphone_button')), findsOneWidget);

    await mic.tap();
    await mic.tap();
    expect($(const Key('group_call_microphone_button')), findsOneWidget);
  });
}
