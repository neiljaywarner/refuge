import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/system_text_scaler.dart';

void main() {
  test('a standard sensory preset keeps the system scaler', () {
    const system = TextScaler.linear(2);
    final combined = composeSystemAndSensoryScaler(system: system, sensoryFactor: 1);
    expect(combined, system);
    expect(combined.scale(10), 20);
  });

  test('a sensory preset multiplies the system scaler and is not clamped', () {
    final combined = composeSystemAndSensoryScaler(
      system: const TextScaler.linear(2),
      sensoryFactor: 1.5,
    );
    expect(combined.scale(10), 30);
    expect(combined.scale(16), 48);
  });

  test('multiplying no scaling yields the sensory preset', () {
    final combined = composeSystemAndSensoryScaler(
      system: TextScaler.noScaling,
      sensoryFactor: 1.3,
    );
    expect(combined.scale(10), closeTo(13, 0.01));
  });
}
