import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'native_launcher_labels.dart';

/// Multi-environment flavors following ADR 0006 (CodeWithAndrea + VGV hybrid)
/// so `dev` testing and preview channels never clash with `prod` community
/// data, Firebase Analytics, or Firebase Remote Config.
///
/// **Active flavors today**: [dev] and [prod] only.
/// [stg] and [qa] remain enum hooks for [#40](https://github.com/neiljaywarner/refuge/issues/40)
/// and are not deployed yet.
///
/// Web app origins use Firebase Hosting (`*.web.app`), parallel to Android
/// `applicationId` suffixes (`.dev` / none for prod):
/// - prod → `https://belongonthespectrum.web.app/`
/// - dev → `https://dev-belongonthespectrum.web.app/`
///
/// The marketing / Circle site (`https://www.belongonthespectrum.com/`) is
/// separate from the Flutter web app hosting origin.
enum AppFlavor {
  dev('dev', isProduction: false),
  stg('stg', isProduction: false),
  qa('qa', isProduction: false),
  prod('prod', isProduction: true);

  const AppFlavor(this.slug, {required this.isProduction});

  /// Canonical production marketing name (launcher title when [isProduction]).
  static const String productionMarketingName = productionLauncherTitle;

  /// Canonical base application / bundle identifier across Android, iOS, and macOS.
  static const String baseApplicationId = 'com.belongonthespectrum.refuge';

  /// Public marketing / community website domain (not the Flutter web app host).
  static const String marketingDomain = 'belongonthespectrum.com';

  /// Firebase Hosting base domain for the Flutter web / PWA app.
  static const String hostingBaseDomain = 'belongonthespectrum.web.app';

  /// Legacy alias for [marketingDomain]. Prefer [hostingBaseDomain] for web app
  /// origins and [marketingDomain] for the brand site.
  static const String baseDomain = marketingDomain;

  final String slug;
  final bool isProduction;

  /// Home-screen / launcher title. Non-production flavors use a VGV-style
  /// `[ENV]` prefix so dev and prod installs are easy to tell apart.
  String get launcherTitle =>
      launcherTitleForFlavorSlug(slug, isProduction: isProduction);

  /// Human-readable name (same as [launcherTitle]).
  String get displayName => launcherTitle;

  /// Short uppercase tag for in-app chrome when not production (`DEV`, `STG`, …).
  String? get environmentTag => isProduction ? null : slug.toUpperCase();

  /// Environment suffix appended to [baseApplicationId] for non-production builds
  /// (e.g., `.dev`, `.stg`, `.qa`, or `''` for production).
  String get applicationIdSuffix => isProduction ? '' : '.$slug';

  /// Full platform package / bundle identifier (e.g., `com.belongonthespectrum.refuge.dev`
  /// in `dev` or `com.belongonthespectrum.refuge` in `prod`).
  String get applicationId => '$baseApplicationId$applicationIdSuffix';

  /// Firebase Hosting site-name prefix for non-production (`dev-`, `stg-`, `qa-`,
  /// or `''` in `prod`), mirroring Android [applicationIdSuffix].
  String get urlPrefix => isProduction ? '' : '$slug-';

  /// Firebase Hosting hostname (`dev-belongonthespectrum.web.app` for non-prod,
  /// `belongonthespectrum.web.app` for `prod`).
  String get domainHost => '$urlPrefix$hostingBaseDomain';

  /// Compact domain label for UI badges (`dev-belongonthespectrum.web.app` in
  /// `dev`, `belongonthespectrum.web.app` in `prod`).
  String get shortDomainLabel => domainHost;

  /// Full canonical HTTPS URL for the active flavor's web app
  /// (`https://dev-belongonthespectrum.web.app/` or
  /// `https://belongonthespectrum.web.app/` in `prod`).
  String get websiteUrl => 'https://$domainHost/';

  /// Firebase Hosting origin for the active flavor (same host as [websiteUrl],
  /// without a trailing slash).
  String get firebaseHostingUrl => 'https://$domainHost';

  /// Default passwordless Magic Link redirect URL for the active flavor.
  String get magicLinkRedirectUrl => '$firebaseHostingUrl/auth';

  /// Marketing / Circle website (flavor-independent brand home page).
  static const String marketingWebsiteUrl =
      'https://www.belongonthespectrum.com/';

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
