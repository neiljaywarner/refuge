import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/feed_sort_row.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/space_navigation_bar.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

/// Computes the relative luminance of a color per WCAG 2.1 specs.
double _relativeLuminance(Color color) {
  double transform(double channel) =>
      channel <= 0.03928 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Computes the WCAG contrast ratio between two colors (range: 1.0 to 21.0).
double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Monastic Dark (Charcoal) Contrast & Theme Tokens (#617)', () {
    late ThemeData charcoalTheme;

    setUp(() {
      charcoalTheme = SensoryThemeData.getTheme(SensoryMode.charcoal);
    });

    test('Monastic Dark theme has dark brightness and Material 3 enabled', () {
      expect(charcoalTheme.brightness, Brightness.dark);
      expect(charcoalTheme.useMaterial3, isTrue);
    });

    test('Primary color meets WCAG AAA (>= 7:1) contrast against scaffold background', () {
      final ratio = _contrastRatio(
        charcoalTheme.colorScheme.primary,
        charcoalTheme.scaffoldBackgroundColor,
      );
      // Expected >= 7.0:1 for high calm readability
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('onSurface text meets WCAG AAA (>= 7:1) contrast against surface', () {
      final ratio = _contrastRatio(
        charcoalTheme.colorScheme.onSurface,
        charcoalTheme.colorScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('ChipTheme unselected label meets WCAG AAA (>= 7:1) contrast against chip background', () {
      final chipTheme = charcoalTheme.chipTheme;
      expect(chipTheme.backgroundColor, isNotNull);
      expect(chipTheme.labelStyle?.color, isNotNull);

      final ratio = _contrastRatio(chipTheme.labelStyle!.color!, chipTheme.backgroundColor!);
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test(
      'ChipTheme selected label meets WCAG AA (>= 4.5:1) contrast against selected chip background',
      () {
        final chipTheme = charcoalTheme.chipTheme;
        expect(chipTheme.selectedColor, isNotNull);
        expect(chipTheme.secondaryLabelStyle?.color, isNotNull);

        final ratio = _contrastRatio(
          chipTheme.secondaryLabelStyle!.color!,
          chipTheme.selectedColor!,
        );
        expect(ratio, greaterThanOrEqualTo(4.5));
      },
    );

    test('Feed chrome border meets WCAG 1.4.11 (>= 3:1) against scaffold and fill (#484)', () {
      final scaffold = charcoalTheme.scaffoldBackgroundColor;
      expect(_contrastRatio(MonasticChrome.controlBorder, scaffold), greaterThanOrEqualTo(3));
      expect(
        _contrastRatio(MonasticChrome.controlBorder, MonasticChrome.controlFill),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrastRatio(MonasticChrome.label, MonasticChrome.controlFill),
        greaterThanOrEqualTo(7),
      );
    });

    test('Notification badge text meets WCAG AAA against Monastic primary (#484)', () {
      final ratio = _contrastRatio(
        charcoalTheme.colorScheme.onPrimary,
        charcoalTheme.colorScheme.primary,
      );
      expect(ratio, greaterThanOrEqualTo(7));
      expect(_contrastRatio(Colors.white, charcoalTheme.colorScheme.primary), lessThan(4.5));
    });

    test('ChipTheme defines distinct side border for Monastic Dark', () {
      final chipTheme = charcoalTheme.chipTheme;
      expect(chipTheme.side, isNotNull);
      expect(chipTheme.side?.color, isNotNull);
    });
  });

  group('Monastic Dark Chrome Widget Tests (#617)', () {
    testWidgets('BelongBottomNavBar renders readable active and inactive tabs in charcoal mode', (
      tester,
    ) async {
      final theme = SensoryThemeData.getTheme(SensoryMode.charcoal);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              bottomNavigationBar: BelongBottomNavBar(
                currentTab: BelongBottomTab.home,
                onSelectTab: (_) {},
                isContrast: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('belong_bottom_nav_bar')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_tab_home')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_tab_notifications')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_tab_msgs')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_tab_search')), findsOneWidget);
    });

    testWidgets('FeedSortRow renders popup and sort chips in Monastic Dark theme', (tester) async {
      final theme = SensoryThemeData.getTheme(SensoryMode.charcoal);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FeedSortRow(
              activeSort: FeedSortOption.latest,
              onSelectSort: (_) {},
              isContrast: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed_sort_popup_button')), findsOneWidget);
      expect(find.byKey(const Key('feed_sort_chip_latest')), findsOneWidget);
      expect(find.text('Sort: '), findsOneWidget);
    });

    testWidgets('phone-width filter and sort labels stay fully visible in Monastic Dark (#484)', (
      tester,
    ) async {
      await _pumpChrome(
        tester,
        width: 390,
        filter: '[Prayer Request]',
        sort: FeedSortOption.newActivity,
      );

      expect(_labelOverflows(tester, 'tone_filter_active_label'), isFalse);
      expect(_labelOverflows(tester, 'feed_sort_active_label'), isFalse);
      expect(_labelOverflows(tester, 'space_room_title'), isFalse);
      expect(find.text('Prayer Request'), findsOneWidget);
      expect(find.textContaining('New Activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px monastic chrome does not overflow and keeps the room title (#484)', (
      tester,
    ) async {
      await _pumpChrome(
        tester,
        width: 320,
        filter: '[Bible Deep-Dive]',
        sort: FeedSortOption.alphabetical,
      );

      expect(tester.takeException(), isNull);
      expect(_labelOverflows(tester, 'space_room_title'), isFalse);
      expect(_labelOverflows(tester, 'tone_filter_active_label'), isFalse);
      expect(_labelOverflows(tester, 'feed_sort_active_label'), isFalse);
    });

    testWidgets('dark notification badge uses onPrimary, sage badge stays white (#484)', (
      tester,
    ) async {
      Future<Badge> pumpBadge(ThemeData theme) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              unreadNotificationsCountProvider.overrideWith((ref) => 2),
              memberProfileProvider.overrideWith(_SignedInProfile.new),
            ],
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                bottomNavigationBar: BelongBottomNavBar(
                  currentTab: BelongBottomTab.home,
                  onSelectTab: (_) {},
                  isContrast: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widget<Badge>(find.byKey(const Key('bottom_nav_notifications_badge')));
      }

      final darkBadge = await pumpBadge(SensoryThemeData.getTheme(SensoryMode.charcoal));
      expect(darkBadge.textColor, const Color(0xFF0F1A12));

      final sageBadge = await pumpBadge(SensoryThemeData.getTheme(SensoryMode.sage));
      expect(sageBadge.textColor, Colors.white);
    });

    testWidgets('inactive monastic nav labels use the calm slate token (#484)', (tester) async {
      final theme = SensoryThemeData.getTheme(SensoryMode.charcoal);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              bottomNavigationBar: BelongBottomNavBar(
                currentTab: BelongBottomTab.home,
                onSelectTab: (_) {},
                isContrast: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final messages = tester.widget<Text>(find.byKey(const Key('bottom_nav_label_msgs')));
      expect(messages.style?.color, MonasticChrome.label);
      expect(messages.style?.fontSize, 12);
      final home = tester.widget<Text>(find.byKey(const Key('bottom_nav_label_home')));
      expect(home.style?.color, theme.colorScheme.primary);
    });
  });
}

class _SignedInProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile(
    displayName: 'Fellow Member',
    email: 'member@belongonthespectrum.com',
    bio: 'Quiet rest',
    comfortBadges: ['Literal communication appreciated'],
    isSignedIn: true,
  );
}

Future<void> _pumpChrome(
  WidgetTester tester, {
  required double width,
  required String filter,
  required FeedSortOption sort,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: SensoryThemeData.getTheme(SensoryMode.charcoal),
        home: Scaffold(
          body: SpaceNavigationBar(
            selectedSpace: 'prayer',
            onSelectSpace: (_) {},
            onBackToSpaces: () {},
            activeFilter: filter,
            onSelectFilter: (_) {},
            activeSort: sort,
            onSelectSort: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _labelOverflows(WidgetTester tester, String key) {
  final paragraph = tester.renderObject<RenderParagraph>(find.byKey(Key(key)));
  return paragraph.didExceedMaxLines;
}
