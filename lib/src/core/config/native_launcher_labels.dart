/// Native launcher titles shared by [AppFlavor], Gradle, iOS, and CLI tools.
///
/// Kept free of Flutter/Riverpod so `dart run tool/...` works on CI.
library;

/// Production home-screen / launcher title.
const productionLauncherTitle = 'Belong on the Spectrum';

/// VGV-style `[ENV]` prefix title for non-production flavor slugs.
String launcherTitleForFlavorSlug(String slug, {required bool isProduction}) {
  if (isProduction) return productionLauncherTitle;
  final normalized = slug.trim().toLowerCase();
  if (normalized.isEmpty) return productionLauncherTitle;
  return '[${normalized.toUpperCase()}] $productionLauncherTitle';
}

/// Dev flavor launcher label (Test Lab + App Distribution badging).
const devLauncherTitle = '[DEV] $productionLauncherTitle';
