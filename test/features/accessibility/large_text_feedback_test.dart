import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('feedback sheet stays usable at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      await pumpFeedbackAtScale(tester, scale);
      expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
      expect(find.text('Vote on Features'), findsOneWidget);
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      final isLargeText = scale > 1.15;
      expect(tabs.isScrollable, isLargeText);
      expect(tabs.tabAlignment, isLargeText ? TabAlignment.start : TabAlignment.fill);
      expect(
        find.ancestor(
          of: find.text('Belong Roadmap & Feedback'),
          matching: find.byType(SingleChildScrollView),
        ),
        isLargeText ? findsOneWidget : findsNothing,
      );
      expectMinTapTarget(tester, find.byKey(const Key('close_feedback_sheet_button')));
    }
  });
}
