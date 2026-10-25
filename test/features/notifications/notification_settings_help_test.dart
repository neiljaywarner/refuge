import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/notification_settings_help.dart';

void main() {
  test('each platform names the screen where notification options live', () {
    expect(
      notificationSettingsHelp(TargetPlatform.android),
      contains('Apps, then Belong, then Notifications'),
    );
    expect(
      notificationSettingsHelp(TargetPlatform.android),
      contains('Direct messages'),
    );
    expect(
      notificationSettingsHelp(TargetPlatform.iOS),
      contains('Settings, then Notifications, then Belong'),
    );
    expect(
      notificationSettingsHelp(TargetPlatform.macOS),
      contains('System Settings, then Notifications, then Belong'),
    );
    expect(
      notificationSettingsHelp(TargetPlatform.linux),
      contains('address bar'),
    );
  });
}
