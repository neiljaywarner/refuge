import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('sensory settings dialog stays usable at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      final session = await pumpSensorySettingsAtScale(tester, scale);
      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(find.text('Standard (100%)'), findsOneWidget);
      expect(find.text('Max Clarity (150%)'), findsOneWidget);
      await tester.ensureVisible(find.text('Max Clarity (150%)'));
      await tester.pump();
      session.check();
    }
  });

  testWidgets('notification settings sheet stays usable at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      await pumpNotificationSettingsAtScale(tester, scale);
      expect(find.text('Calm Notification Ethics'), findsOneWidget);
    }
  });
}
