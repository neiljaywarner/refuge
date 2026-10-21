import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Sanctuary App & PostRepository Widget Tests', () {
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
    });

    Future<void> pumpApp(PatrolTester $) async {
      $.tester.view.physicalSize = const Size(1200, 1600);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });
      await $.pumpWidgetAndSettle(SanctuaryApp(repository: repository));
    }

    patrolWidgetTest('Renders Sanctuary header, seeded posts, and space navigation', ($) async {
      await pumpApp($);

      // Verify title & calm-tech subtitle
      expect($('Sanctuary'), findsOneWidget);
      expect($(RegExp('Calm Tech')), findsOneWidget);

      // Verify default spaces navigation chips
      expect($('🙏 #prayer-sanctuary'), findsOneWidget);
      expect($('📖 #weekly-study'), findsOneWidget);

      // Verify seeded posts in default 'prayer' space
      expect($('David M. (UK)'), findsOneWidget);
      expect($('Elena R. (Colorado)'), findsOneWidget);
      // Pastor Thomas is in 'study' space, so shouldn't appear in 'prayer'
      expect($('Pastor Thomas (Melbourne)'), findsNothing);
    });

    patrolWidgetTest('Switching space updates the stream of posts', ($) async {
      await pumpApp($);

      // Tap on #weekly-study space chip
      await $('📖 #weekly-study').tap();

      // Now Pastor Thomas should be visible, and David M. should not
      expect($('Pastor Thomas (Melbourne)'), findsOneWidget);
      expect($('David M. (UK)'), findsNothing);

      // Tap on #announcements (empty space)
      await $('📢 #announcements').tap();

      // Verify empty space peaceful placeholder
      expect($(RegExp('Space is quiet right now')), findsOneWidget);
    });

    patrolWidgetTest('Toggling sensory themes switches theme mode without errors', ($) async {
      await pumpApp($);

      // Tap 'Dark' (charcoal) via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Dark').tap();

      // Tap 'Contrast' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Contrast').tap();

      // Tap 'Clean' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Clean').tap();

      // Tap 'Sage' via Sensory Themes menu
      await $(find.byTooltip('Sensory Themes')).tap();
      await $('Sage').tap();

      expect($('Sanctuary'), findsOneWidget);
    });

    patrolWidgetTest('Publishing a reflection adds it to the top of the feed', ($) async {
      await pumpApp($);

      const testContent = 'Grateful for quiet moments of stillness in a hurried world.';

      // Enter text into the reflection TextField
      await $(TextField).enterText(testContent);

      // Tap 'Publish Reflection'
      await $('Publish Reflection').tap();

      // Verify the new post is rendered
      expect($(testContent), findsOneWidget);
      expect($('Fellowship Member'), findsOneWidget);

      // Verify input field was cleared
      final textField = $.tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    patrolWidgetTest('Incrementing qualitative care reactions updates counts', ($) async {
      await pumpApp($);

      // Find first '🙏 6 Praying' button
      final prayingButton = $('6 Praying');
      expect(prayingButton, findsOneWidget);

      // Tap pray reaction
      await prayingButton.tap();

      // Verify it incremented to 7
      expect($('7 Praying'), findsOneWidget);
      expect($('6 Praying'), findsNothing);

      // Find '🤍 4 Support' button
      final supportButton = $('4 Support');
      expect(supportButton, findsOneWidget);

      // Tap support reaction
      await supportButton.tap();

      // Verify incremented to 5
      expect($('5 Support'), findsOneWidget);
      expect($('4 Support'), findsNothing);
    });

    patrolWidgetTest('Filtering by tone tags displays only matching posts', ($) async {
      await pumpApp($);

      // Initially in 'prayer' space: David M. has [Prayer Request], Elena R. has [Comfort Only]
      expect($('David M. (UK)'), findsOneWidget);
      expect($('Elena R. (Colorado)'), findsOneWidget);

      // Tap filter chip for '[Comfort Only]'
      final comfortFilterChips = $(find.widgetWithText(ChoiceChip, '[Comfort Only]'));
      await comfortFilterChips.first.tap();

      // Elena should be present, David should be filtered out
      expect($('Elena R. (Colorado)'), findsOneWidget);
      expect($('David M. (UK)'), findsNothing);

      // Switch filter back to 'All'
      await $(find.widgetWithText(ChoiceChip, 'All')).tap();

      expect($('David M. (UK)'), findsOneWidget);
      expect($('Elena R. (Colorado)'), findsOneWidget);
    });

    patrolWidgetTest('Calm-tech meme gallery allows selecting and dismissing meme', ($) async {
      await pumpApp($);

      // Verify 'Add Meme / GIF' button is present
      final addMemeButton = $('Add Meme / GIF');
      expect(addMemeButton, findsOneWidget);

      // Open gallery modal
      await addMemeButton.tap();

      // Check modal content
      expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);
      expect($('Elijah Under the Broom Tree'), findsOneWidget);

      // Tap on Elijah meme
      await $('Elijah Under the Broom Tree').tap();

      // Modal is dismissed, attachment preview banner is shown
      expect($('Attached: Elijah Under the Broom Tree'), findsOneWidget);
      expect($('Change Meme'), findsOneWidget);

      // Dismiss the meme
      await $(Icons.close).first.tap();

      // Preview banner is gone, button returns to 'Add Meme / GIF'
      expect($('Attached: Elijah Under the Broom Tree'), findsNothing);
      expect($('Add Meme / GIF'), findsOneWidget);
    });
  });
}
