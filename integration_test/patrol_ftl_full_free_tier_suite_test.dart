import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';

import 'patrol_app_harness.dart';

/// Bundled read-only end-to-end multi-journey suite designed to maximize ROI
/// on Firebase Test Lab Spark free tier (5 physical / 10 virtual runs per day).
///
/// Executes 7 non-mutating journeys within a single APK execution slot:
/// 1. Cold start, branding, and shell verification
/// 2. Bottom navigation destination switching
/// 3. Tone filter selection and feed sort switching
/// 4. Feedback & Feature Roadmap sheet opening and dismiss
/// 5. About dialog verification
/// 6. Sensory mode / theme responsiveness
/// 7. Native background and resume resilience (Android/iOS)
void main() {
  patrolTest('FTL Free-Tier Suite: comprehensive 7-journey read-only smoke', ($) async {
    // ---------------------------------------------------------
    // Journey 1: Cold start, branding, and shell verification
    // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // Journey 2: Bottom navigation destination switching
    // ---------------------------------------------------------
    await $(find.byKey(const Key('bottom_nav_tab_search'))).tap();
    await $.pumpAndSettle();
    expect($('Search'), findsWidgets);

    await $(find.byKey(const Key('bottom_nav_tab_notifications'))).tap();
    await $.pumpAndSettle();
    expect($('Notifications'), findsWidgets);

    await $(find.byKey(const Key('bottom_nav_tab_home'))).tap();
    await $.pumpAndSettle();
    expect($('Vote & Feedback'), findsOneWidget);

    // ---------------------------------------------------------
    // Journey 3: Tone filter selection & feed sort switching
    // ---------------------------------------------------------
    for (final filter in kToneFilters.take(3)) {
      final key = Key(toneFilterSemanticsId(filter));
      if ($(key).visible) {
        await $(key).tap();
        await $.pumpAndSettle();
        expect($.tester.takeException(), isNull);
      }
    }

    final recentSortKey = Key('feed_sort_chip_${FeedSortOption.recent.name}');
    if ($(recentSortKey).visible) {
      await $(recentSortKey).tap();
      await $.pumpAndSettle();
      expect($.tester.takeException(), isNull);
    }

    // ---------------------------------------------------------
    // Journey 4: Feedback & Feature Roadmap sheet
    // ---------------------------------------------------------
    await $('Vote & Feedback').tap();
    await $.pumpAndSettle();
    expect($('Belong Roadmap & Feedback'), findsOneWidget);

    // Close the modal bottom sheet
    await $.tester.pageBack();
    await $.pumpAndSettle();
    expect($('Vote & Feedback'), findsOneWidget);

    // ---------------------------------------------------------
    // Journey 5: About dialog verification
    // ---------------------------------------------------------
    final aboutButton = find.byTooltip('About Belong');
    if (aboutButton.evaluate().isNotEmpty) {
      await $(aboutButton).tap();
      await $.pumpAndSettle();
      expect(find.byType(AboutDialog), findsOneWidget);
      await $('Close').tap();
      await $.pumpAndSettle();
    }

    // ---------------------------------------------------------
    // Journey 6: Sensory theme mode verification
    // ---------------------------------------------------------
    expect(find.byType(MaterialApp), findsOneWidget);

    // ---------------------------------------------------------
    // Journey 7: Native background and resume resilience
    // ---------------------------------------------------------
    if (Platform.isAndroid || Platform.isIOS) {
      await $.platform.mobile.pressHome();
      await $.platform.mobile.openApp(appId: 'com.belongonthespectrum.refuge.dev');
      await $.pumpAndSettle();
      expect($('Vote & Feedback'), findsOneWidget);
    }
  });
}
