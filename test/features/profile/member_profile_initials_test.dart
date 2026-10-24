import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

MemberProfile _createProfile(String name) => MemberProfile(
      displayName: name,
      email: 'member@belongonthespectrum.com',
      bio: 'Fellowship member',
      comfortBadges: const [],
      isSignedIn: true,
    );

void main() {
  group('MemberProfile.initials Dart 3 Switch Expression', () {
    test('extracts single initial for single-word name', () {
      final profile = _createProfile('Neil');
      expect(profile.initials, 'N');
    });

    test('extracts first and last initials for two-word name', () {
      final profile = _createProfile('Neil Warner');
      expect(profile.initials, 'NW');
    });

    test('extracts first and last initials for multi-word name (e.g. Dr. Grace Hopper)', () {
      final profile = _createProfile('Dr. Grace Hopper');
      expect(profile.initials, 'GH');
    });

    test('strips parenthetical role/location suffix before initials', () {
      final profile = _createProfile('David M. (Colorado)');
      expect(profile.initials, 'DM');
    });

    test('extracts uppercase initials when input is lowercase', () {
      final profile = _createProfile('caleb stone');
      expect(profile.initials, 'CS');
    });

    test('falls back to "B" (Belong community member monogram) when name is empty', () {
      final profile = _createProfile('');
      expect(profile.initials, 'B');
    });

    test('falls back to "B" when name contains only whitespace', () {
      final profile = _createProfile('    ');
      expect(profile.initials, 'B');
    });

    test('handles multiple consecutive whitespace characters cleanly', () {
      final profile = _createProfile('  Marty     Organizer  ');
      expect(profile.initials, 'MO');
    });
  });

  group('ReflectionCard.getInitials monogram parsing', () {
    test('extracts clean initials from author with country/region parenthetical', () {
      expect(ReflectionCard.getInitials('David M. (UK)'), 'DM');
    });

    test('extracts clean initials from author with role parenthetical', () {
      expect(ReflectionCard.getInitials('Marty (Organizer)'), 'MO');
    });

    test('extracts single initial for single name', () {
      expect(ReflectionCard.getInitials('Grace'), 'G');
    });

    test('falls back to "B" for empty or whitespace author name', () {
      expect(ReflectionCard.getInitials(''), 'B');
      expect(ReflectionCard.getInitials('   '), 'B');
    });
  });

  group('DevFellowshipMember.initials Dart 3 Switch Expression', () {
    test('extracts initials for curated fellowship member', () {
      const member = DevFellowshipMember(
        name: 'Marty (Organizer)',
        role: 'Community Organizer',
        bio: 'Community bio',
        churchAffiliation: 'DFW Church',
        isIcocMember: true,
        comfortBadges: [],
      );
      expect(member.initials, 'M');
    });

    test('extracts single initial for single name', () {
      const member = DevFellowshipMember(
        name: 'Grace',
        role: 'Member',
        bio: 'Member bio',
        churchAffiliation: 'Boston Church',
        isIcocMember: true,
        comfortBadges: [],
      );
      expect(member.initials, 'G');
    });

    test('falls back to "B" when name is empty', () {
      const member = DevFellowshipMember(
        name: '',
        role: 'Member',
        bio: 'Member bio',
        churchAffiliation: 'None',
        isIcocMember: false,
        comfortBadges: [],
      );
      expect(member.initials, 'B');
    });
  });

  group('BelongNotification.displayMessage Dart 3 Switch Expression', () {
    test('generates mention message', () {
      final notification = BelongNotification(
        id: 'notif-1',
        type: BelongNotificationType.mention,
        authorName: 'Marty',
        postTitle: 'Markan Chiasms',
        timestamp: DateTime(2026, 10, 22),
      );
      expect(
        notification.displayMessage,
        'Marty mentioned you in a comment on "Markan Chiasms"',
      );
    });

    test('generates reply message', () {
      final notification = BelongNotification(
        id: 'notif-2',
        type: BelongNotificationType.reply,
        authorName: 'Caleb',
        postTitle: 'Quiet Rooms',
        timestamp: DateTime(2026, 10, 22),
      );
      expect(
        notification.displayMessage,
        'Caleb replied to your comment on "Quiet Rooms"',
      );
    });

    test('generates like message', () {
      final notification = BelongNotification(
        id: 'notif-3',
        type: BelongNotificationType.like,
        authorName: 'Sarah',
        postTitle: 'Sensory Safety',
        timestamp: DateTime(2026, 10, 22),
      );
      expect(
        notification.displayMessage,
        'Sarah liked your reflection on "Sensory Safety"',
      );
    });

    test('generates following space message', () {
      final notification = BelongNotification(
        id: 'notif-4',
        type: BelongNotificationType.following,
        authorName: 'David',
        postTitle: 'Fellowship Hall',
        timestamp: DateTime(2026, 10, 22),
      );
      expect(
        notification.displayMessage,
        'David posted a new reflection in "Fellowship Hall"',
      );
    });
  });
}
