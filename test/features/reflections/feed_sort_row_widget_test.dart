import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/feed_sort_row.dart';

void main() {
  testWidgets('a chip and the menu both report the chosen sort on the next frame', (tester) async {
    FeedSortOption selected = FeedSortOption.latest;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FeedSortRow(
              activeSort: selected,
              isContrast: false,
              onSelectSort: (option) => setState(() => selected = option),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('feed_sort_chip_popular')));
    await tester.pump();
    expect(selected, FeedSortOption.popular);

    await tester.tap(find.byKey(const Key('feed_sort_popup_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed_sort_menu_item_oldest')), findsOneWidget);
    await tester.tap(find.byKey(const Key('feed_sort_menu_item_oldest')));
    await tester.pump();
    expect(selected, FeedSortOption.oldest);
  });

  testWidgets('contrast mode at text scale 2 keeps the sort row on screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedSortRow(
            activeSort: FeedSortOption.forYou,
            isContrast: true,
            onSelectSort: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    expect(find.textContaining('For you'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sort scheduled after the row is gone does not run', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    selectFeedSortAfterFrame(captured, () => fail('the row was already gone'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
