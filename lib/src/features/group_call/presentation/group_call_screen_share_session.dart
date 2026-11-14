import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../domain/group_call_screen_share.dart';

/// Android MediaProjection consent and the screen-share foreground service.
///
/// The live app uses [streamAndroidShareHooks]. Tests pass a stand-in.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
/// https://getstream.io/video/docs/flutter/advanced/background-modes/
class GroupCallAndroidShareHooks {
  const GroupCallAndroidShareHooks({
    required this.requestConsent,
    required this.startNotification,
    required this.stopNotification,
  });

  /// `call.requestScreenSharePermission()`. Android 14 shows the system
  /// capture dialog. False means the person cancelled.
  final Future<bool> Function(Call call) requestConsent;

  /// `StreamBackgroundService().startScreenSharingNotificationService(call)`.
  /// Android 14 requires `FOREGROUND_SERVICE_MEDIA_PROJECTION` to be running
  /// before the capture starts.
  final Future<bool> Function(Call call) startNotification;

  /// `StreamBackgroundService().stopScreenSharingNotificationService(callCid)`.
  final Future<void> Function(String callCid) stopNotification;
}

/// Registers Android notification handlers for one [StreamVideo] client.
///
/// [StreamBackgroundService.init] is what stops the track when the person
/// taps Stop on the screen-share notification, and what stops the service
/// when capture ends outside the app. Web and iOS do not use that service.
/// Call this after the preview client is created, and before a share starts.
///
/// https://getstream.io/video/docs/flutter/advanced/background-modes/
void prepareGroupCallScreenShare({
  required GroupCallSharePlatform platform,
  required void Function() registerAndroidHandlers,
}) {
  if (platform != GroupCallSharePlatform.android) return;
  registerAndroidHandlers();
}

/// Hooks that call Stream's Android screen-share service.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
GroupCallAndroidShareHooks streamAndroidShareHooks() => GroupCallAndroidShareHooks(
  requestConsent: (call) => call.requestScreenSharePermission(),
  startNotification: (call) =>
      StreamBackgroundService().startScreenSharingNotificationService(call),
  stopNotification: (callCid) =>
      StreamBackgroundService().stopScreenSharingNotificationService(callCid),
);

/// Starts or stops a share on web or Android.
///
/// Web calls `call.setScreenShareEnabled`. The SDK asks the browser for
/// `getDisplayMedia`, and stops the share when that track ends.
/// Android asks for capture consent, starts the media-projection foreground
/// service, then enables the track. A failed start stops the service.
/// iOS is refused here. A broadcast extension is a follow-up.
///
/// https://getstream.io/video/docs/flutter/guides/screensharing/
Future<Result<None>> setGroupCallScreenShare(
  Call call, {
  required bool enabled,
  required GroupCallSharePlatform platform,
  GroupCallAndroidShareHooks? android,
  bool Function()? stillAllowed,
}) async {
  if (platform == GroupCallSharePlatform.android) {
    final hooks = android;
    if (hooks == null) {
      return Result.error('Screen sharing is not available on this device.');
    }
    return _setAndroidShare(call, enabled: enabled, hooks: hooks, stillAllowed: stillAllowed);
  }
  if (platform != GroupCallSharePlatform.web) {
    return Result.error('Screen sharing is not available on this device.');
  }
  // Web: setScreenShareEnabled uses getDisplayMedia. The SDK assigns
  // mediaTrack.onEnded so closing the browser share bar stops the track.
  // https://getstream.io/video/docs/flutter/guides/screensharing/
  return call.setScreenShareEnabled(enabled: enabled);
}

Future<Result<None>> _setAndroidShare(
  Call call, {
  required bool enabled,
  required GroupCallAndroidShareHooks hooks,
  bool Function()? stillAllowed,
}) async {
  if (!enabled) {
    final result = await call.setScreenShareEnabled(enabled: false);
    await hooks.stopNotification(call.callCid.value);
    return result;
  }
  if (!await hooks.requestConsent(call)) {
    return Result.error('Screen sharing stayed as it was.');
  }
  // The host can turn guest sharing off while the system dialog is open.
  // Stopping does not use this check.
  if (stillAllowed != null && !stillAllowed()) {
    return Result.error('Screen sharing stayed as it was.');
  }
  if (!await hooks.startNotification(call)) {
    return Result.error('Screen sharing stayed as it was.');
  }
  if (stillAllowed != null && !stillAllowed()) {
    await hooks.stopNotification(call.callCid.value);
    return Result.error('Screen sharing stayed as it was.');
  }
  final result = await call.setScreenShareEnabled(enabled: true);
  if (result.isFailure) {
    await hooks.stopNotification(call.callCid.value);
  }
  return result;
}
