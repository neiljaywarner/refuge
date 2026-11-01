import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  patrolWidgetTest('Patrol Hello World Widget Test: read-only home shell and bottom nav', (
    $,
  ) async {
    await $.pumpWidgetAndSettle(RefugeApp(repository: LocalPostRepository()));

    expect($('Belong'), findsOneWidget);
    expect($('Refuge'), findsOneWidget);

    expect($('Home'), findsOneWidget);
    expect($('Notifications'), findsOneWidget);
    expect($('Messages'), findsOneWidget);
    expect($('Search'), findsOneWidget);

    // Home content is at most 820 wide, so phone chrome (#484) drops the
    // "Filter:" prefix and shows the active filter name instead.
    expect($(const Key('tone_filter_popup_button')), findsOneWidget);
    expect($(const Key('tone_filter_active_label')), findsOneWidget);
    expect($('All'), findsWidgets);
    expect($(const Key('feed_sort_popup_button')), findsOneWidget);
    expect($(ChoiceChip), findsWidgets);

    expect($('Vote & Feedback'), findsOneWidget);
  });
}
