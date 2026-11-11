import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import 'group_call_screen_share.dart';

/// Debug log for screen share (#928).
///
/// Release builds stay quiet. The line starts with `[#screenshare]` so
/// `adb logcat` can grep it. Names, emails, and tokens are not written.
void logGroupCallScreenShare(String detail) {
  if (!kDebugMode) return;
  AppLogger.debug(groupCallScreenShareLine(detail));
}

/// Prefixes [detail] and strips an email or a JWT if one was passed in.
String groupCallScreenShareLine(String detail) {
  final cleaned = detail
      .replaceAll(RegExp(r'\S+@\S+'), 'redacted')
      .replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]+'), 'redacted');
  return '[#screenshare] $cleaned';
}

/// A start or stop request. The platform name is web, android, ios, or other.
String groupCallScreenShareRequest({
  required bool enabled,
  required GroupCallSharePlatform platform,
  required bool granted,
  required bool guest,
}) => 'request enabled=$enabled platform=${platform.name} granted=$granted guest=$guest';

/// Whether the publish was accepted. The Stream error text is not included.
String groupCallScreenShareResult({required bool enabled, required bool accepted}) =>
    'result enabled=$enabled accepted=$accepted';

/// Who is on the main tile, without a name or an id.
String groupCallScreenShareViewLine({required bool someoneSharing, required bool localSharing}) =>
    'view someoneSharing=$someoneSharing localSharing=$localSharing';
