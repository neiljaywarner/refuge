import 'package:flutter/material.dart';

import '../core/theme/belong_text_styles.dart';
import '../features/sensory_themes/domain/sensory_mode.dart';

class SensoryThemeData {
  static ThemeData getTheme(SensoryMode mode) {
    final theme = switch (mode) {
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8CD4A2),
          onPrimary: Color(0xFF0F1A12),
          primaryContainer: Color(0xFF233829),
          onPrimaryContainer: Color(0xFFC7EBCF),
          secondary: Color(0xFF8CD4A2),
          onSecondary: Color(0xFF0F1A12),
          secondaryContainer: Color(0xFF27382E),
          onSecondaryContainer: Color(0xFFE2E8F0),
          surface: Color(0xFF24282D),
          onSurface: Color(0xFFF1F5F9),
          surfaceContainer: Color(0xFF2A2F35),
          surfaceContainerHigh: Color(0xFF333A42),
          outline: Color(0xFF6B7885),
          outlineVariant: Color(0xFF4A5560),
        ),
        cardColor: const Color(0xFF24282D),
        dividerColor: const Color(0xFF3E4752),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF252A2F),
          selectedColor: Color(0xFF27382E),
          side: BorderSide(color: Color(0xFF4A5560), width: 1.0),
          labelStyle: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: TextStyle(
            color: Color(0xFF8CD4A2),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          checkmarkColor: Color(0xFF8CD4A2),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      SensoryMode.contrast => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFEB3B),
          onPrimary: Colors.black,
          secondary: Color(0xFFFFEB3B),
          onSecondary: Colors.black,
          secondaryContainer: Color(0xFF2B2600),
          onSecondaryContainer: Color(0xFFFFEB3B),
          surface: Color(0xFF0F0F0F),
          onSurface: Colors.white,
        ),
        cardColor: Colors.black,
        dividerColor: Colors.white,
        chipTheme: const ChipThemeData(
          selectedColor: Color(0xFFFFEB3B),
          labelStyle: TextStyle(color: Colors.white),
          secondaryLabelStyle: TextStyle(color: Colors.black),
        ),
      ),
    };
    return theme.copyWith(
      extensions: [BelongTextStyles.forTheme(theme, contrast: mode == SensoryMode.contrast)],
    );
  }
}
