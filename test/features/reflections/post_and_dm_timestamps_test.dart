import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

/// Calendar day far enough in the past that [formatRelativeDate] stays "Oct 20"
/// instead of a relative label that drifts with the test clock.
final DateTime _knownSentAt = DateTime(2020, 10, 20, 15, 30);

void main() {
  patrolWidgetTest(
    'A post created on 20 Oct shows Oct 20 beside the author, not inside the post',
    ($) async {
      const body = 'The quiet room is reserved for anyone who needs a break.';
      final post = Post(
        id: 'post-timestamp',
        authorName: 'David M.',
        spaceKey: 'prayer',
        toneTag: 'Gentle',
        content: body,
        timestamp: _knownSentAt,
        reactions: const {},
      );

      // Given a post by David M. created on 20 Oct
      // And the post body does not contain that date
      expect(body.contains('Oct 20'), isFalse);
      expect(post.formattedDate(DateTime(2026, 10, 23, 12)), 'Oct 20');

      // When the post card is shown
      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ReflectionCard(
                post: post,
                isContrast: false,
                onAddReaction: (_) {},
              ),
            ),
          ),
        ),
      );

      // Then the card shows "Oct 20" beside the author, not inside the post body
      expect($('David M.'), findsOneWidget);
      expect($(body), findsOneWidget);
      expect($('Oct 20'), findsOneWidget);
      expect($(const Key('post_timestamp_post-timestamp')), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'A direct message sent on 20 Oct shows Oct 20 beside the message, not inside the text',
    ($) async {
      const body = 'Glad you are here. No need to reply until you are ready.';
      final message = DirectMessage(
        id: 'dm-1',
        senderName: 'Fellow Member',
        isFromMe: false,
        content: body,
        sentAt: _knownSentAt,
      );
      final thread = MessageThread(
        id: 'dm-timestamp',
        participantName: 'Fellow Member',
        avatarInitials: 'FM',
        previewSnippet: body,
        lastActivity: DateTime.now(),
        messages: [message],
      );

      // Given a direct message from Fellow Member sent on 20 Oct
      // And the message text does not contain that date
      expect(body.contains('Oct 20'), isFalse);
      expect(message.formattedDate(DateTime(2026, 10, 23, 12)), 'Oct 20');

      // When the conversation is opened
      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: BelongMessagesView(initialThreads: [thread]),
          ),
        ),
      );
      await $(const Key('thread-dm-timestamp')).tap();

      // Then "Oct 20" appears beside the message, not inside the message text
      expect($('Fellow Member'), findsWidgets);
      expect($(body), findsOneWidget);
      expect($('Oct 20'), findsOneWidget);
      expect($(const Key('direct_message_timestamp_dm-1')), findsOneWidget);
    },
  );
}
