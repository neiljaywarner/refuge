import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';

void main() {
  group('MessageThread & MemberProfile Domain Unit Tests', () {
    test('MemberProfile tagline and effectiveTagline work as expected', () {
      const p1 = MemberProfile(
        displayName: 'Hannah M.',
        email: 'hannah@example.com',
        bio: 'Autistic artist',
        comfortBadges: ['Artist'],
        isSignedIn: true,
        tagline: 'Sensory-friendly contemplative prayer & botanical art',
      );
      expect(
        p1.effectiveTagline,
        'Sensory-friendly contemplative prayer & botanical art',
      );

      const p2 = MemberProfile(
        displayName: 'Guest',
        email: '',
        bio: 'Just looking around',
        comfortBadges: [],
        isSignedIn: false,
      );
      expect(p2.effectiveTagline, 'Just looking around');
    });

    test('DevFellowshipMember provides tagline fallback', () {
      const m1 = DevFellowshipMember(
        name: 'Marty',
        role: 'Founder',
        tagline: 'Championing neurodiversity in faith communities',
        bio: 'Bio text',
        churchAffiliation: 'DFW Church',
        isIcocMember: true,
        comfortBadges: ['Founder'],
      );
      expect(
        m1.effectiveTagline,
        'Championing neurodiversity in faith communities',
      );

      const m2 = DevFellowshipMember(
        name: 'Alex',
        role: 'Facilitator',
        bio: 'Bio text',
        churchAffiliation: 'Boston',
        isIcocMember: true,
        comfortBadges: [],
      );
      expect(m2.effectiveTagline, 'Facilitator');
    });

    test('MessageThread formattedDate outputs relative and calendar dates', () {
      final base = DateTime(2026, 10, 22, 12, 0);

      final tJustNow = MessageThread(
        id: '1',
        participantName: 'Test',
        avatarInitials: 'T',
        previewSnippet: 'Hi',
        lastActivity: base.subtract(const Duration(seconds: 20)),
      );
      expect(tJustNow.formattedDate(base), 'Just now');

      final tMins = tJustNow.copyWith(
        lastActivity: base.subtract(const Duration(minutes: 15)),
      );
      expect(tMins.formattedDate(base), '15m ago');

      final tHours = tJustNow.copyWith(
        lastActivity: base.subtract(const Duration(hours: 2)),
      );
      expect(tHours.formattedDate(base), '2 hrs ago');

      final tDays = tJustNow.copyWith(
        lastActivity: base.subtract(const Duration(days: 3)),
      );
      expect(tDays.formattedDate(base), '3 days ago');

      final tOld = tJustNow.copyWith(
        lastActivity: DateTime(2026, 9, 7, 10, 0),
      );
      expect(tOld.formattedDate(base), 'Sep 7');
    });
  });

  group('BelongMessagesView Search & Compose BDD Widget Tests', () {
    Widget buildMessagesApp({List<MessageThread>? threads}) {
      return ProviderScope(
        child: MaterialApp(
          home: BelongMessagesView(initialThreads: threads),
        ),
      );
    }

    patrolWidgetTest(
      'Message threads render avatars, subjects, types, and timestamps',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildMessagesApp());
        await $.pumpAndSettle();

        // Verify conversations are displayed with subjects and types
        expect($('Marty & Community Team'), findsOneWidget);
        expect($('Sensory Game Night Group'), findsOneWidget);
        expect($('Silent Co-Presence Fellowship'), findsOneWidget);
        expect(
          $('Welcome to Belong Fellowship: Welcome to Belong on the Spectrum! Glad you are here with us.'),
          findsOneWidget,
        );
        expect(
          $('Wingspan & Cascadia Setup: Bringing Wingspan and Cascadia this Friday! Quiet room reserved.'),
          findsOneWidget,
        );
        expect(
          $('Tomorrow 2 PM Coworking: Tomorrow 2 PM: cameras optional, ambient lo-fi, zero masking.'),
          findsOneWidget,
        );

        // Verify message types
        expect($('Fellowship'), findsOneWidget);
        expect($('Group'), findsWidgets);
      },
    );

    patrolWidgetTest(
      'Real-time search filters conversations by sender, subject, or snippet',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildMessagesApp());
        await $.pumpAndSettle();

        // 1. Search by participant name
        await $(const Key('search_messages_input')).enterText('Marty');
        await $.pumpAndSettle();

        expect($('Marty & Community Team'), findsOneWidget);
        expect($('Sensory Game Night Group'), findsNothing);

        // 2. Search by subject
        await $(const Key('search_messages_input')).enterText('Wingspan');
        await $.pumpAndSettle();

        expect($('Sensory Game Night Group'), findsOneWidget);
        expect($('Marty & Community Team'), findsNothing);

        // 3. Clear search restores all threads
        await $(const Key('clear_search_messages_button')).tap();
        await $.pumpAndSettle();

        expect($('Marty & Community Team'), findsOneWidget);
        expect($('Sensory Game Night Group'), findsOneWidget);
        expect($('Silent Co-Presence Fellowship'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Tapping Add Msg icon opens modal with member autocomplete and profile taglines',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        await $.pumpWidget(buildMessagesApp());
        await $.pumpAndSettle();

        // Tap cute & clear Add Msg icon
        expect($(const Key('add_new_message_button')), findsOneWidget);
        await $(const Key('add_new_message_button')).tap();
        await $.pumpAndSettle();

        // Modal is open
        expect($('New Message'), findsOneWidget);
        expect($(const Key('recipient_search_input')), findsOneWidget);

        // Verify members are listed with their name as title and profile tagline as subtitle!
        expect($('Marty (Organizer)'), findsOneWidget);
        expect(
          $('Championing neurodiversity in faith communities'),
          findsOneWidget,
        );

        expect($('Caleb Stone'), findsOneWidget);
        expect(
          $('Soundscapes, calm lighting, and tech seams'),
          findsOneWidget,
        );

        expect($('Sarah Chen'), findsOneWidget);
        expect(
          $('Deep dive Greek word studies and chiasms'),
          findsOneWidget,
        );

        // 1. Select two members who are in the current fellowship directory.
        await $(const Key('member_picker_item_Caleb Stone')).tap();
        await $.pumpAndSettle();
        expect($(const Key('selected_recipient_chip_Caleb Stone')), findsOneWidget);

        await $(const Key('member_picker_item_Sarah Chen')).tap();
        await $.pumpAndSettle();
        expect($(const Key('selected_recipient_chip_Sarah Chen')), findsOneWidget);

        // 2. Fill in subject and content
        await $(const Key('new_message_subject_input')).enterText('Friday Fellowship');
        await $.pumpAndSettle();

        await $(const Key('new_message_content_input')).enterText(
          'Looking forward to quiet conversation this week!',
        );
        await $.pumpAndSettle();

        // 3. Send message
        await $(const Key('send_new_message_button')).tap();
        await $.pumpAndSettle();

        // 4. Modal closes and new conversation is active in thread detail
        expect($('Friday Fellowship'), findsOneWidget);
        expect(
          $('Looking forward to quiet conversation this week!'),
          findsOneWidget,
        );

        // 5. Test reply in thread
        await $(const Key('reply-message-field')).enterText('Will bring teas!');
        await $.pumpAndSettle();
        await $(const Key('send-reply-button')).tap();
        await $.pumpAndSettle();
        expect($('Will bring teas!'), findsOneWidget);

        // 6. Back button returns to thread list with new conversation at top
        await $(const Key('back-to-messages-list')).tap();
        await $.pumpAndSettle();

        expect($('Caleb Stone & 1 others'), findsOneWidget);
        expect(
          $('Friday Fellowship: Will bring teas!'),
          findsOneWidget,
        );
      },
    );
  });
}
