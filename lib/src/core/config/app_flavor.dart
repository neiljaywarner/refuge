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

  final String slug;
  final String displayName;
  final bool isProduction;

  static AppFlavor fromString(String value) {
    return AppFlavor.values.firstWhere(
      (f) => f.slug.toLowerCase() == value.toLowerCase(),
      orElse: () => AppFlavor.dev,
    );
  }
}

/// Provides the active [AppFlavor] for the running instance.
final appFlavorProvider = Provider<AppFlavor>((ref) {
  const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  return AppFlavor.fromString(envFlavor);
});
