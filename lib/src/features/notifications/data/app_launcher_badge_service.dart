import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Service responsible for updating the native app launcher icon badge
/// on iOS and Android devices, keeping unread notification count synchronized.
class AppLauncherBadgeService {
  static const MethodChannel _channel = MethodChannel(
    'com.belongonthespectrum.sanctuary/badge',
  );

  int _currentBadgeCount = 0;
  int get currentBadgeCount => _currentBadgeCount;

  /// Sets the launcher icon badge number.
  /// If [count] is 0, the badge is automatically removed/cleared.
  Future<bool> setBadgeCount(int count) async {
    _currentBadgeCount = count < 0 ? 0 : count;
    try {
      if (kIsWeb) return false;
      final result = await _channel.invokeMethod<bool>(
        'setBadgeCount',
        {'count': _currentBadgeCount},
      );
      return result ?? true;
    } catch (e) {
      // Graceful fallback for test runners or devices where launcher badge
      // provider is not supported or not yet bound.
      debugPrint('ℹ️ [LauncherBadge] setBadgeCount($_currentBadgeCount): $e');
      return false;
    }
  }

  /// Removes/clears the launcher icon badge.
  Future<bool> clearBadge() async {
    return setBadgeCount(0);
  }
}

final appLauncherBadgeServiceProvider = Provider<AppLauncherBadgeService>((ref) {
  return AppLauncherBadgeService();
});
