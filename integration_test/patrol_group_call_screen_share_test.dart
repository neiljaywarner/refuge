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

    // Home opens the lobby. The lobby confirms with the same "Join call" label.
    final confirm = $(const Key('group_call_confirm_join_button'));
    await confirm.waitUntilVisible();
    await confirm.tap();
    await _grantRuntimeDialogs($);

    final mic = $(const Key('group_call_microphone_button'));
    await mic.waitUntilVisible();

    final share = $(const Key('group_call_share_button'));
    if (!share.exists) {
      markTestSkipped(
        'The call is open, and Share is hidden. Stream did not grant '
        'screenshare, or this guest harness is still waiting for the host.',
      );
      return;
    }

    await share.tap();
    await _acceptCaptureDialog($);
    await $('Stop sharing').waitUntilVisible();
    expect($('You are sharing'), findsOneWidget);

    await $('Stop sharing').tap();
    await $('Share screen').waitUntilVisible();
    expect($('You are sharing'), findsNothing);
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
/// "Share screen" is last because that is also the in-app button label.
Future<void> _acceptCaptureDialog(PatrolIntegrationTester $) async {
  const labels = ['Entire screen', 'Start now', 'Start', 'Share screen'];
  var accepted = false;
  for (final label in labels) {
    try {
      await $.platform.android.tap(
        AndroidSelector(text: label),
        timeout: const Duration(seconds: 2),
      );
      accepted = true;
    } catch (_) {}
  }
  expect(accepted, isTrue, reason: 'The capture dialog had no Start or Start now.');
}
