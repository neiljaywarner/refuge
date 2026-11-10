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
      expectMinTapTarget(tester, find.byKey(const Key('close_feedback_sheet_button')));
    }
  });
}
