import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_providers.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_recipient.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';

void main() {
  patrolWidgetTest('searching grokbot2 shows Fellow Member and not Marty', ($) async {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    final mailbox = InMemoryDirectMessageMailbox(
      seedUsers: {
        'uid-real': {
          'displayName': 'Fellow Member',
          'email': 'grokbot2@example.com',
          'bio': 'Handle search peer',
        },
      },
    );

    await $.pumpWidget(
      ProviderScope(
        overrides: [
          directMessageMailboxOverrideProvider.overrideWithValue(mailbox),
          messageRecipientIncludeSamplesProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: BelongMessagesView()),
      ),
    );
    await $.pumpAndSettle();

    await $(const Key('add_new_message_button')).tap();
    await $.pumpAndSettle();

    await $(const Key('recipient_search_input')).enterText('Handle search peer');
    await $.pumpAndSettle();

    expect($('Fellow Member'), findsOneWidget);
    expect($('Marty (Organizer)'), findsNothing);
    expect(find.bySemanticsIdentifier('dm-recipient-match'), findsOneWidget);
  });
}
