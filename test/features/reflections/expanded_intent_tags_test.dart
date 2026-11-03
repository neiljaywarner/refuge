import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/tone_filter_row.dart';

void main() {
  group('Expanded Intent Tags (#848 Bruce Usability Feedback)', () {
    test('kToneOptions includes Chat, General, and Other', () {
      expect(kToneOptions, contains('[General Chat]'));
      expect(kToneOptions, contains('[Fellowship]'));
      expect(kToneOptions, contains('[Other]'));
    });

    test('kToneFilters includes Chat, General, and Other filter chips', () {
      expect(kToneFilters, contains('[General Chat]'));
      expect(kToneFilters, contains('[Fellowship]'));
      expect(kToneFilters, contains('[Other]'));
    });

    testWidgets('ToneFilterRow displays expanded filter chips', (tester) async {
      String? selectedFilter;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(2000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ToneFilterRow(activeFilter: 'All', onSelectFilter: (f) => selectedFilter = f),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tone_filter_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('tone_filter_chip_general_chat')), findsOneWidget);

      final otherFinder = find.byKey(const Key('tone_filter_chip_other'));
      expect(otherFinder, findsOneWidget);

      await tester.ensureVisible(otherFinder);
      await tester.pumpAndSettle();
      await tester.tap(otherFinder);
      await tester.pumpAndSettle();
      expect(selectedFilter, equals('[Other]'));
    });

    testWidgets('ReflectionComposer renders expanded intent options without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReflectionComposer(
              selectedSpace: 'prayer',
              primaryColor: Colors.blue,
              isContrast: false,
              onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async {
                return PostPublishStatus.confirmed;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('composer_expand_button')));
      await tester.pumpAndSettle();

      expect(find.text('[Prayer Request]'), findsOneWidget);
    });
  });
}
