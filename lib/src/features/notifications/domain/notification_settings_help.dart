import 'package:flutter/foundation.dart';

/// Where the operating system keeps notification sound and permission.
///
/// The in-app Message alerts switch is Belong's on/off. This sentence points
/// at the system screen for the platform the member is using.
String notificationSettingsHelp(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
      return 'On Android, system notification options are in Settings, then Apps, then Belong, then Notifications. The Direct messages channel is where sound and banners are changed.';
    case TargetPlatform.iOS:
      return 'On iPhone, system notification options are in Settings, then Notifications, then Belong.';
    case TargetPlatform.macOS:
      return 'On Mac, system notification options are in System Settings, then Notifications, then Belong.';
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return 'In a browser, use the lock or tune icon in the address bar, then Notifications, to change sound and permission for this site.';
  }
}
