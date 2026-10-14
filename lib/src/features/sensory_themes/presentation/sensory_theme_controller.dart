import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sensory_mode.dart';

/// Riverpod StateNotifier managing the active SensoryMode.
class SensoryThemeNotifier extends StateNotifier<SensoryMode> {
  SensoryThemeNotifier([super.initial = SensoryMode.sage]);

  void setMode(SensoryMode newMode) {
    if (state != newMode) {
      state = newMode;
    }
  }
}

/// Global provider for current sensory theme mode.
final sensoryThemeModeProvider =
    StateNotifierProvider<SensoryThemeNotifier, SensoryMode>(
  (ref) => SensoryThemeNotifier(),
);

/// Legacy ChangeNotifier adapter for backward compatibility with existing tests and widgets.
class ThemeNotifier extends ChangeNotifier {
  SensoryMode _mode = SensoryMode.sage;
  SensoryMode get mode => _mode;

  void setMode(SensoryMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }
}
