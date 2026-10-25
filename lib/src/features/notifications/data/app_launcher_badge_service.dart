import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Service responsible for updating the native app launcher icon badge
/// on iOS and Android devices, keeping unread notification count synchronized.
class AppLauncherBadgeService {
  static const MethodChannel _channel = MethodChannel(
    'com.belongonthespectrum.refuge/badge',
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
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[AppLauncherBadgeService] Failed to set badge count: $e');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clears the app badge count to 0.
  Future<bool> clearBadge() => setBadgeCount(0);
}

/// Riverpod provider for [AppLauncherBadgeService].
final appLauncherBadgeServiceProvider = Provider<AppLauncherBadgeService>((ref) {
  return AppLauncherBadgeService();
});
