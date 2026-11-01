import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// Legacy entry name kept for docs; prefer [patrol_ftl_home_shell_test.dart].
void main() {
  patrolTest('Firebase Test Lab Hello World: read-only home shell and bottom nav', ($) async {
    await pumpDevReadOnlyHome($);

    expect($('Belong'), findsOneWidget);
    expect($('Refuge'), findsOneWidget);
    expect($('Home'), findsOneWidget);
    expect($('Notifications'), findsOneWidget);
    expect($('Messages'), findsOneWidget);
    expect($('Search'), findsOneWidget);
    // Home content stays under 960 wide, so the filter pill shows the
    // active name ("All") instead of a "Filter:" prefix (#484).
    expect($(const Key('tone_filter_popup_button')), findsOneWidget);
    expect($(const Key('tone_filter_active_label')), findsOneWidget);
    expect($('All'), findsWidgets);
    expect($(const Key('feed_sort_popup_button')), findsOneWidget);
    expect($(ChoiceChip), findsWidgets);
    expect($('Vote & Feedback'), findsOneWidget);
  });
}
