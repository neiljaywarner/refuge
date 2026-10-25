import 'package:flutter/material.dart';

/// Four text roles for Belong screens.
///
/// Use these instead of inline `TextStyle(fontSize: ..., color: ...)`.
/// Sensory font scale still applies through the app [TextScaler].
/// Contrast mode is baked in when the theme is built, so a widget does not
/// repeat yellow-on-black colors.
class BelongTextStyles extends ThemeExtension<BelongTextStyles> {
  const BelongTextStyles({
    required this.title,
    required this.body,
    required this.caption,
    required this.emphasis,
  });

  /// Screen and dialog titles.
  final TextStyle title;

  /// Ordinary reading text.
  final TextStyle body;

  /// Timestamps, build stamps, and other secondary lines.
  final TextStyle caption;

  /// Names and short labels that should stand out from body text.
  final TextStyle emphasis;

  static BelongTextStyles of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BelongTextStyles>() ?? forTheme(theme);
  }

  /// Styles for a theme that does not already carry this extension.
  static BelongTextStyles forTheme(ThemeData theme, {bool contrast = false}) {
    final scheme = theme.colorScheme;
    final titleColor = contrast ? const Color(0xFFFFEB3B) : scheme.primary;
    final bodyColor = contrast ? Colors.white : scheme.onSurface;
    final captionColor = contrast
        ? Colors.white70
        : (theme.textTheme.bodySmall?.color ?? scheme.onSurface);
    return BelongTextStyles(
      title: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.bold,
        color: titleColor,
      ),
      body: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      ),
      caption: TextStyle(
        fontSize: 11.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: captionColor,
      ),
      emphasis: TextStyle(
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.bold,
        color: bodyColor,
      ),
    );
  }

  @override
  BelongTextStyles copyWith({
    TextStyle? title,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? emphasis,
  }) {
    return BelongTextStyles(
      title: title ?? this.title,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      emphasis: emphasis ?? this.emphasis,
    );
  }

  @override
  BelongTextStyles lerp(ThemeExtension<BelongTextStyles>? other, double t) {
    if (other is! BelongTextStyles) return this;
    return BelongTextStyles(
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      emphasis: TextStyle.lerp(emphasis, other.emphasis, t)!,
    );
  }
}
