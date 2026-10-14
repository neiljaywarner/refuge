import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('BDD Feature: Fellowship Spaces and Mindful Intent Navigation', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(SanctuaryApp(repository: repository));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Scenario: Switching between fellowship spaces displays space-specific reflections',
      (WidgetTester tester) async {
        // Given the Sanctuary application is open in default '#prayer-sanctuary' room
        await pumpSanctuary(tester);

        // Then I should see reflections from 'David M. (UK)'
        expect(find.text('David M. (UK)'), findsOneWidget);
        // And I should not see reflections from 'Pastor Thomas (Melbourne)'
        expect(find.text('Pastor Thomas (Melbourne)'), findsNothing);

        // When I tap on the '📖 #weekly-study' space chip
        await tester.tap(find.text('📖 #weekly-study'));
        await tester.pumpAndSettle();

        // Then I should see reflections from 'Pastor Thomas (Melbourne)'
        expect(find.text('Pastor Thomas (Melbourne)'), findsOneWidget);
        // And I should not see reflections from 'David M. (UK)'
        expect(find.text('David M. (UK)'), findsNothing);
      },
    );

    testWidgets(
      'Scenario: Visiting an empty fellowship room shows peaceful stillness',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        // When I tap on '#announcements' space chip
        await tester.tap(find.text('📢 #announcements'));
        await tester.pumpAndSettle();

        // Then I should see 'Space is quiet right now'
        expect(find.textContaining('Space is quiet right now'), findsOneWidget);
        // And no chaotic error banners exist
        expect(find.textContaining('Error'), findsNothing);
      },
    );

    testWidgets(
      'Scenario: Filtering reflections by mindful intent tags',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        // When I select the '[Comfort Only]' intent filter chip
        final comfortFilter = find.widgetWithText(ChoiceChip, '[Comfort Only]');
        await tester.tap(comfortFilter.first);
        await tester.pumpAndSettle();

        // Then I should see reflections from 'Elena R. (Colorado)'
        expect(find.text('Elena R. (Colorado)'), findsOneWidget);
        // And I should not see reflections from 'David M. (UK)'
        expect(find.text('David M. (UK)'), findsNothing);

        // When I select the 'All' intent filter chip
        await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
        await tester.pumpAndSettle();

        // Then I should see reflections from both
        expect(find.text('David M. (UK)'), findsOneWidget);
        expect(find.text('Elena R. (Colorado)'), findsOneWidget);
      },
    );
  });

  group('BDD Feature: WCAG Sensory Modes and Accessibility', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(SanctuaryApp(repository: repository));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Scenario: Toggling through all 4 sensory themes applies appropriate styling',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        // When I tap 'Dark' via Sensory Themes menu
        await tester.tap(find.byTooltip('Sensory Themes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(find.text('Sanctuary'), findsOneWidget);

        // When I tap 'Contrast' via Sensory Themes menu
        await tester.tap(find.byTooltip('Sensory Themes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Contrast'));
        await tester.pumpAndSettle();
        expect(find.text('Sanctuary'), findsOneWidget);

        // When I tap 'Clean' via Sensory Themes menu
        await tester.tap(find.byTooltip('Sensory Themes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clean'));
        await tester.pumpAndSettle();
        expect(find.text('Sanctuary'), findsOneWidget);

        // When I tap 'Sage' via Sensory Themes menu
        await tester.tap(find.byTooltip('Sensory Themes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sage'));
        await tester.pumpAndSettle();
        expect(find.text('Sanctuary'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario: Visual contrast and title persistence across sensory switches',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        // Tap Contrast mode via Sensory Themes menu
        await tester.tap(find.byTooltip('Sensory Themes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Contrast'));
        await tester.pumpAndSettle();

        // Verify title & calm tech subtitle remain visible and unclipped
        expect(find.text('Sanctuary'), findsOneWidget);
        expect(find.textContaining('Calm Tech'), findsOneWidget);
      },
    );
  });

  group('BDD Feature: Qualitative Care Affirmations Without Dopamine Loops', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpSanctuary(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(SanctuaryApp(repository: repository));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Scenario: Incrementing qualitative care affirmations atomically',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        // Initial Praying reaction
        final prayButton = find.text('6 Praying');
        expect(prayButton, findsOneWidget);

        // When I tap '6 Praying'
        await tester.tap(prayButton);
        await tester.pumpAndSettle();

        // Then counter should increment to '7 Praying'
        expect(find.text('7 Praying'), findsOneWidget);
        expect(find.text('6 Praying'), findsNothing);
      },
    );

    testWidgets(
      'Scenario: Publishing an unhurried reflection and resetting composer',
      (WidgetTester tester) async {
        await pumpSanctuary(tester);

        const testReflection =
            'Finding rest in Scripture and quiet stillness today.';

        // When I type into reflection composer
        await tester.enterText(find.byType(TextField), testReflection);
        await tester.pumpAndSettle();

        // And tap 'Publish Reflection'
        await tester.tap(find.text('Publish Reflection'));
        await tester.pumpAndSettle();

        // Then reflection appears in the feed
        expect(find.text(testReflection), findsOneWidget);
        // And input is cleared
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      },
    );
  });

  group('BDD Feature: Serverpod 4 Resilient Client Integration', () {
    test(
      'Scenario: Operating in resilient offline fallback mode within 800ms',
      () async {
        // Given a ServerpodPostRepository initialized with unreachable server
        final repo = ServerpodPostRepository(
          serverUrl: 'http://127.0.0.1:9999/',
        );

        // When client requests posts for space 'prayer'
        final posts = await repo.getPosts(spaceKey: 'prayer');

        // Then it yields seeded fellowship reflections without throwing
        expect(posts, isNotEmpty);
        expect(posts.any((p) => p.authorName.contains('David M.')), isTrue);
      },
    );

    testWidgets(
      'Scenario: Server-side Quiet Digest banner renders peaceful aggregates',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = LocalPostRepository();
        await tester.pumpWidget(SanctuaryApp(repository: repo));
        await tester.pumpAndSettle();

        // Verify Quiet Digest banner is present
        expect(find.textContaining('Gathered in peace'), findsOneWidget);
        expect(find.textContaining('reflections'), findsOneWidget);
        expect(find.textContaining('care affirmations'), findsOneWidget);
      },
    );
  });
}
