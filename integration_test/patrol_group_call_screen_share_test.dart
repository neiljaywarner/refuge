import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/src/features/group_call/data/stream_video_preview_config.dart';

import 'patrol_app_harness.dart';

/// Accepts Android's system capture dialog, then leaves the share button up.
///
/// Skips unless this binary was built with `STREAM_VIDEO_PREVIEW` and a
/// `STREAM_TOKEN_ENDPOINT`. It does not store a Stream secret. A second
/// device's getStats check is not part of this file: there is no second
/// peer on the machine that runs it.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
/// (`call.requestScreenSharePermission` shows the system dialog on Android 14)
void main() {
  patrolTest('preview screen share accepts the capture dialog', ($) async {
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
    await _grantRuntimeDialogs($);

    final join = $('Join call');
    if (!join.exists) {
      markTestSkipped(
        'Join call is hidden. Sign in on a preview build, or open a guest '
        'link, then run this test again.',
      );
      return;
    }

    await join.tap();
    await _grantRuntimeDialogs($);

    final share = $(const Key('group_call_share_button'));
    if (!share.exists) {
      markTestSkipped(
        'Share is hidden. Stream did not grant screenshare, or this person '
        'is a guest and the host has not allowed it.',
      );
      return;
    }

    await share.tap();
    await _acceptCaptureDialog($);
    expect($(const Key('group_call_share_button')), findsOneWidget);

    await share.tap();
    expect($(const Key('group_call_share_button')), findsOneWidget);
  });
}

Future<void> _grantRuntimeDialogs(PatrolIntegrationTester $) async {
  for (var dialog = 0; dialog < 2; dialog++) {
    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
  }
}

/// The MediaProjection sheet is outside the Flutter tree. Labels vary by
/// Android version: "Entire screen", then "Start" or "Start now".
Future<void> _acceptCaptureDialog(PatrolIntegrationTester $) async {
  const labels = ['Entire screen', 'Share screen', 'Start now', 'Start'];
  for (final label in labels) {
    try {
      await $.platform.android.tap(
        AndroidSelector(text: label),
        timeout: const Duration(seconds: 2),
      );
    } catch (_) {}
  }
}
