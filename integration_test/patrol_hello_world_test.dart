import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// Legacy entry name kept for docs; prefer [patrol_ftl_home_shell_test.dart].
void main() {
  patrolTest(
    'Firebase Test Lab Hello World: read-only home shell and bottom nav',
    ($) async {
      await pumpDevReadOnlyHome($);

      expect($('Belong'), findsOneWidget);
      expect($('Refuge'), findsOneWidget);
      expect($('Home'), findsOneWidget);
      expect($('Notifications'), findsOneWidget);
      expect($('Messages'), findsOneWidget);
      expect($('Search'), findsOneWidget);
      expect($('Filter: '), findsOneWidget);
      expect($(ChoiceChip), findsWidgets);
      expect($('Vote & Feedback'), findsOneWidget);
    },
  );
}
