import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// Read-only Patrol flow: bottom tabs by semantics id (no posts, auth, or DMs).
void main() {
  patrolTest(
    'FTL: bottom nav tabs switch read-only destinations',
    ($) async {
      await pumpDevReadOnlyHome($);

      await $(find.byKey(const Key('bottom_nav_tab_search'))).tap();
      await $.pumpAndSettle();
      expect($('Search'), findsWidgets);

      await $(find.byKey(const Key('bottom_nav_tab_notifications'))).tap();
      await $.pumpAndSettle();
      expect($('Notifications'), findsWidgets);

      await $(find.byKey(const Key('bottom_nav_tab_home'))).tap();
      await $.pumpAndSettle();
      expect($('Vote & Feedback'), findsOneWidget);
    },
  );
}
