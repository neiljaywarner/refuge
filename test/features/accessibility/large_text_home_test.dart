import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('home feed and bottom nav stay usable at large text scales', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      for (final scale in largeTextScales) {
        final session = await pumpHomeAtScale(tester, scale);
        expect(find.text('Belong'), findsWidgets);
        expect(find.text('Refuge'), findsWidgets);
        expect(find.byKey(const Key('bottom_nav_tab_home')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Home tab')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('open_feedback_and_voting_button')));
        await tester.pump();
        session.check();
        expectMinTapTarget(tester, find.byKey(const Key('bottom_nav_tab_home')));
        expectMinTapTarget(tester, find.byKey(const Key('home_top_bar_sign_in_button')));
      }
    } finally {
      handle.dispose();
    }
  });
}
