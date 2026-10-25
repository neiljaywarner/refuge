import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/application/private_feedback_router.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/github_feedback_client.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/feedback_and_voting_models.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/feedback_drawing_canvas.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('PrivateFeedbackRouter Attachment Formatting', () {
    test('formatPrivateIssue does not present the storage stub as an uploaded image', () {
      const router = PrivateFeedbackRouter();
      const stub = 'https://storage.belongonthespectrum.com/feedback/attachments/scribble_123.png';
      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.sad,
        message: 'hi, feedback from 20-octoberpm',
        contactEmail: 'tester@belongonthespectrum.com',
        attachmentUrl: stub,
      );

      expect(payload.repository, 'neiljaywarner/belong_feedback');
      expect(payload.title, '[Bug / Confusing] hi, feedback from 20-octoberpm');
      expect(payload.labels, contains('bug-report'));
      expect(payload.body, contains('### Annotated Screenshot / Scribble Attachment'));
      expect(payload.body, isNot(contains('![Annotated Screenshot]($stub)')));
      expect(payload.body, contains('It was not uploaded'));
      expect(payload.body, contains('### Feedback Note\nhi, feedback from 20-octoberpm'));
    });

    test('formatPrivateIssue embeds a real hosted attachment URL', () {
      const router = PrivateFeedbackRouter();
      const hosted = 'https://example.com/feedback/scribble_123.png';
      final payload = router.formatPrivateIssue(
        sentiment: FeedbackSentiment.sad,
        message: 'hi, feedback from 20-octoberpm',
        attachmentUrl: hosted,
      );

      expect(payload.body, contains('![Annotated Screenshot]($hosted)'));
    });
  });

  group('FeedbackDrawingCanvas Unit & Interaction Tests', () {
    testWidgets('FeedbackDrawingCanvas can draw strokes and export PNG bytes', (tester) async {
      final key = GlobalKey<FeedbackDrawingCanvasState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FeedbackDrawingCanvas(key: key, canvasHeight: 200)),
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

    testWidgets(
      'FeedbackDrawingDialog preserves strokes and avoids overflow on landscape rotation (#386)',
      (tester) async {
        // Start in portrait orientation
        tester.view.physicalSize = const Size(420, 840);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Dialog(insetPadding: EdgeInsets.all(16), child: FeedbackDrawingDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Draw a stroke in portrait
        final touchArea = find.byKey(const Key('feedback_drawing_touch_area'));
        await tester.drag(touchArea, const Offset(45, 35));
        await tester.pumpAndSettle();

        final canvasState = tester.state<FeedbackDrawingCanvasState>(
          find.byType(FeedbackDrawingCanvas),
        );
        expect(canvasState.strokes.length, 1);

        // Rotate to compact landscape viewport
        tester.view.physicalSize = const Size(840, 380);
        await tester.pumpAndSettle();

        // Verify zero overflow exceptions and stroke is preserved
        expect(tester.takeException(), isNull);
        expect(canvasState.strokes.length, 1);
        expect(find.text('Feedback drawing canvas, 1 stroke'), findsOneWidget);
      },
    );

    testWidgets('dialog announces a captured screenshot and a close label', (tester) async {
      const png = <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    FeedbackDrawingDialog.show(context, screenshotBytes: Uint8List.fromList(png)),
                child: const Text('Open drawing'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open drawing'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Annotating a screenshot of this screen'), findsOneWidget);
      expect(find.byTooltip('Close drawing'), findsOneWidget);
      expect(find.text('Feedback drawing canvas, 0 strokes'), findsOneWidget);
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
              home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: 1)),
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
        await $.tester.drag(
          find.byKey(const Key('feedback_drawing_touch_area')),
          const Offset(50, 50),
        );
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

        // The sheet must not claim a GitHub filing or a hosted upload.
        expect(
          $(
            'Thank you. Your note was saved for organizers and copied to the clipboard. It was not sent to GitHub. The drawing stayed with the note and was not uploaded.',
          ),
          findsOneWidget,
        );
        expect($('belong_feedback'), findsNothing);
        expect($('storage.belongonthespectrum.com'), findsNothing);

        expect(inMemoryRepo.submittedFeedbackLog.length, 1);
        final log = inMemoryRepo.submittedFeedbackLog.first;
        expect(log['message'], 'hi, feedback from 20-octoberpm');
        expect(log['contactEmail'], 'tester@belong.org');
        expect(log['destination'], 'neiljaywarner/belong_feedback');
        expect(log['hasScreenshotAttachment'], 'true');
        expect(log['githubIssueCreated'], 'false');
        expect(log['storedIn'], 'member_feedback');
        expect(log['attachmentDelivery'], 'local_only');
        expect(log.containsKey('attachmentUrl'), isFalse);
        expect(
          inMemoryStorage.retainedPaths.any((path) => path.startsWith('feedback/attachments/')),
          isTrue,
        );
        expect(
          inMemoryStorage.retainedPaths.join(' '),
          isNot(contains('storage.belongonthespectrum.com')),
        );
      },
    );

    patrolWidgetTest(
      'Submits feedback with configured GitHub client and displays issue number confirmation',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        final mockHttp = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'number': 42,
              'html_url': 'https://github.com/neiljaywarner/belong_feedback/issues/42',
            }),
            201,
          ),
        );

        final client = GitHubFeedbackClient(httpClient: mockHttp, token: 'ghp_sample_token');
        final inMemoryRepo = InMemoryFeatureVotingRepository(gitHubClient: client);

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [featureVotingRepositoryProvider.overrideWithValue(inMemoryRepo)],
            child: const MaterialApp(
              home: Scaffold(body: BelongFeedbackAndVotingSheet(initialTabIndex: 1)),
            ),
          ),
        );

        // Switch to sad / bug sentiment
        await $(const Key('sentiment_sad')).tap();
        await $.pumpAndSettle();

        // Enter note
        await $(const Key('feedback_message_input'))
            .enterText('A bug occurred while testing feedback dispatch.');
        await $.pumpAndSettle();

        // Submit
        await $(const Key('submit_feedback_button')).tap();
        await $.pumpAndSettle();

        expect(
          $(
            'Thank you! Your feedback was routed to our private triage queue (belong_feedback#42).',
          ),
          findsOneWidget,
        );
        expect(inMemoryRepo.submittedFeedbackLog.length, 1);
        final log = inMemoryRepo.submittedFeedbackLog.first;
        expect(log['githubIssueCreated'], 'true');
        expect(log['githubIssueNumber'], '42');
      },
    );
  });
}
