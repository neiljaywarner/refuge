import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../firebase/organizer_remote_config_service.dart';

/// StateNotifier that manages the single master **Preview Mode** flag.
///
/// Priority:
/// 1. Local explicit user toggle override (if set).
/// 2. Remote Config default (`organizer_preview_mode_enabled`).
/// 3. False (safe default: experimental features hidden).
class PreviewModeNotifier extends StateNotifier<bool> {
  PreviewModeNotifier(super.initial);

  void toggle() => state = !state;
  void setEnabled(bool value) => state = value;
}

/// Explicit local user override (null = use Remote Config default).
final previewModeUserOverrideProvider = StateProvider<bool?>((ref) => null);

/// Single master provider for checking whether experimental preview features
/// should be displayed across the app.
final previewFeaturesEnabledProvider = StateNotifierProvider<PreviewModeNotifier, bool>((ref) {
  final remoteConfig = ref.watch(organizerRemoteConfigProvider);
  final userOverride = ref.watch(previewModeUserOverrideProvider);
  final effective = userOverride ?? remoteConfig.previewModeEnabled;
  return PreviewModeNotifier(effective);
});
