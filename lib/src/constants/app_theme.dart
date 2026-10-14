import 'package:flutter/material.dart';

import '../features/sensory_themes/domain/sensory_mode.dart';

class SensoryThemeData {
  static ThemeData getTheme(SensoryMode mode) => switch (mode) {
    SensoryMode.clean => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        surface: const Color(0xFFFAFAFA),
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
    ),
    SensoryMode.sage => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A7C59),
        surface: const Color(0xFFE6ECE8),
        primary: const Color(0xFF4A7C59),
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFDDE5E0),
    ),
    SensoryMode.charcoal => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1D20),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF68A67D), surface: Color(0xFF24282D)),
      cardColor: const Color(0xFF24282D),
      dividerColor: const Color(0xFF333A42),
    ),
    SensoryMode.contrast => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFEB3B),
        surface: Color(0xFF0F0F0F),
        onSurface: Colors.white,
      ),
      cardColor: Colors.black,
      dividerColor: Colors.white,
    ),
  };
}
