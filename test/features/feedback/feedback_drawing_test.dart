import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/application/private_feedback_router.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/feedback_drawing_canvas.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('PrivateFeedbackRouter Attachment Formatting', () {
    test('formatPrivateIssue embeds attachment markdown when attachmentUrl is provided', () {
      const router = PrivateFeedbackRouter();
      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.sad,
        message: 'hi, feedback from 20-octoberpm',
        contactEmail: 'tester@belongonthespectrum.com',
        attachmentUrl: 'https://storage.belongonthespectrum.com/feedback/attachments/scribble_123.png',
      );

      expect(payload.repository, 'neiljaywarner/belong_feedback');
      expect(payload.title, '[Bug / Confusing] hi, feedback from 20-octoberpm');
      expect(payload.labels, contains('bug-report'));
      expect(payload.body, contains('### Annotated Screenshot / Scribble Attachment'));
      expect(payload.body, contains('![Annotated Screenshot](https://storage.belongonthespectrum.com/feedback/attachments/scribble_123.png)'));
      expect(payload.body, contains('### Feedback Note\nhi, feedback from 20-octoberpm'));
    });
  });

  group('FeedbackDrawingCanvas Unit & Interaction Tests', () {
    testWidgets('FeedbackDrawingCanvas can draw strokes and export PNG bytes', (tester) async {
      final key = GlobalKey<FeedbackDrawingCanvasState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedbackDrawingCanvas(
              key: key,
              canvasHeight: 200,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify canvas rendered
      expect(find.byKey(const Key('feedback_drawing_touch_area')), findsOneWidget);

      // Perform dragging gesture to simulate user drawing
      final touchArea = find.byKey(const Key('feedback_drawing_touch_area'));
      final gesture = await tester.startGesture(tester.getCenter(touchArea));
      await gesture.moveBy(const Offset(40, 40));
      await gesture.moveBy(const Offset(-20, 30));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(key.currentState?.strokes.length, greaterThanOrEqualTo(1));

      // Test export PNG
      final bytes = await key.currentState?.exportPngBytes(width: 100, height: 100);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));

      // Test undo
      key.currentState?.undo();
      await tester.pumpAndSettle();
      expect(key.currentState?.strokes.isEmpty, isTrue);
    });
  });

  group('BelongFeedbackAndVotingSheet Scribble Attachment Flow', () {
    patrolWidgetTest(
      'Opens drawing dialog, attaches scribble, and submits feedback with attachment',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        final inMemoryRepo = InMemoryFeatureVotingRepository();
        final inMemoryStorage = InMemoryStorageRepository();

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              featureVotingRepositoryProvider.overrideWithValue(inMemoryRepo),
              storageRepositoryProvider.overrideWithValue(inMemoryStorage),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: BelongFeedbackAndVotingSheet(initialTabIndex: 1),
              ),
            ),
          ),
        );

        // Switch to sad / bug sentiment
        expect($(const Key('sentiment_sad')), findsOneWidget);
        await $(const Key('sentiment_sad')).tap();
        await $.pumpAndSettle();

        // Enter note
        await $(const Key('feedback_message_input')).enterText('hi, feedback from 20-octoberpm');
        await $(const Key('feedback_contact_input')).enterText('tester@belong.org');
        await $.pumpAndSettle();

        // Open drawing dialog
        expect($(const Key('open_feedback_drawing_button')), findsOneWidget);
        await $(const Key('open_feedback_drawing_button')).tap();
        await $.pumpAndSettle();

        // Verify drawing dialog is open
        expect($('Draw / Annotate Feedback'), findsOneWidget);
        expect($(const Key('feedback_drawing_touch_area')), findsOneWidget);

        // Draw a stroke
        await $.tester.drag(find.byKey(const Key('feedback_drawing_touch_area')), const Offset(50, 50));
        await $.pumpAndSettle();

        // Tap attach scribble
        expect($(const Key('drawing_dialog_attach_button')), findsOneWidget);
        await $(const Key('drawing_dialog_attach_button')).tap();
        await $.pumpAndSettle();

        // Verify thumbnail is displayed in feedback sheet
        expect($(const Key('attached_scribble_preview_container')), findsOneWidget);
        expect($(const Key('attached_scribble_thumbnail')), findsOneWidget);

        // Submit feedback
        expect($(const Key('submit_feedback_button')), findsOneWidget);
        await $(const Key('submit_feedback_button')).tap();
        await $.pumpAndSettle();

        // Check success message
        expect($('Thank you! Your note was securely routed to our private triage queue (belong_feedback) so your privacy is 100% protected.'), findsOneWidget);

        // Verify in-memory repository recorded the submission with attachmentUrl
        expect(inMemoryRepo.submittedFeedbackLog.length, 1);
        final log = inMemoryRepo.submittedFeedbackLog.first;
        expect(log['message'], 'hi, feedback from 20-octoberpm');
        expect(log['contactEmail'], 'tester@belong.org');
        expect(log['destination'], 'neiljaywarner/belong_feedback');
        expect(log['hasScreenshotAttachment'], 'true');
        expect(log['attachmentUrl'], contains('https://storage.belongonthespectrum.com/feedback/attachments/'));
      },
    );
  });
}
