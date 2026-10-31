import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taps Skip when the post-sign-in first-visit card is shown (#663).
Future<void> dismissFirstVisitWelcomeIfShown(WidgetTester tester) async {
  final skip = find.byKey(const Key('first_visit_skip_button'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }
}
