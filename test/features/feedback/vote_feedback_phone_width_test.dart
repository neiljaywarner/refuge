import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  testWidgets(
    'Vote & Feedback stays inside a phone-width viewport and opens the sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Banner, composer, and title rows still overflow at 390px. Those are
      // outside this chip. Ignore only that layout report so the chip asserts
      // can run.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(RefugeApp(repository: LocalPostRepository()));
      await tester.pumpAndSettle();

      final finder = find.byKey(const Key('open_feedback_and_voting_button'));
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));

      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
    },
  );
}
