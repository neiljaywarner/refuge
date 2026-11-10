import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_font_scale.dart';

import '../../helpers/text_scale.dart';

void main() {
  testWidgets('RefugeApp keeps a system text scale of 2.0 when the preset is standard', (
    tester,
  ) async {
    await pumpWithTextScale(
      tester,
      RefugeApp(
        repository: LocalPostRepository(),
        homeOverride: const Scaffold(body: Text('scale probe', key: Key('scale_probe'))),
      ),
      scale: 2,
      wrapMaterialApp: false,
    );

    final context = tester.element(find.byKey(const Key('scale_probe')));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(20, 0.01));
  });

  testWidgets('RefugeApp multiplies system text scale by the sensory preset', (tester) async {
    await pumpWithTextScale(
      tester,
      RefugeApp(
        repository: LocalPostRepository(),
        overrides: [
          sensoryFontScaleProvider.overrideWith(
            (ref) => SensoryFontScaleNotifier(SensoryFontScale.clarity),
          ),
        ],
        homeOverride: const Scaffold(body: Text('scale probe', key: Key('scale_probe'))),
      ),
      scale: 2,
      wrapMaterialApp: false,
    );

    final context = tester.element(find.byKey(const Key('scale_probe')));
    // Clarity is 1.5. System 2.0 stays in the product: 3.0, not clamped to 1.5.
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(30, 0.01));
  });
}
