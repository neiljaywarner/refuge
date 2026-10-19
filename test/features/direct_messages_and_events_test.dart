import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/events/domain/sensory_event.dart';
import 'package:refuge4serverpod/src/features/events/presentation/actually_autistic_events_view.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';

void main() {
  group('Pragmatic Unit TDD: DirectMessage & MessageThread', () {
    test('sampleThreads provides welcoming initial community threads', () {
      final threads = MessageThread.sampleThreads();
      expect(threads.length, 3);
      expect(threads.first.participantName, 'Marty & Community Team');
      expect(threads.first.unreadCount, 1);
      expect(threads.first.messages.isNotEmpty, isTrue);
    });

    test('MessageThread copyWith preserves unmodified fields and updates new ones', () {
      final thread = MessageThread.sampleThreads().first;
      final updated = thread.copyWith(unreadCount: 0, previewSnippet: 'Updated preview');
      expect(updated.unreadCount, 0);
      expect(updated.previewSnippet, 'Updated preview');
      expect(updated.id, thread.id);
      expect(updated.participantName, thread.participantName);
    });
  });

  group('Pragmatic Unit TDD: SensoryEvent', () {
    test('sampleEvents provides detailed sensory indicators', () {
      final events = SensoryEvent.sampleEvents();
      expect(events.length, 3);
      final boardGames = events.firstWhere((e) => e.id == 'event-board-games');
      expect(boardGames.quietRoomAvailable, isTrue);
      expect(boardGames.lightingLevel, contains('Soft warm lamps'));
      expect(boardGames.soundLevel, contains('Low ambient'));
      expect(boardGames.userRsvpd, isFalse);
    });

    test('SensoryEvent copyWith updates RSVP and count cleanly', () {
      final event = SensoryEvent.sampleEvents().first;
      final rsvpd = event.copyWith(userRsvpd: true, rsvpCount: event.rsvpCount + 1);
      expect(rsvpd.userRsvpd, isTrue);
      expect(rsvpd.rsvpCount, event.rsvpCount + 1);
    });
  });

  patrolWidgetTest(
    'BDD (patrol_finders): Direct Messages thread list, calm digest toggle, and sending a reply',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: Scaffold(
            body: BelongMessagesView(),
          ),
        ),
      );

      // 1. Verify thread list & Calm Batched Digest toggle
      expect($('Direct Messages'), findsOneWidget);
      expect($('Calm Batched Digest is Active (quiet daily summary)'), findsOneWidget);
      expect($(Switch), findsOneWidget);

      // 2. Toggle Calm Batched Digest
      await $(Switch).tap();
      expect($('Calm Batched Digest is Disabled (realtime alerts)'), findsOneWidget);

      // 3. Tap on a conversation thread
      await $(const Key('thread-thread-welcome')).tap();
      expect($('Marty & Community Team'), findsOneWidget);
      expect($(find.textContaining('Welcome to Belong!')), findsWidgets);

      // 4. Send a reply
      await $(const Key('reply-message-field')).enterText('Hello Marty, thank you for welcoming me!');
      await $(const Key('send-reply-button')).tap();
      expect($('Hello Marty, thank you for welcoming me!'), findsOneWidget);

      // 5. Navigate back to thread list
      await $(const Key('back-to-messages-list')).tap();
      expect($('Direct Messages'), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'BDD (patrol_finders): Calm Notifications view delivers unhurried updates without stress',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: CalmNotificationsView(),
        ),
      );

      expect($('Calm Notifications'), findsOneWidget);
      expect($('All notifications are delivered gently without intrusive sound alerts or badges.'), findsOneWidget);
      expect($('Sensory Game Night This Friday'), findsOneWidget);
      expect($('New Reflection in Welcome Space'), findsOneWidget);
      expect($('Calm Daily Digest Ready'), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'BDD (patrol_finders): Actually Autistic Events calendar displays sensory badges and 1-tap RSVP',
    ($) async {
      await $.pumpWidgetAndSettle(
        const MaterialApp(
          home: ActuallyAutisticEventsView(),
        ),
      );

      // 1. Verify header and sensory commitment banner
      expect($('Actually Autistic Events'), findsOneWidget);
      expect($('Sensory-Friendly & Masking-Free'), findsOneWidget);

      // 2. Verify event cards and sensory badges
      expect($('Actually Autistic Weekly Online Fellowship'), findsOneWidget);
      expect($('Quiet Room Available'), findsWidgets);

      // 3. Tap 1-tap RSVP button on first visible event
      final rsvpKey = const Key('rsvp-button-event-weekly-online');
      expect($('14 members attending'), findsOneWidget);
      await $(rsvpKey).tap();

      // 4. Verify RSVP confirmed state
      expect($('✅ RSVP Confirmed'), findsWidgets);
      expect($('Attending (Quiet RSVP)'), findsWidgets);
      expect($('15 members attending'), findsOneWidget);

      // 5. Tap again to cancel RSVP
      await $(rsvpKey).tap();
      expect($('14 members attending'), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'BDD (patrol_finders): Full App navigation switches into Msgs tab smoothly',
    ($) async {
      await $.pumpWidgetAndSettle(
        SanctuaryApp(repository: LocalPostRepository()),
      );

      // Tap bottom tab Msgs via unselected icon
      await $(Icons.chat_bubble_outline_rounded).tap();
      expect($('Direct Messages'), findsOneWidget);
      expect($('Calm Batched Digest is Active (quiet daily summary)'), findsOneWidget);
    },
  );
}
