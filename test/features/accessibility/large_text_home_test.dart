import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/community_anchor_banner.dart';

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
        final signIn = find.byKey(const Key('home_top_bar_sign_in_button'));
        if (scale >= 2) {
          expect(find.descendant(of: signIn, matching: find.text('Sign In')), findsNothing);
          expect(find.byTooltip('Sign In'), findsOneWidget);
          expect(find.bySemanticsLabel('Sign In'), findsWidgets);
        } else {
          expect(find.descendant(of: signIn, matching: find.text('Sign In')), findsOneWidget);
        }
        if (scale == 1) {
          final banner = tester.getSize(find.byKey(const Key('organizer_message_banner')));
          final message = tester.getSize(find.textContaining('peaceful sanctuary'));
          expect(message.width, greaterThan(banner.width * 0.55));
        }
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets('inline domain does not take half the banner title', (tester) async {
    final session = await pumpWithTextScale(
      tester,
      const CommunityAnchorBanner(primaryColor: Color(0xFF2E6B56), isContrast: false),
      scale: 1,
      surface: const Size(560, 800),
      shell: (child) => ProviderScope(child: child),
    );

    final domain = tester.getSize(find.textContaining('belongonthespectrum.web.app'));
    final titleSize = tester.getSize(find.text('Welcome to Belong on the Spectrum'));
    // Two Flexible children would split this row. The title then keeps more
    // width than the capped domain.
    expect(titleSize.width, greaterThan(domain.width + 40));
    session.check();
  });
}
