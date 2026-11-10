import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('sign-in wall stays on screen at text scales 1.0, 1.3, 2.0, and 3.0', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      for (final scale in largeTextScales) {
        final session = await pumpSignInAtScale(tester, scale);
        expect(find.byKey(const Key('sign_in_title')), findsOneWidget);
        expect(find.byKey(const Key('sign_in_unavailable')), findsOneWidget);
        expect(find.byKey(const Key('sign_in_recovery_panel')), findsOneWidget);

        final title = tester.element(find.byKey(const Key('sign_in_title')));
        expect(MediaQuery.textScalerOf(title).scale(10), closeTo(10 * scale, 0.01));

        await tester.ensureVisible(find.byKey(const Key('sign_in_forgot_password')));
        await tester.pump();
        session.check();
        expectMinTapTarget(tester, find.byKey(const Key('sign_in_forgot_password')));
      }
    } finally {
      handle.dispose();
    }
  });
}
