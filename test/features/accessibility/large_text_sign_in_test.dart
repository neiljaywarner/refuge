import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets(
    'sign-in wall stays on screen at text scales 1.0, 1.3, 2.0, and 3.0',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        for (final scale in largeTextScales) {
          final session = await pumpSignInAtScale(tester, scale);
          expect(find.byKey(const Key('sign_in_title')), findsOneWidget);
          expect(find.byKey(const Key('sign_in_unavailable')), findsOneWidget);
          expect(
            find.byKey(const Key('sign_in_recovery_panel')),
            findsOneWidget,
          );

          final title = tester.element(find.byKey(const Key('sign_in_title')));
          expect(
            MediaQuery.textScalerOf(title).scale(10),
            closeTo(10 * scale, 0.01),
          );

          await tester.ensureVisible(
            find.byKey(const Key('sign_in_forgot_password')),
          );
          await tester.pump();
          session.check();
          expectMinTapTarget(
            tester,
            find.byKey(const Key('sign_in_forgot_password')),
          );
        }
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'sign-in recovery clears a bottom gesture inset at text scales 2 and 3',
    (tester) async {
      const bottomInset = 34.0;
      tester.view.viewPadding = const FakeViewPadding(bottom: bottomInset);
      tester.view.padding = const FakeViewPadding(bottom: bottomInset);
      addTearDown(() {
        tester.view.resetViewPadding();
        tester.view.resetPadding();
      });

      for (final scale in <double>[2, 3]) {
        final session = await pumpSignInAtScale(tester, scale);
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsOneWidget);
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        session.check();

        final panel = tester.getRect(
          find.byKey(const Key('sign_in_recovery_panel')),
        );
        expect(
          panel.bottom,
          lessThanOrEqualTo(largeTextPhoneSurface.height - bottomInset + 0.5),
          reason:
              'recovery panel sits under the gesture inset at text scale $scale (${panel.bottom})',
        );
      }
    },
  );
}
