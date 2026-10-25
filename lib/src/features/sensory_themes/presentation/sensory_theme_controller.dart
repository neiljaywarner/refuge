import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sensory_font_scale.dart';
import '../domain/sensory_mode.dart';

/// Riverpod StateNotifier managing the active SensoryMode.
class SensoryThemeNotifier extends StateNotifier<SensoryMode> {
  SensoryThemeNotifier([super.initial = SensoryMode.sage]);

  void setMode(SensoryMode newMode) {
    if (state != newMode) {
      state = newMode;
    }
  }

  void toggleHighContrast() {
    state = state == SensoryMode.contrast
        ? SensoryMode.sage
        : SensoryMode.contrast;
  }
}

/// Global provider for current sensory theme mode.
final sensoryThemeModeProvider =
    StateNotifierProvider<SensoryThemeNotifier, SensoryMode>(
      (ref) => SensoryThemeNotifier(),
    );

/// Riverpod StateNotifier managing the active SensoryFontScale (Issue #277).
class SensoryFontScaleNotifier extends StateNotifier<SensoryFontScale> {
  SensoryFontScaleNotifier([super.initial = SensoryFontScale.standard]);

  void setScale(SensoryFontScale newScale) {
    if (state != newScale) {
      state = newScale;
    }
  }
}

/// Global provider for sensory font scaling preset.
final sensoryFontScaleProvider =
    StateNotifierProvider<SensoryFontScaleNotifier, SensoryFontScale>(
      (ref) => SensoryFontScaleNotifier(),
    );

/// Legacy ChangeNotifier adapter for backward compatibility with existing tests and widgets.
class ThemeNotifier extends ChangeNotifier {
  SensoryMode _mode = SensoryMode.sage;
  SensoryMode get mode => _mode;

  SensoryFontScale _fontScale = SensoryFontScale.standard;
  SensoryFontScale get fontScale => _fontScale;

  void setMode(SensoryMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  void toggleHighContrast() {
    setMode(
      _mode == SensoryMode.contrast ? SensoryMode.sage : SensoryMode.contrast,
    );
  }

  void setFontScale(SensoryFontScale newScale) {
    if (_fontScale != newScale) {
      _fontScale = newScale;
      notifyListeners();
    }
  }
}
