import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Sanctuary App & PostRepository Widget Tests', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpApp(WidgetTester tester) async {
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
      'Renders Sanctuary header, seeded posts, and space navigation',
      (WidgetTester tester) async {
        await pumpApp(tester);

        // Verify title & calm-tech subtitle
        expect(find.text('Sanctuary'), findsOneWidget);
        expect(find.textContaining('Calm Tech'), findsOneWidget);

        // Verify default spaces navigation chips
        expect(find.text('🙏 #prayer-sanctuary'), findsOneWidget);
        expect(find.text('📖 #weekly-study'), findsOneWidget);

        // Verify seeded posts in default 'prayer' space
        expect(find.text('David M. (UK)'), findsOneWidget);
        expect(find.text('Elena R. (Colorado)'), findsOneWidget);
        // Pastor Thomas is in 'study' space, so shouldn't appear in 'prayer'
        expect(find.text('Pastor Thomas (Melbourne)'), findsNothing);
      },
    );

    testWidgets('Switching space updates the stream of posts', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Tap on #weekly-study space chip
      await tester.tap(find.text('📖 #weekly-study'));
      await tester.pumpAndSettle();

      // Now Pastor Thomas should be visible, and David M. should not
      expect(find.text('Pastor Thomas (Melbourne)'), findsOneWidget);
      expect(find.text('David M. (UK)'), findsNothing);

      // Tap on #announcements (empty space)
      await tester.tap(find.text('📢 #announcements'));
      await tester.pumpAndSettle();

      // Verify empty space peaceful placeholder
      expect(find.textContaining('Space is quiet right now'), findsOneWidget);
    });

    testWidgets('Toggling sensory themes switches theme mode without errors', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Tap 'Dark' (charcoal) via Sensory Themes menu
      await tester.tap(find.byTooltip('Sensory Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Tap 'Contrast' via Sensory Themes menu
      await tester.tap(find.byTooltip('Sensory Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contrast'));
      await tester.pumpAndSettle();

      // Tap 'Clean' via Sensory Themes menu
      await tester.tap(find.byTooltip('Sensory Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clean'));
      await tester.pumpAndSettle();

      // Tap 'Sage' via Sensory Themes menu
      await tester.tap(find.byTooltip('Sensory Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sage'));
      await tester.pumpAndSettle();

      expect(find.text('Sanctuary'), findsOneWidget);
    });

    testWidgets('Publishing a reflection adds it to the top of the feed', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      const testContent =
          'Grateful for quiet moments of stillness in a hurried world.';

      // Enter text into the reflection TextField
      await tester.enterText(find.byType(TextField), testContent);
      await tester.pumpAndSettle();

      // Tap 'Publish Reflection'
      await tester.tap(find.text('Publish Reflection'));
      await tester.pumpAndSettle();

      // Verify the new post is rendered
      expect(find.text(testContent), findsOneWidget);
      expect(find.text('Fellowship Member'), findsOneWidget);

      // Verify input field was cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Incrementing qualitative care reactions updates counts', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Find first '🙏 6 Praying' button
      final prayingButton = find.text('6 Praying');
      expect(prayingButton, findsOneWidget);

      // Tap pray reaction
      await tester.tap(prayingButton);
      await tester.pumpAndSettle();

      // Verify it incremented to 7
      expect(find.text('7 Praying'), findsOneWidget);
      expect(find.text('6 Praying'), findsNothing);

      // Find '🤍 4 Support' button
      final supportButton = find.text('4 Support');
      expect(supportButton, findsOneWidget);

      // Tap support reaction
      await tester.tap(supportButton);
      await tester.pumpAndSettle();

      // Verify incremented to 5
      expect(find.text('5 Support'), findsOneWidget);
      expect(find.text('4 Support'), findsNothing);
    });

    testWidgets('Filtering by tone tags displays only matching posts', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Initially in 'prayer' space: David M. has [Prayer Request], Elena R. has [Comfort Only]
      expect(find.text('David M. (UK)'), findsOneWidget);
      expect(find.text('Elena R. (Colorado)'), findsOneWidget);

      // Tap filter chip for '[Comfort Only]'
      // Note: filter row has a ChoiceChip with '[Comfort Only]'
      final comfortFilterChips = find.widgetWithText(
        ChoiceChip,
        '[Comfort Only]',
      );
      await tester.tap(comfortFilterChips.first);
      await tester.pumpAndSettle();

      // Elena should be present, David should be filtered out
      expect(find.text('Elena R. (Colorado)'), findsOneWidget);
      expect(find.text('David M. (UK)'), findsNothing);

      // Switch filter back to 'All'
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('David M. (UK)'), findsOneWidget);
      expect(find.text('Elena R. (Colorado)'), findsOneWidget);
    });

    testWidgets('Calm-tech meme gallery allows selecting and dismissing meme', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Verify 'Add Meme / GIF' button is present
      final addMemeButton = find.text('Add Meme / GIF');
      expect(addMemeButton, findsOneWidget);

      // Open gallery modal
      await tester.tap(addMemeButton);
      await tester.pumpAndSettle();

      // Check modal content
      expect(find.text('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);
      expect(find.text('Elijah Under the Broom Tree'), findsOneWidget);

      // Tap on Elijah meme
      await tester.tap(find.text('Elijah Under the Broom Tree'));
      await tester.pumpAndSettle();

      // Modal is dismissed, attachment preview banner is shown
      expect(find.text('Attached: Elijah Under the Broom Tree'), findsOneWidget);
      expect(find.text('Change Meme'), findsOneWidget);

      // Dismiss the meme
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // Preview banner is gone, button returns to 'Add Meme / GIF'
      expect(find.text('Attached: Elijah Under the Broom Tree'), findsNothing);
      expect(find.text('Add Meme / GIF'), findsOneWidget);
    });
  });
}
