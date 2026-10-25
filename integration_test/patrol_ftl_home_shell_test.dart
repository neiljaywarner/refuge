import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// Read-only Firebase Test Lab / Patrol smoke: home chrome and bottom nav.
void main() {
  patrolTest(
    'FTL: dev home shell shows branding, filters, and bottom nav',
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
