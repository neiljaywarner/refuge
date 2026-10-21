import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';

/// Service managing neurodivergent-first notification permissions and calm digest schedules.
class NotificationPermissionsService extends StateNotifier<CalmNotificationPreferences> {
  NotificationPermissionsService({
    CalmNotificationPreferences initialPreferences = const CalmNotificationPreferences(),
    bool? overrideIsWebPwaInstalled,
    bool? overrideIsIosWebWithoutPwa,
  }) : super(initialPreferences) {
    _initPlatformState(
      overrideIsWebPwaInstalled: overrideIsWebPwaInstalled,
      overrideIsIosWebWithoutPwa: overrideIsIosWebWithoutPwa,
    );
  }

  void _initPlatformState({
    bool? overrideIsWebPwaInstalled,
    bool? overrideIsIosWebWithoutPwa,
  }) {
    if (overrideIsWebPwaInstalled != null || overrideIsIosWebWithoutPwa != null) {
      state = state.copyWith(
        isWebPwaInstalled: overrideIsWebPwaInstalled ?? state.isWebPwaInstalled,
        isIosWebWithoutPwa: overrideIsIosWebWithoutPwa ?? state.isIosWebWithoutPwa,
      );
      return;
    }

    if (kIsWeb) {
      // In web, detect if running on iOS outside standalone PWA mode
      final userAgent = defaultTargetPlatform == TargetPlatform.iOS;
      state = state.copyWith(
        isWebPwaInstalled: false, // Default web tab
        isIosWebWithoutPwa: userAgent,
      );
    }
  }

  /// Updates the calm batched digest schedule without triggering urgent popups.
  void setSchedule(CalmDigestSchedule schedule) {
    if (schedule == CalmDigestSchedule.muted) {
      state = state.copyWith(schedule: schedule, enabled: false);
    } else {
      state = state.copyWith(schedule: schedule);
    }
  }

  /// Toggles push notifications on or off with sensory-safe defaults.
  Future<bool> setEnabled(bool enable) async {
    if (!enable) {
      state = state.copyWith(enabled: false);
      return false;
    }
    return requestPushPermission();
  }

  /// Requests notification permission with respectful transparency.
  Future<bool> requestPushPermission() async {
    if (state.isIosWebWithoutPwa) {
      // Mobile Safari cannot grant web push inside regular browser tabs.
      // Must be added to Home Screen first.
      return false;
    }

    // In production, this wires into FirebaseMessaging.instance.requestPermission()
    // and FirebaseMessaging.instance.getToken().
    const mockToken = 'fcm_token_calm_digest_alpha_preview';
    state = state.copyWith(
      enabled: true,
      fcmToken: mockToken,
    );
    return true;
  }
}

/// Global provider for [CalmNotificationPreferences].
final calmNotificationPreferencesProvider =
    StateNotifierProvider<NotificationPermissionsService, CalmNotificationPreferences>((ref) {
  return NotificationPermissionsService();
});
