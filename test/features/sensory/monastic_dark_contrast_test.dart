import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/feed_sort_row.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

/// Computes the relative luminance of a color per WCAG 2.1 specs.
double _relativeLuminance(Color color) {
  double transform(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

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
  });
}
