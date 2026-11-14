import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Explicit local user override (null = use Remote Config or the stored switch).
final previewModeUserOverrideProvider = StateProvider<bool?>((ref) => null);
