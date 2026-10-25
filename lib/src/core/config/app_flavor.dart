import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Multi-environment flavors following ADR 0006 (CodeWithAndrea + VGV hybrid)
/// so `dev` testing and preview channels never clash with `prod` community
/// data, Firebase Analytics, or Firebase Remote Config.
enum AppFlavor {
  dev('dev', 'Belong (Dev)', isProduction: false),
  stg('stg', 'Belong (Staging)', isProduction: false),
  qa('qa', 'Belong (QA)', isProduction: false),
  prod('prod', 'Belong on the Spectrum', isProduction: true);

  const AppFlavor(
    this.slug,
    this.displayName, {
    required this.isProduction,
  });

  /// Canonical base application / bundle identifier across Android, iOS, and macOS.
  static const String baseApplicationId = 'com.belongonthespectrum.refuge';

  /// Canonical base web domain.
  static const String baseDomain = 'belongonthespectrum.com';

  final String slug;
  final String displayName;
  final bool isProduction;

  /// Environment suffix appended to [baseApplicationId] for non-production builds
  /// (e.g., `.dev`, `.stg`, `.qa`, or `''` for production).
  String get applicationIdSuffix => isProduction ? '' : '.$slug';

  /// Full platform package / bundle identifier (e.g., `com.belongonthespectrum.refuge.dev`
  /// in `dev` or `com.belongonthespectrum.refuge` in `prod`).
  String get applicationId => '$baseApplicationId$applicationIdSuffix';

  /// Subdomain prefix for non-production web URLs (`dev.`, `stg.`, `qa.`, or `''` in `prod`).
  String get urlPrefix => isProduction ? '' : '$slug.';

  /// Hostname with subdomain prefix (`dev.belongonthespectrum.com` for non-prod,
  /// `www.belongonthespectrum.com` for `prod`).
  String get domainHost =>
      isProduction ? 'www.$baseDomain' : '$urlPrefix$baseDomain';

  /// Compact domain label for UI badges (`dev.belongonthespectrum.com` in `dev`,
  /// `belongonthespectrum.com` in `prod`).
  String get shortDomainLabel =>
      isProduction ? baseDomain : '$urlPrefix$baseDomain';

  /// Full canonical HTTPS URL for the active flavor (`https://dev.belongonthespectrum.com/`,
  /// `https://stg.belongonthespectrum.com/`, `https://qa.belongonthespectrum.com/`,
  /// `https://www.belongonthespectrum.com/`).
  String get websiteUrl => 'https://$domainHost/';

  /// Firebase Hosting origin for the active flavor (`https://dev-belongonthespectrum.web.app`
  /// or `https://belongonthespectrum.web.app` in `prod`).
  String get firebaseHostingUrl => isProduction
      ? 'https://belongonthespectrum.web.app'
      : 'https://$slug-belongonthespectrum.web.app';

  /// Default passwordless Magic Link redirect URL for the active flavor.
  String get magicLinkRedirectUrl => '$firebaseHostingUrl/auth';

  static AppFlavor fromString(String value) {
    return AppFlavor.values.firstWhere(
      (f) => f.slug.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => AppFlavor.dev,
    );
  }
}

/// Provides the active [AppFlavor] for the running instance.
final appFlavorProvider = Provider<AppFlavor>((ref) {
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  return AppFlavor.fromString(envFlavor);
});
