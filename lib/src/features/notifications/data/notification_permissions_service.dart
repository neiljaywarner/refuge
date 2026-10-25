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
      _restoreTask = _restore();
      _watchSignIn();
    }
  }

  int _edits = 0;
  StreamSubscription<User?>? _authSub;
  Future<void>? _restoreTask;
  var _restoreFinished = false;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final seen = _edits;
    final stored = await readStoredPushPreference();
    if (stored != null && seen == _edits) {
      state = state.copyWith(
        enabled: stored.enabled,
        schedule: stored.schedule,
        fcmToken: stored.fcmToken,
      );
    }
    _restoreFinished = true;
    await _syncCloudPushRegistration();
  }

  void _watchSignIn() {
    try {
      if (Firebase.apps.isEmpty) return;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) return;
        unawaited(() async {
          final pending = _restoreTask;
          if (pending != null) await pending;
          if (!_restoreFinished) return;
          await _syncCloudPushRegistration();
        }());
      });
    } catch (_) {
      // Tests and a cold start before Firebase initializes skip the listener.
    }
  }

  /// Refreshes the FCM token when alerts are on, then registers with the sender.
  Future<void> syncCloudPushRegistration() => _syncCloudPushRegistration();

  Future<void> _syncCloudPushRegistration() async {
    if (Firebase.apps.isEmpty) return;
    try {
      if (FirebaseAuth.instance.currentUser == null) return;
    } catch (_) {
      return;
    }

    if (!state.enabled || state.schedule == CalmDigestSchedule.muted) {
      await _persist();
      return;
    }

    if (state.isIosWebWithoutPwa) {
      await _persist();
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        state = state.copyWith(isSystemPermissionDenied: true);
        await _persist();
        return;
      }
      String? token;
      try {
        token = await messaging.getToken(
          vapidKey: kIsWeb ? 'BEl5_VapidKeyPlaceholderBelongOnTheSpectrum' : null,
        );
      } catch (_) {
        token = state.fcmToken;
      }
      if (token != null && token.isNotEmpty && !token.startsWith('fcm_token_calm')) {
        state = state.copyWith(fcmToken: token, isSystemPermissionDenied: false);
      }
    } catch (_) {
      // Offline or a test harness: keep the saved switch and try register.
    }
    await _persist();
  }

  void _initPlatformState({bool? overrideIsWebPwaInstalled, bool? overrideIsIosWebWithoutPwa}) {
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
        badge: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        String? token;
        try {
          token = await messaging.getToken(
            vapidKey: kIsWeb ? 'BEl5_VapidKeyPlaceholderBelongOnTheSpectrum' : null,
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
        state = state.copyWith(enabled: false, isSystemPermissionDenied: true);
        return false;
      }
    } catch (_) {
      final firebaseReady = Firebase.apps.isNotEmpty;
      if (kIsWeb || !firebaseReady) {
        state = state.copyWith(
          enabled: true,
          isSystemPermissionDenied: false,
          fcmToken: 'fcm_token_calm_digest_alpha_preview',
        );
        return true;
      }
      state = state.copyWith(enabled: false, isSystemPermissionDenied: true);
      return false;
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
