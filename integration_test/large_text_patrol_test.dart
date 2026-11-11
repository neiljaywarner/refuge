import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/main.dart';

import 'patrol_app_harness.dart';

/// Walks home, messages, and feedback at the device's current text scale.
///
/// `tool/run_large_text_device_checks.sh` sets Android font scale and display
/// density from the host, runs this test, then restores both. The app process
/// cannot change those settings, so this test only walks the screens and reads
/// [MediaQuery.textScalerOf]. Group-call join is not on this branch (PR #905).
void main() {
  patrolTest('large system text: home, messages, and feedback stay usable', ($) async {
    await pumpDevReadOnlyHome($);

    final home = find.byType(RefugeHomeScreen);
    expect(home, findsOneWidget);
    final scale = MediaQuery.textScalerOf($.tester.element(home)).scale(1);
    expect(scale, greaterThan(0));

    expect($('Vote & Feedback'), findsOneWidget);
    expect($('Home'), findsOneWidget);
    expect($('Belong'), findsWidgets);

    await $('Messages').tap();
    expect($('Direct Messages'), findsOneWidget);
    await $('Home').tap();
    await $('Vote & Feedback').tap();
    expect($('Belong Roadmap & Feedback'), findsOneWidget);
  });
}
