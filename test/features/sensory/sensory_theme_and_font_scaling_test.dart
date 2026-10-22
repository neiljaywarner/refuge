import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_refuge_dialog.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_font_scale.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/presentation/sensory_theme_controller.dart';
import 'package:refuge4serverpod/src/home_screen.dart';

void main() {
  group('SensoryFontScale & Controller Unit Tests', () {
    test('SensoryFontScale defines 4 calm-tech presets with correct scale factors', () {
      expect(SensoryFontScale.standard.scaleFactor, 1.0);
      expect(SensoryFontScale.comfort.scaleFactor, 1.15);
      expect(SensoryFontScale.spacious.scaleFactor, 1.30);
      expect(SensoryFontScale.clarity.scaleFactor, 1.50);

      expect(SensoryFontScale.values.length, 4);
    });

    test('SensoryThemeNotifier toggleHighContrast flips between contrast and sage', () {
      final notifier = SensoryThemeNotifier(SensoryMode.sage);
      expect(notifier.state, SensoryMode.sage);

      notifier.toggleHighContrast();
      expect(notifier.state, SensoryMode.contrast);

      notifier.toggleHighContrast();
      expect(notifier.state, SensoryMode.sage);
    });

    test('ThemeNotifier supports fontScale and toggleHighContrast', () {
      final notifier = ThemeNotifier();
      expect(notifier.mode, SensoryMode.sage);
      expect(notifier.fontScale, SensoryFontScale.standard);

      notifier.toggleHighContrast();
      expect(notifier.mode, SensoryMode.contrast);

      notifier.setFontScale(SensoryFontScale.spacious);
      expect(notifier.fontScale, SensoryFontScale.spacious);
    });
  });

  group('High-Contrast Toggle & Font Scaling Widget Tests', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    testWidgets('Tapping 1-tap High-Contrast toggle in AppBar flips theme', (tester) async {
      final themeNotifier = ThemeNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            postRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: RefugeHomeScreen(
              repository: repository,
              themeNotifier: themeNotifier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('home_high_contrast_toggle_button'));
      expect(toggleFinder, findsOneWidget);

      expect(themeNotifier.mode, SensoryMode.sage);

      // Tap toggle -> High Contrast
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();
      expect(themeNotifier.mode, SensoryMode.contrast);

      // Tap toggle again -> Reverts to Sage
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();
      expect(themeNotifier.mode, SensoryMode.sage);
    });

    testWidgets('About dialog displays High Contrast switch and 4 font scaling chips', (tester) async {
      SensoryFontScale? selectedScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAboutRefugeDialog(
                  context,
                  primaryColor: Colors.teal,
                  isContrast: false,
                  currentMode: SensoryMode.sage,
                  onSelectMode: (_) {},
                  currentFontScale: SensoryFontScale.standard,
                  onSelectFontScale: (scale) => selectedScale = scale,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify High Contrast Mode SwitchListTile
      expect(find.text('High Contrast Mode (WCAG AAA)'), findsOneWidget);

      // Verify 4 Font Scaling chips exist
      expect(find.text('Standard (100%)'), findsOneWidget);
      expect(find.text('Comfort (115%)'), findsOneWidget);
      expect(find.text('Spacious (130%)'), findsOneWidget);
      expect(find.text('Max Clarity (150%)'), findsOneWidget);

      // Ensure chip is visible in scrollable dialog and tap it
      final chipFinder = find.text('Spacious (130%)');
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(selectedScale, SensoryFontScale.spacious);
    });
  });
}
