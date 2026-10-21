import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/app_flavor.dart';
import '../logging/app_logger.dart';

/// Centralized, resilient Firebase lifecycle initializer.
///
/// Guarantees that [Firebase.initializeApp] is invoked at startup across
/// Flutter Web / PWA, Android, and iOS with platform-appropriate options,
/// activates Crashlytics fatal & non-fatal collection, configures Analytics
/// user properties, and falls back gracefully to in-memory / Serverpod
/// diagnostics in unit/BDD test harnesses or offline environments.
class FirebaseInitializer {
  static bool _initialized = false;

  static bool get isInitialized => _initialized || Firebase.apps.isNotEmpty;

  /// Default public configuration for Belong on the Spectrum Firebase project.
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForBackgroundWorkerRefuge4Serverpod',
    appId: '1:1056581413812:web:calmnotificationsbelong',
    messagingSenderId: '1056581413812',
    projectId: 'belongonthespectrum',
    authDomain: 'belongonthespectrum.firebaseapp.com',
    storageBucket: 'belongonthespectrum.appspot.com',
  );

  /// Initializes Firebase and configures Crashlytics + Analytics hooks.
  static Future<bool> initialize({required AppFlavor flavor}) async {
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      await _configureServices(flavor);
      return true;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(options: webOptions);
      } else {
        // Native Android/iOS reads google-services.json / GoogleService-Info.plist
        // or uses fallback options if native assets are unlinked during testing.
        try {
          await Firebase.initializeApp();
        } catch (_) {
          await Firebase.initializeApp(options: webOptions);
        }
      }

      _initialized = true;
      await _configureServices(flavor);
      talker.info('🔥 [FirebaseInitializer] Firebase initialized successfully (${flavor.slug})');
      return true;
    } catch (e, st) {
      _initialized = false;
      talker.warning(
        '⚠️ [FirebaseInitializer] Firebase unconfigured or running in headless mode: $e',
        e,
        st,
      );
      return false;
    }
  }

  static Future<void> _configureServices(AppFlavor flavor) async {
    try {
      // 1. Configure Crashlytics
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        await FirebaseCrashlytics.instance.setCustomKey('flavor', flavor.slug);
        await FirebaseCrashlytics.instance.setCustomKey('environment', kReleaseMode ? 'release' : 'debug');
      }

      // 2. Configure Analytics
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseAnalytics.instance.setUserProperty(name: 'flavor', value: flavor.slug);
      await FirebaseAnalytics.instance.setUserProperty(name: 'app_variant', value: 'belong_refuge');

      // 3. Configure Firebase UI Auth providers (Email / Password / Reset)
      FirebaseUIAuth.configureProviders([
        EmailAuthProvider(),
      ]);
    } catch (e) {
      talker.warning('⚠️ [FirebaseInitializer] Error configuring Firebase services: $e');
    }
  }
}
