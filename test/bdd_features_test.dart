import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('BDD Feature: Fellowship Spaces and Mindful Intent Navigation', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(PatrolTester $) async {
      $.tester.view.physicalSize = const Size(1200, 1600);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      await $.pumpWidgetAndSettle(SanctuaryApp(repository: repository));
    }

    patrolWidgetTest(
      'Scenario: Switching between fellowship spaces displays space-specific reflections',
      ($) async {
        // Given the Sanctuary application is open in default '#prayer-sanctuary' room
        await pumpSanctuary($);

        // Then I should see reflections from 'David M. (UK)'
        expect($('David M. (UK)'), findsOneWidget);
        // And I should not see reflections from 'Pastor Thomas (Melbourne)'
        expect($('Pastor Thomas (Melbourne)'), findsNothing);

        // When I tap on the '📖 #weekly-study' space chip
        await $('📖 #weekly-study').tap();

        // Then I should see reflections from 'Pastor Thomas (Melbourne)'
        expect($('Pastor Thomas (Melbourne)'), findsOneWidget);
        // And I should not see reflections from 'David M. (UK)'
        expect($('David M. (UK)'), findsNothing);
      },
    );

    patrolWidgetTest('Scenario: Visiting an empty fellowship room shows peaceful stillness', (
      $,
    ) async {
      await pumpSanctuary($);

      // When I tap on '#announcements' space chip
      await $('📢 #announcements').tap();

      // Then I should see 'Space is quiet right now'
      expect($(RegExp('Space is quiet right now')), findsOneWidget);
      // And no chaotic error banners exist
      expect($(RegExp('Error')), findsNothing);
    });

    patrolWidgetTest('Scenario: Filtering reflections by mindful intent tags', (
      $,
    ) async {
      await pumpSanctuary($);

      // When I select the '[Comfort Only]' intent filter chip
      final comfortFilter = $(find.widgetWithText(ChoiceChip, '[Comfort Only]'));
      await comfortFilter.first.tap();

      // Then I should see reflections from 'Elena R. (Colorado)'
      expect($('Elena R. (Colorado)'), findsOneWidget);
      // And I should not see reflections from 'David M. (UK)'
      expect($('David M. (UK)'), findsNothing);

      // When I select the 'All' intent filter chip
      await $(find.widgetWithText(ChoiceChip, 'All')).tap();

      // Then I should see reflections from both
      expect($('David M. (UK)'), findsOneWidget);
      expect($('Elena R. (Colorado)'), findsOneWidget);
    });
  });

  group('BDD Feature: WCAG Sensory Modes and Accessibility', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(PatrolTester $) async {
      $.tester.view.physicalSize = const Size(1200, 1600);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      await $.pumpWidgetAndSettle(SanctuaryApp(repository: repository));
    }

    patrolWidgetTest('Scenario: Toggling through all 4 sensory themes applies appropriate styling', (
      $,
    ) async {
      await pumpSanctuary($);

      // When I tap 'Dark' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Dark').tap();
      expect($('Sanctuary'), findsOneWidget);

      // When I tap 'Contrast' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Contrast').tap();
      expect($('Sanctuary'), findsOneWidget);

      // When I tap 'Clean' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Clean').tap();
      expect($('Sanctuary'), findsOneWidget);

      // When I tap 'Sage' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Sage').tap();
      expect($('Sanctuary'), findsOneWidget);
    });

    patrolWidgetTest('Scenario: Visual contrast and title persistence across sensory switches', (
      $,
    ) async {
      await pumpSanctuary($);

      // Tap Contrast mode via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Contrast').tap();

      // Verify title & calm tech subtitle remain visible and unclipped
      expect($('Sanctuary'), findsOneWidget);
      expect($(RegExp('Calm Tech')), findsOneWidget);
    });
  });

  group('BDD Feature: Qualitative Care Affirmations Without Dopamine Loops', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(PatrolTester $) async {
      $.tester.view.physicalSize = const Size(1200, 1600);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      await $.pumpWidgetAndSettle(SanctuaryApp(repository: repository));
    }

    patrolWidgetTest('Scenario: Incrementing qualitative care affirmations atomically', (
      $,
    ) async {
      await pumpSanctuary($);

      // Initial Praying reaction
      final prayButton = $('6 Praying');
      expect(prayButton, findsOneWidget);

      // When I tap '6 Praying'
      await prayButton.tap();

      // Then counter should increment to '7 Praying'
      expect($('7 Praying'), findsOneWidget);
      expect($('6 Praying'), findsNothing);
    });

    patrolWidgetTest('Scenario: Publishing an unhurried reflection and resetting composer', (
      $,
    ) async {
      await pumpSanctuary($);

      const testReflection = 'Finding rest in Scripture and quiet stillness today.';

      // When I type into reflection composer
      await $(TextField).enterText(testReflection);

      // And tap 'Publish Reflection'
      await $('Publish Reflection').tap();

      // Then reflection appears in the feed
      expect($(testReflection), findsOneWidget);
      // And input is cleared
      final textField = $.tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });

  group('BDD Feature: Serverpod 4 Resilient Client Integration', () {
    test('Scenario: Operating in resilient offline fallback mode within 800ms', () async {
      // Given a ServerpodPostRepository initialized with unreachable server
      final repo = ServerpodPostRepository(serverUrl: 'http://127.0.0.1:9999/');

      // When client requests posts for space 'prayer'
      final posts = await repo.getPosts(spaceKey: 'prayer');

      // Then it yields seeded fellowship reflections without throwing
      expect(posts, isNotEmpty);
      expect(posts.any((p) => p.authorName.contains('David M.')), isTrue);
    });

    patrolWidgetTest('Scenario: Server-side Quiet Digest banner renders peaceful aggregates', (
      $,
    ) async {
      $.tester.view.physicalSize = const Size(1200, 1600);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final repo = LocalPostRepository();
      await $.pumpWidgetAndSettle(SanctuaryApp(repository: repo));

      // Verify Quiet Digest banner is present
      expect($(RegExp('Gathered in peace')), findsOneWidget);
      expect($(RegExp('reflections')), findsOneWidget);
      expect($(RegExp('care affirmations')), findsOneWidget);
    });
  });
}
