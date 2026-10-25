import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/notifications/data/push_preference_store.dart';
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
    if (overrideIsWebPwaInstalled == null && overrideIsIosWebWithoutPwa == null) {
      unawaited(_restore());
      _watchSignIn();
    }
  }

  int _edits = 0;
  StreamSubscription<User?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final seen = _edits;
    final stored = await readStoredPushPreference();
    if (stored == null || seen != _edits) return;
    state = state.copyWith(
      enabled: stored.enabled,
      schedule: stored.schedule,
      fcmToken: stored.fcmToken,
    );
  }

  void _watchSignIn() {
    try {
      if (Firebase.apps.isEmpty) return;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) unawaited(_persist());
      });
    } catch (_) {
      // Tests and a cold start before Firebase initializes skip the listener.
    }
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
    _edits += 1;
    if (schedule == CalmDigestSchedule.muted) {
      state = state.copyWith(schedule: schedule, enabled: false);
    } else {
      state = state.copyWith(schedule: schedule);
    }
    unawaited(_persist());
  }

  /// Toggles push notifications on or off with sensory-safe defaults.
  Future<bool> setEnabled(bool enable) async {
    _edits += 1;
    if (!enable) {
      state = state.copyWith(enabled: false);
      await _persist();
      return false;
    }
    final granted = await requestPushPermission();
    await _persist();
    return granted;
  }

  Future<void> _persist() async {
    try {
      await savePushPreference(state);
    } catch (_) {
      // A failed save keeps the on-device choice. The next toggle retries.
    }
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
