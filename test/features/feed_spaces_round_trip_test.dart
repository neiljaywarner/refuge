import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

/// Regression for #402: tester went Feed → Spaces → Feed and saw a grey
/// screen instead of the reflections feed.
void main() {
  patrolWidgetTest('BDD #402: Feed → Spaces → Feed re-renders reflections (no grey screen)', (
    $,
  ) async {
    $.tester.view.physicalSize = const Size(800, 1400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown($.tester.view.reset);
    await $.pumpWidgetAndSettle(RefugeApp(repository: LocalPostRepository()));

    expect(find.byType(ReflectionCard), findsWidgets);

    for (var round = 0; round < 3; round++) {
      await $(const Key('subnav_spaces_tab')).tap();
      await $.pumpAndSettle();
      expect($(const Key('belong_spaces_directory_list')), findsOneWidget);

      await $(const Key('subnav_feed_tab')).tap();
      await $.pumpAndSettle();

      expect($.tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Feed must not hang on a spinner after returning (#402)',
      );
      expect(find.byType(ReflectionCard), findsWidgets);
    }
  });

  patrolWidgetTest('BDD #402: Spaces → pick a space → Feed renders that space', ($) async {
    $.tester.view.physicalSize = const Size(800, 1400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown($.tester.view.reset);
    await $.pumpWidgetAndSettle(RefugeApp(repository: LocalPostRepository()));

    await $(const Key('subnav_spaces_tab')).tap();
    await $.pumpAndSettle();
    await $('General Chat').first.tap();
    await $.pumpAndSettle();

    expect($.tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
