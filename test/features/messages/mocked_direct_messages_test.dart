import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';

void main() {
  void useTallScreen(PatrolTester $) {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });
  }

  group('Direct messages without a live inbox', () {
    patrolWidgetTest('Scenario: sending with no recipient or no text shows a gentle prompt', (
      $,
    ) async {
      useTallScreen($);
      await $.pumpWidgetAndSettle(
        const ProviderScope(child: MaterialApp(home: BelongMessagesView())),
      );

      await $(const Key('add_new_message_button')).tap();
      await $(const Key('send_new_message_button')).tap();
      await $.pump();
      expect($('Please select at least one recipient.'), findsOneWidget);
      await $.tester.pump(const Duration(seconds: 5));

      await $(const Key('member_picker_item_Caleb Stone')).tap();
      await $(const Key('send_new_message_button')).tap();
      await $.pump();
      expect($('Please write a message content.'), findsOneWidget);
      expect($('New Message'), findsOneWidget);
    });

    patrolWidgetTest('Scenario: a single recipient thread opens and an empty reply is ignored', (
      $,
    ) async {
      useTallScreen($);
      var leftMessages = false;
      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: MaterialApp(home: BelongMessagesView(onBackToHome: () => leftMessages = true)),
        ),
      );

      expect($(const Key('messages-back-button')), findsOneWidget);
      await $(const Key('messages-back-button')).tap();
      expect(leftMessages, isTrue);

      await $(const Key('add_new_message_button')).tap();
      await $(const Key('recipient_search_input')).enterText('acoustics');
      await $.pumpAndSettle();
      expect($(const Key('member_picker_item_Nathan K. (Texas)')), findsOneWidget);
      expect($(const Key('member_picker_item_Caleb Stone')), findsNothing);

      await $(const Key('recipient_search_input')).enterText('');
      await $(const Key('member_picker_item_Caleb Stone')).tap();
      expect($(const Key('selected_recipient_chip_Caleb Stone')), findsOneWidget);
      $.tester
          .widget<InputChip>(find.byKey(const Key('selected_recipient_chip_Caleb Stone')))
          .onDeleted
          ?.call();
      await $.pump();
      expect($(const Key('selected_recipient_chip_Caleb Stone')), findsNothing);

      await $(const Key('member_picker_item_Caleb Stone')).tap();
      await $(const Key('new_message_content_input'))
          .enterText('Would Thursday evening still feel calm?');
      await $(const Key('send_new_message_button')).tap();
      await $.pumpAndSettle();

      expect($('Caleb Stone'), findsWidgets);
      expect($('Would Thursday evening still feel calm?'), findsOneWidget);
      expect($('Caleb Stone & 1 others'), findsNothing);

      await $(const Key('send-reply-button')).tap();
      await $.pumpAndSettle();
      expect($('Would Thursday evening still feel calm?'), findsOneWidget);
    });

    patrolWidgetTest('Scenario: two recipients become a group thread', ($) async {
      useTallScreen($);
      await $.pumpWidgetAndSettle(
        const ProviderScope(child: MaterialApp(home: BelongMessagesView())),
      );

      await $(const Key('add_new_message_button')).tap();
      await $(const Key('member_picker_item_Marty (Organizer)')).tap();
      await $(const Key('member_picker_item_Sarah Chen')).tap();
      await $(const Key('new_message_subject_input')).enterText('Quiet check-in');
      await $(const Key('new_message_content_input')).enterText('No need to reply quickly.');
      await $(const Key('send_new_message_button')).tap();
      await $.pumpAndSettle();

      expect($('Quiet check-in'), findsOneWidget);
      expect($('No need to reply quickly.'), findsOneWidget);

      await $(const Key('back-to-messages-list')).tap();
      await $.pumpAndSettle();
      expect($('Marty (Organizer) & 1 others'), findsOneWidget);
      expect($('Quiet check-in: No need to reply quickly.'), findsOneWidget);
    });
  });
}
