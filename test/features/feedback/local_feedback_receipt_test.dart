import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/feedback/domain/local_feedback_receipt.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone M4a: Feedback Visibility Receipt ("What I Entered") (#852)', () {
    test('LocalFeedbackReceipt serialization round-trip', () {
      final receipt = LocalFeedbackReceipt(
        id: '123',
        message: 'The prayer button is calm and clear.',
        sentimentLabel: 'Happy',
        sentimentEmoji: '😊',
        rating: 5,
        contact: 'bruce@example.com',
        hasDrawing: true,
        timestamp: DateTime.utc(2026, 11, 2, 23, 0),
      );

      final json = receipt.toJson();
      final roundTrip = LocalFeedbackReceipt.fromJson(json);

      expect(roundTrip.id, equals('123'));
      expect(roundTrip.message, equals('The prayer button is calm and clear.'));
      expect(roundTrip.sentimentLabel, equals('Happy'));
      expect(roundTrip.sentimentEmoji, equals('😊'));
      expect(roundTrip.rating, equals(5));
      expect(roundTrip.contact, equals('bruce@example.com'));
      expect(roundTrip.hasDrawing, isTrue);
      expect(roundTrip.timestamp, equals(DateTime.utc(2026, 11, 2, 23, 0)));
    });

    test('LocalFeedbackReceiptStore saves and loads receipts', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await LocalFeedbackReceiptStore.loadReceipts(), isEmpty);

      final receipt = LocalFeedbackReceipt(
        id: 'rec_1',
        message: 'Could not see what I entered previously.',
        sentimentLabel: 'Needs Help',
        sentimentEmoji: '😐',
        rating: 3,
        timestamp: DateTime.now(),
      );

      await LocalFeedbackReceiptStore.saveReceipt(receipt);
      final loaded = await LocalFeedbackReceiptStore.loadReceipts();
      expect(loaded.length, equals(1));
      expect(loaded.first.message, equals('Could not see what I entered previously.'));
    });

    patrolWidgetTest('Submitting feedback renders "Your Recent Submissions" receipt card', ($) async {
      SharedPreferences.setMockInitialValues({});
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BelongFeedbackAndVotingSheet(initialTabIndex: 1),
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      // Enter feedback note
      final messageField = $(Key('feedback_message_input'));
      expect(messageField, findsOneWidget);
      await $(messageField).enterText('Testing feedback receipt history (#852)');
      await $.pumpAndSettle();

      // Tap submit button
      final submitBtn = $(Key('submit_feedback_button'));
      expect(submitBtn, findsOneWidget);
      await $(submitBtn).tap();
      await $.pumpAndSettle();

      // Verify the recent submissions card is immediately rendered with the entered note
      expect($(Key('recent_submissions_history_card')), findsOneWidget);
      expect($('Your Recent Submissions (1)'), findsOneWidget);
      expect($('Testing feedback receipt history (#852)'), findsOneWidget);

      // Verify receipt was persisted in SharedPreferences
      final savedReceipts = await LocalFeedbackReceiptStore.loadReceipts();
      expect(savedReceipts.length, equals(1));
      expect(savedReceipts.first.message, equals('Testing feedback receipt history (#852)'));
    });
  });
}
