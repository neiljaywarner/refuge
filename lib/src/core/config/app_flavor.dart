import 'package:flutter/foundation.dart';
import 'app_logger.dart';

enum AppFlavor { dev, staging, prod }

class AppFlavorConfig {
  static const String _flavorStr = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static AppFlavor get current {
    switch (_flavorStr.toLowerCase()) {
      case 'prod':
        return AppFlavor.prod;
      case 'staging':
        return AppFlavor.staging;
      case 'dev':
      default:
        return AppFlavor.dev;
    }
  }

  static bool get isDev => current == AppFlavor.dev;
  static bool get isStaging => current == AppFlavor.staging;
  static bool get isProd => current == AppFlavor.prod;

  static String get serverpodUrl {
    if (kIsWeb) return 'http://localhost:8080/';
    switch (current) {
      case AppFlavor.prod:
        return 'https://api.belongonthespectrum.com/';
      case AppFlavor.staging:
        return 'https://staging.belongonthespectrum.com/';
      case AppFlavor.dev:
        return defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8080/'
            : 'http://localhost:8080/';
    }
  }

  static void logCurrentFlavor() => AppLogger.info(
    '🚀 [FlavorConfig] Active Flavor: ${current.name.toUpperCase()} (Target: $serverpodUrl)',
  );
}
