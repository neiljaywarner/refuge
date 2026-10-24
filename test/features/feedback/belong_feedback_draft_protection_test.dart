import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/data/vote_storage_service.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';

void main() {
  setUp(() {
    VoteStorageService.instance.clear();
  });

  tearDown(() {
    VoteStorageService.instance.clear();
  });

  group('BelongFeedbackAndVotingSheet Draft Protection Tests (#525)', () {
    patrolWidgetTest(
      'empty feedback closes immediately without discard dialog',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () => BelongFeedbackAndVotingSheet.show(
                      context,
                      initialTabIndex: 1,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await $(const Key('open_sheet_button')).tap();
        expect($(const Key('close_feedback_sheet_button')), findsOneWidget);

        // Tap close button when nothing is typed
        await $(const Key('close_feedback_sheet_button')).tap();

        // Discard dialog is NOT shown
        expect($(const Key('confirm_discard_feedback_dialog')), findsNothing);
        // Sheet is closed
        expect($(const Key('close_feedback_sheet_button')), findsNothing);
      },
    );

    patrolWidgetTest(
      'typed feedback text prompts discard dialog on close, keep editing retains text',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () => BelongFeedbackAndVotingSheet.show(
                      context,
                      initialTabIndex: 1,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await $(const Key('open_sheet_button')).tap();

        // Enter feedback text
        await $(const Key('feedback_message_input')).enterText(
          'Draft message that should be protected from accidental dismissal',
        );

        // Attempt to close via header close button
        await $(const Key('close_feedback_sheet_button')).tap();

        // Discard dialog appears
        expect($(const Key('confirm_discard_feedback_dialog')), findsOneWidget);
        expect($('Discard unsaved feedback?'), findsOneWidget);

        // Tap "Keep Editing"
        await $(const Key('discard_feedback_cancel_button')).tap();

        // Dialog is gone, sheet is still open, text is retained
        expect($(const Key('confirm_discard_feedback_dialog')), findsNothing);
        expect($(const Key('close_feedback_sheet_button')), findsOneWidget);
        expect(
          $('Draft message that should be protected from accidental dismissal'),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      'typed feedback text prompts discard dialog, discard button closes sheet',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () => BelongFeedbackAndVotingSheet.show(
                      context,
                      initialTabIndex: 1,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await $(const Key('open_sheet_button')).tap();

        // Enter text
        await $(const Key('feedback_message_input')).enterText('Discard me please');

        // Tap close
        await $(const Key('close_feedback_sheet_button')).tap();

        expect($(const Key('confirm_discard_feedback_dialog')), findsOneWidget);

        // Tap Discard
        await $(const Key('discard_feedback_confirm_button')).tap();

        // Both dialog and sheet are closed
        expect($(const Key('confirm_discard_feedback_dialog')), findsNothing);
        expect($(const Key('close_feedback_sheet_button')), findsNothing);
      },
    );

    patrolWidgetTest(
      'drawing screenshot button renders cleanly on feedback tab',
      ($) async {
        $.tester.view.physicalSize = const Size(1000, 1600);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown($.tester.view.resetPhysicalSize);

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () => BelongFeedbackAndVotingSheet.show(
                      context,
                      initialTabIndex: 1,
                      screenshotBytes: Uint8List.fromList([1, 2, 3]),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await $(const Key('open_sheet_button')).tap();

        expect($(const Key('open_feedback_drawing_button')), findsOneWidget);
      },
    );
  });
}
