import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_flavor.dart';
import '../logging/app_logger.dart';
import 'firebase_installations_service.dart';
import 'in_app_messaging/in_app_messaging_service.dart';

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

  /// Default public configuration for Belong on the Spectrum Firebase project (Web PWA).
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyBtW8uQckI88rT1TPng459EVC9ynnm2twU',
    appId: '1:207506875171:web:5a5917af04e2540ab96296',
    messagingSenderId: '207506875171',
    projectId: 'belongonthespectrum',
    authDomain: 'belongonthespectrum.firebaseapp.com',
    storageBucket: 'belongonthespectrum.firebasestorage.app',
    measurementId: 'G-CFQY6FYYBM',
  );

  /// Default configuration for Belong on the Spectrum Firebase project (Android native).
  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'AIzaSyCqQdtP2D3lLGUch5BPExr4apoXaU9v0K0',
    appId: '1:207506875171:android:e578634c4bc21da2b96296',
    messagingSenderId: '207506875171',
    projectId: 'belongonthespectrum',
    storageBucket: 'belongonthespectrum.firebasestorage.app',
  );

  /// Initializes Firebase and configures Crashlytics + Analytics hooks.
  static Future<bool> initialize({required AppFlavor flavor}) async {
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      await _configureServices(flavor);
      await _activateRemoteConfig();
      return true;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(options: webOptions);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Native Android reads google-services.json or falls back to verified androidOptions.
        try {
          await Firebase.initializeApp();
        } catch (_) {
          await Firebase.initializeApp(options: androidOptions);
        }
      } else {
        // Native iOS reads GoogleService-Info.plist or uses webOptions fallback.
        try {
          await Firebase.initializeApp();
        } catch (_) {
          await Firebase.initializeApp(options: webOptions);
        }
      }

      _initialized = true;
      await _configureServices(flavor);
      await _activateRemoteConfig();
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
        await FirebaseCrashlytics.instance.setCustomKey(
          'environment',
          kReleaseMode ? 'release' : 'debug',
        );
      }

      // 2. Configure Analytics
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseAnalytics.instance.setUserProperty(name: 'flavor', value: flavor.slug);
      await FirebaseAnalytics.instance.setUserProperty(name: 'app_variant', value: 'belong_refuge');
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'is_debug_mode',
        value: kDebugMode ? 'true' : 'false',
      );

      const automationTool = String.fromEnvironment('AUTOMATION_TOOL', defaultValue: '');
      final resolvedAutomationTool = automationTool.isNotEmpty ? automationTool : 'none';
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'automation_tool',
        value: resolvedAutomationTool,
      );
      await FirebaseAnalytics.instance.setUserProperty(name: 'client_flavor', value: flavor.slug);

      // 3. Configure Firebase UI Auth providers (Email / Password / Reset)
      FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

      // 4. Configure In-App Messaging (Conditional on mobile, graceful stub on web)
      final fiam = createInAppMessagingService();
      await fiam.initialize();

      // 5. Query and record unique Firebase Installation ID for device troubleshooting
      final installationsService = FirebaseInstallationsService();
      final fid = await installationsService.getInstallationsId();
      await FirebaseAnalytics.instance.setUserProperty(name: 'installations_id', value: fid);
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCustomKey('installations_id', fid);
      }
    } catch (e) {
      talker.warning('⚠️ [FirebaseInitializer] Error configuring Firebase services: $e');
    }
  }

  /// Loads the published organizer allowlist before the first screen reads it.
  ///
  /// The in-app default for `admin_emails_csv` stays empty, so a failed fetch
  /// recognizes nobody. Production ignores `DEV_ADMIN_EMAILS`.
  static Future<void> _activateRemoteConfig() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 12),
        ),
      );
      await rc.setDefaults(const {
        'admin_emails_csv': '',
        'giphy_api_key': '',
        'giphy_api_key_android': '',
        'giphy_api_key_ios': '',
        'giphy_api_key_web': '',
        'giphy_content_rating': 'pg',
      });
      await rc.fetchAndActivate().timeout(const Duration(seconds: 8));
    } catch (e) {
      talker.warning('⚠️ [FirebaseInitializer] Remote Config fetch skipped: $e');
    }
  }
}
