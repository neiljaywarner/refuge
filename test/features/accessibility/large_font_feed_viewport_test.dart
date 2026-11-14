import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/large_font_home_layout.dart';

import '../../helpers/text_scale.dart';

/// Pixel 9a logical size. The owner's screenshot was taken on that phone.
const Size pixel9aSurface = Size(412, 915);

/// Scales the feed-ownership tests actually assert. 1.0 must keep today's
/// chrome. 1.5 and 2.0 are the large-text layout (Android's maximum is 200%).
const List<double> feedViewportScales = <double>[1.0, 1.5, 2.0];

void main() {
  testWidgets('feed viewport owns a Pixel 9a at large text and stays familiar at 1.0', (
    tester,
  ) async {
    for (final scale in feedViewportScales) {
      final session = await _pumpHome(tester, scale);
      final fraction = _feedViewportFraction(tester);

      if (scale > kLargeFontHomeLayoutThreshold) {
        expect(
          fraction,
          greaterThanOrEqualTo(0.7),
          reason: 'text scale $scale feed viewport was ${fraction.toStringAsFixed(2)} of the phone',
        );
        expect(find.byKey(const Key('organizer_message_banner')), findsNothing);
        expect(find.byKey(const Key('reflection_composer_input')), findsNothing);
        expect(find.byKey(const Key('large_font_share_thought_button')), findsOneWidget);
        expectMinTapTarget(
          tester,
          find.byKey(const Key('large_font_share_thought_button')),
          surface: pixel9aSurface,
        );
        expectMinTapTarget(
          tester,
          find.byKey(const Key('large_font_open_drawer_button')),
          surface: pixel9aSurface,
        );
      } else {
        expect(find.byKey(const Key('organizer_message_banner')), findsOneWidget);
        expect(find.byKey(const Key('reflection_composer_input')), findsOneWidget);
        expect(find.byKey(const Key('subnav_feed_tab')), findsOneWidget);
        expect(find.byKey(const Key('space_room_header')), findsOneWidget);
        expect(find.byKey(const Key('large_font_open_drawer_button')), findsNothing);
        expect(find.textContaining('Gathered in peace'), findsOneWidget);
      }

      if (scale == 2.0) {
        final card = tester.getRect(find.byKey(const Key('reflection_card_1')));
        final content = tester.getRect(find.textContaining('Please pray for peace of mind'));
        expect(
          card.top,
          lessThanOrEqualTo(pixel9aSurface.height * 0.30),
          reason: 'first card started at ${card.top.toStringAsFixed(1)}',
        );
        expect(
          content.top,
          lessThanOrEqualTo(pixel9aSurface.height * 0.30),
          reason: 'first post content started at ${content.top.toStringAsFixed(1)}',
        );
      }
      session.check();
    }
  });

  testWidgets('large text keeps feed controls reachable from the home menu', (tester) async {
    for (final scale in <double>[1.5, 2.0]) {
      final session = await _pumpHome(tester, scale);
      await tester.tap(find.byKey(const Key('large_font_open_drawer_button')));
      await settleLargeText(tester);

      expect(find.text('Vote & Feedback'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      final drawerScroll = find.descendant(
        of: find.byKey(const Key('large_font_home_drawer')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.textContaining('Welcome to Belong'),
        240,
        scrollable: drawerScroll.first,
      );
      expect(find.textContaining('Welcome to Belong'), findsOneWidget);
      expect(find.textContaining('peaceful sanctuary'), findsWidgets);
      expect(find.textContaining('Gathered in peace'), findsOneWidget);
      expect(find.byKey(const Key('space_room_header')), findsOneWidget);

      for (final key in <Key>[
        const Key('subnav_feed_tab'),
        const Key('subnav_spaces_tab'),
        const Key('open_feedback_and_voting_button'),
        const Key('large_font_drawer_about_button'),
        const Key('space_switcher_popup_button'),
        const Key('tone_filter_popup_button'),
        const Key('feed_sort_popup_button'),
      ]) {
        await tester.ensureVisible(find.byKey(key));
        await tester.pump();
        expectMinTapTarget(tester, find.byKey(key), surface: pixel9aSurface);
      }
      session.check();

      tester.state<ScrollableState>(drawerScroll.first).position.jumpTo(0);
      await tester.pump();
      await tester.tap(find.byKey(const Key('subnav_spaces_tab')));
      await settleLargeText(tester);
      expect(find.byKey(const Key('belong_spaces_directory_list')), findsOneWidget);
      session.check();
    }
  });

  testWidgets('drawer Spaces from Messages opens the home directory', (tester) async {
    final session = await _pumpHome(tester, 2);
    await tester.tap(find.byKey(const Key('bottom_nav_tab_msgs')));
    await settleLargeText(tester);
    await tester.tap(find.byKey(const Key('large_font_open_drawer_button')));
    await settleLargeText(tester);
    await tester.tap(find.byKey(const Key('subnav_spaces_tab')));
    await settleLargeText(tester);
    expect(find.byKey(const Key('belong_spaces_directory_list')), findsOneWidget);
    expect(find.text('Direct Messages'), findsNothing);
    session.check();
  });

  testWidgets('the large-text composer owns the phone', (tester) async {
    for (final scale in <double>[1.5, 2.0]) {
      final session = await _pumpHome(tester, scale);
      await tester.tap(find.byKey(const Key('large_font_share_thought_button')));
      await settleLargeText(tester);

      final surface = tester.getSize(find.byKey(const Key('large_font_composer_surface')));
      final fraction = surface.height / pixel9aSurface.height;
      expect(
        fraction,
        greaterThanOrEqualTo(0.7),
        reason: 'text scale $scale composer was ${fraction.toStringAsFixed(2)} of the phone',
      );
      expect(find.byKey(const Key('reflection_composer_input')), findsOneWidget);
      expectMinTapTarget(tester, find.byTooltip('Close composer'), surface: pixel9aSurface);
      session.check();
    }
  });
}

Future<TextScaleSession> _pumpHome(WidgetTester tester, double scale) {
  final repository = LocalPostRepository();
  return pumpWithTextScale(
    tester,
    RefugeHomeScreen(repository: repository),
    scale: scale,
    surface: pixel9aSurface,
    shell: (child) => ProviderScope(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
      child: child,
    ),
  );
}

double _feedViewportFraction(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byKey(const Key('home_feed_scroll')),
    matching: find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  expect(scrollable, findsOneWidget);
  return tester.getSize(scrollable).height / pixel9aSurface.height;
}
