import 'package:flutter/material.dart';

import '../../../core/theme/belong_text_styles.dart';

/// Fireside `minimal-dark` colors from bemadiscipleship.com.
///
/// `body` is `#222222` with white text. `.fixed-header` and `.hero-player`
/// are `#2A2A2A`. `.prose a` and `.episode-details a` are `#2EA4F9`,
/// hover `#1599F8`.
ThemeData bemaDiscussionTheme() {
  const background = Color(0xFF222222);
  const surface = Color(0xFF2A2A2A);
  const primary = Color(0xFF2EA4F9);
  const primaryHover = Color(0xFF1599F8);
  const onPrimary = Color(0xFF0E1A24);
  const hairline = Color(0x14FFFFFF);
  final scheme = ColorScheme.dark(
    primary: primary,
    onPrimary: onPrimary,
    secondary: primaryHover,
    onSecondary: onPrimary,
    surface: surface,
    onSurface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: surface,
    dividerColor: hairline,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    extensions: [BelongTextStyles.forTheme(base)],
  );
}
