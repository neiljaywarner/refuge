import 'package:flutter/painting.dart';

/// Multiplies the platform text scaler by Belong's in-app sensory preset.
///
/// [system] is the operating-system Font size (Android `font_scale`, iOS
/// Dynamic Type). [sensoryFactor] is the extra preset from Sensory Settings.
/// A factor of 1 returns [system] unchanged. The product is not clamped:
/// a widget that cannot grow may clamp itself and should say why.
TextScaler composeSystemAndSensoryScaler({
  required TextScaler system,
  required double sensoryFactor,
}) {
  if (sensoryFactor == 1) return system;
  if (identical(system, TextScaler.noScaling) || system == TextScaler.noScaling) {
    return TextScaler.linear(sensoryFactor);
  }
  return _ProductTextScaler(system, sensoryFactor);
}

final class _ProductTextScaler extends TextScaler {
  const _ProductTextScaler(this.inner, this.factor) : assert(factor >= 0);

  final TextScaler inner;
  final double factor;

  @override
  double scale(double fontSize) => inner.scale(fontSize) * factor;

  @override
  // The interface still requires this estimate. Linear system scalers
  // (Android font_scale) make it exact.
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor * factor;

  @override
  TextScaler clamp({double minScaleFactor = 0, double maxScaleFactor = double.infinity}) {
    if (factor == 0) return const TextScaler.linear(0);
    return _ProductTextScaler(
      inner.clamp(minScaleFactor: minScaleFactor / factor, maxScaleFactor: maxScaleFactor / factor),
      factor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _ProductTextScaler && other.inner == inner && other.factor == factor;

  @override
  int get hashCode => Object.hash(inner, factor);

  @override
  String toString() => '$inner x $factor sensory';
}
