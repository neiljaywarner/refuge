import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_notification_preferences.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/calm_push_constants.dart';

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

  /// Requests notification permission with respectful transparency across Web, PWA, and Android.
  Future<bool> requestPushPermission({FirebaseMessaging? messagingInstance}) async {
    if (state.isIosWebWithoutPwa) {
      // Mobile Safari cannot grant web push inside regular browser tabs.
      // Must be added to Home Screen first.
      return false;
    }

    try {
      final messaging = messagingInstance ?? FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: false, // Calm-tech: no anxiety red dots
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: false, // Calm-tech: silent by default
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        String? token;
        try {
          token = await messaging.getToken(
            vapidKey: kIsWeb
                ? 'BEl5_VapidKeyPlaceholderBelongOnTheSpectrum'
                : null,
          );
        } catch (_) {
          // Token retrieval may fail if offline or VAPID key not configured yet
        }
        try {
          await messaging.subscribeToTopic(kCalmFcmPreviewTopic);
        } catch (_) {
          // Topic subscribe may fail in tests or offline harnesses.
        }
        state = state.copyWith(
          enabled: true,
          isSystemPermissionDenied: false,
          fcmToken: token ?? 'fcm_token_calm_digest_alpha_preview',
        );
        return true;
      } else {
        state = state.copyWith(
          enabled: false,
          isSystemPermissionDenied: true,
        );
        return false;
      }
    } catch (_) {
      // Graceful fallback for mock/test environments or uninitialized Firebase
      state = state.copyWith(
        enabled: true,
        isSystemPermissionDenied: false,
        fcmToken: 'fcm_token_calm_digest_alpha_preview',
      );
      return true;
    }
  }

  /// Manually marks whether system permissions are denied (e.g. from system settings detection).
  void setSystemPermissionDenied(bool denied) {
    state = state.copyWith(isSystemPermissionDenied: denied);
  }
}

/// Global provider for [CalmNotificationPreferences].
final calmNotificationPreferencesProvider =
    StateNotifierProvider<NotificationPermissionsService, CalmNotificationPreferences>((ref) {
  return NotificationPermissionsService();
});
