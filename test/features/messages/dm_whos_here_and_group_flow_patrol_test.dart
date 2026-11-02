import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_providers.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/profile/data/member_directory_store.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  void useTallScreen(PatrolTester $) {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });
  }

  group('Direct Message Who\'s Here, Named Groups & Durable Replies (#818)', () {
    patrolWidgetTest(
      'Who\'s Here checkboxes create a named Group DM and persist replies to mailbox',
      ($) async {
        useTallScreen($);
        final mailbox = InMemoryDirectMessageMailbox(
          seedUsers: {
            'uid-caleb': {
              'displayName': 'Caleb Stone',
              'email': 'caleb+audio@example.com',
              'tagline': 'Soundscapes and calm lighting',
              'listedInDirectory': true,
            },
            'uid-sarah': {
              'displayName': 'Sarah Chen',
              'email': 'sarah+greek@example.com',
              'tagline': 'Greek word studies and chiasms',
              'listedInDirectory': true,
            },
          },
        );

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              appFlavorProvider.overrideWithValue(AppFlavor.prod),
              directMessageMailboxOverrideProvider.overrideWithValue(mailbox),
              messageRecipientIncludeSamplesProvider.overrideWithValue(false),
            ],
            child: const MaterialApp(home: BelongMessagesView()),
          ),
        );

        // Prod starts with zero sample threads when remote inbox is empty
        expect($(const Key('empty_messages_placeholder')), findsOneWidget);
        expect($('Marty & Community Team'), findsNothing);

        // Open New Message modal and verify Who's Here checkboxes appear without typing
        await $(const Key('add_new_message_button')).tap();
        await $.pumpAndSettle();

        expect($(const Key('dm_whos_here_header')), findsOneWidget);
        expect($(const Key('dm_directory_checkbox_uid-caleb')), findsOneWidget);
        expect($(const Key('dm_directory_checkbox_uid-sarah')), findsOneWidget);

        // Select two members via Who's Here checkboxes
        await $(const Key('dm_directory_checkbox_uid-caleb')).tap();
        await $.pumpAndSettle();
        await $(const Key('dm_directory_checkbox_uid-sarah')).tap();
        await $.pumpAndSettle();

        // Group Name field is now visible because 2+ members are selected
        expect($(const Key('new_message_group_name_input')), findsOneWidget);
        await $(const Key('new_message_group_name_input')).enterText('Friday Wingspan Circle');
        await $(const Key('new_message_subject_input')).enterText('Quiet Table');
        await $(const Key('new_message_content_input'))
            .enterText('Shall we meet at 6 PM in the quiet room?');

        await $(const Key('send_new_message_button')).tap();
        await $.tester.pump(const Duration(milliseconds: 1600));
        await $.pumpAndSettle();

        // Active thread shows the named Group title
        expect($('Friday Wingspan Circle'), findsWidgets);
        expect($('Shall we meet at 6 PM in the quiet room?'), findsOneWidget);

        // Send a reply and verify it persists in the mailbox
        await $(const Key('reply-message-field')).enterText('I will bring herbal tea!');
        await $.pumpAndSettle();
        await $(const Key('send-reply-button')).tap();
        await $.pumpAndSettle();

        expect($('I will bring herbal tea!'), findsOneWidget);
        final storedForCaleb = await mailbox.loadThreads('uid-caleb');
        expect(storedForCaleb, hasLength(1));
        expect(storedForCaleb.single.displayTitle, 'Friday Wingspan Circle');
        expect(storedForCaleb.single.messages, hasLength(2));
        expect(storedForCaleb.single.messages.last.content, 'I will bring herbal tea!');
      },
    );

    patrolWidgetTest('Group thread renders sender attribution labels on incoming bubbles', (
      $,
    ) async {
      useTallScreen($);
      final groupThread = MessageThread(
        id: 'dm-group-1',
        participantName: 'Friday Wingspan Circle',
        groupName: 'Friday Wingspan Circle',
        avatarInitials: 'FW',
        subject: 'Game Night',
        messageType: 'Group',
        participantIds: const ['uid-me', 'uid-caleb', 'uid-sarah'],
        recipientIds: const ['uid-caleb', 'uid-sarah'],
        previewSnippet: 'Looking forward to it!',
        lastActivity: DateTime.now(),
        messages: [
          DirectMessage(
            id: 'm-caleb-1',
            senderName: 'Caleb Stone',
            content: 'I set up the ambient lamp.',
            sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isFromMe: false,
          ),
          DirectMessage(
            id: 'm-sarah-2',
            senderName: 'Sarah Chen',
            content: 'Bringing Cascadia too!',
            sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
            isFromMe: false,
          ),
        ],
      );

      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: MaterialApp(home: BelongMessagesView(initialThreads: [groupThread])),
        ),
      );

      await $(const Key('thread-dm-group-1')).tap();
      await $.pumpAndSettle();

      expect($(const Key('dm_sender_label_m-caleb-1')), findsOneWidget);
      expect($(const Key('dm_sender_label_m-sarah-2')), findsOneWidget);
      expect($('Caleb Stone'), findsOneWidget);
      expect($('Sarah Chen'), findsOneWidget);
    });

    patrolWidgetTest(
      'BelongMembersDirectoryView in prod shows real directory and opens 1-tap DM',
      ($) async {
        useTallScreen($);
        final mailbox = InMemoryDirectMessageMailbox(
          seedUsers: {
            'uid-hannah': {
              'displayName': 'Hannah Morales',
              'email': 'hannah+art@example.com',
              'tagline': 'Botanical watercolor reflection',
              'listedInDirectory': true,
            },
          },
        );

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              appFlavorProvider.overrideWithValue(AppFlavor.prod),
              authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
              directMessageMailboxOverrideProvider.overrideWithValue(mailbox),
              directoryMembersProvider.overrideWith(
                (ref) => Stream.value(const [
                  DirectoryMember(
                    uid: 'uid-hannah',
                    displayName: 'Hannah Morales',
                    handle: 'art',
                    tagline: 'Botanical watercolor reflection',
                  ),
                ]),
              ),
            ],
            child: const MaterialApp(home: Scaffold(body: BelongMembersDirectoryView())),
          ),
        );

        // Real directory member is shown; sample dev members are hidden in prod
        expect($('Hannah Morales'), findsOneWidget);
        expect($('Marty (Organizer)'), findsNothing);

        // 1-tap Message button on member card opens Direct Messages with Hannah pre-selected
        await $(const Key('message_member_button_uid-hannah')).tap();
        await $.pumpAndSettle();

        expect($(const Key('selected_recipient_chip_Hannah Morales')), findsOneWidget);
      },
    );
  });
}
