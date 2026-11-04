import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/profile/data/member_directory_store.dart';

void main() {
  group('isMemberEligibleForDirectory (#813)', () {
    test('permits active member with explicit listedInDirectory == true', () {
      final eligible = isMemberEligibleForDirectory(
        uid: 'user_active_1',
        userData: {
          'displayName': 'Sarah Joy',
          'email': 'sarah@example.com',
          'listedInDirectory': true,
        },
      );
      expect(eligible, isTrue);
    });

    test('excludes member when listedInDirectory is explicitly false', () {
      final eligible = isMemberEligibleForDirectory(
        uid: 'user_hidden_1',
        userData: {
          'displayName': 'Private Member',
          'email': 'private@example.com',
          'listedInDirectory': false,
        },
      );
      expect(eligible, isFalse);
    });

    test('permits member when listedInDirectory is true or absent without exclusion', () {
      final explicitTrue = isMemberEligibleForDirectory(
        uid: 'user_opted_in',
        userData: {
          'displayName': 'Opted In',
          'email': 'opted@example.com',
          'listedInDirectory': true,
        },
      );
      expect(explicitTrue, isTrue);

      final absentDefault = isMemberEligibleForDirectory(
        uid: 'user_default',
        userData: {
          'displayName': 'Default Member',
          'email': 'default@example.com',
        },
      );
      expect(absentDefault, isTrue);
    });

    test('excludes member when uid is in excludedUids set (banned or soft/self deleted)', () {
      final eligible = isMemberEligibleForDirectory(
        uid: 'user_banned_42',
        userData: {
          'displayName': 'Violating User',
          'email': 'banned@example.com',
          'listedInDirectory': true,
        },
        excludedUids: {'user_banned_42', 'other_banned'},
      );
      expect(eligible, isFalse);
    });

    test('excludes member when banned or softDeleted flags are true in userData', () {
      final bannedFlag = isMemberEligibleForDirectory(
        uid: 'user_flagged_banned',
        userData: {
          'displayName': 'Flagged User',
          'listedInDirectory': true,
          'banned': true,
        },
      );
      expect(bannedFlag, isFalse);

      final softDeletedFlag = isMemberEligibleForDirectory(
        uid: 'user_flagged_deleted',
        userData: {
          'displayName': 'Deleted User',
          'listedInDirectory': true,
          'softDeleted': true,
        },
      );
      expect(softDeletedFlag, isFalse);
    });

    test('excludes member when uid matches currentUserId (cannot message oneself)', () {
      final eligible = isMemberEligibleForDirectory(
        uid: 'user_me',
        userData: {
          'displayName': 'Self',
          'listedInDirectory': true,
        },
        currentUserId: 'user_me',
      );
      expect(eligible, isFalse);
    });

    test('excludes empty uid', () {
      final eligible = isMemberEligibleForDirectory(
        uid: '',
        userData: {
          'displayName': 'Empty UID',
          'listedInDirectory': true,
        },
      );
      expect(eligible, isFalse);
    });
  });

  group('InMemoryDirectMessageMailbox.loadDirectory (#813)', () {
    test('strictly filters unlisted, missing, banned, and self members', () async {
      final mailbox = InMemoryDirectMessageMailbox(
        seedUsers: {
          'user_1': {
            'displayName': 'Alice Smith',
            'email': 'alice+tag@example.com',
            'listedInDirectory': true,
          },
          'user_2_unlisted': {
            'displayName': 'Bob Hidden',
            'email': 'bob@example.com',
            'listedInDirectory': false,
          },
          'user_3_hidden': {
            'displayName': 'Charlie Hidden',
            'email': 'charlie@example.com',
            'listedInDirectory': false,
          },
          'user_4_banned': {
            'displayName': 'David BadActor',
            'email': 'david@example.com',
            'listedInDirectory': true,
          },
          'user_5': {
            'displayName': 'Zoe Fellowship',
            'email': 'zoe@example.com',
            'listedInDirectory': true,
          },
        },
        excludedUids: {'user_4_banned'},
      );

      final recipients = await mailbox.loadDirectory(
        includeSamples: false,
        isProduction: true,
      );

      final recipientNames = recipients.map((r) => r.name).toList();
      expect(recipientNames, contains('Alice Smith'));
      expect(recipientNames, contains('Zoe Fellowship'));
      expect(recipientNames, isNot(contains('Bob Hidden')));
      expect(recipientNames, isNot(contains('Charlie Hidden')));
      expect(recipientNames, isNot(contains('David BadActor')));
      expect(recipients, hasLength(2));
    });

    test('banUser dynamically removes recipient on subsequent loads', () async {
      final mailbox = InMemoryDirectMessageMailbox(
        seedUsers: {
          'user_grace': {
            'displayName': 'Grace Member',
            'email': 'grace@example.com',
            'listedInDirectory': true,
          },
        },
      );

      final initial = await mailbox.loadDirectory(
        includeSamples: false,
        isProduction: true,
      );
      expect(initial, hasLength(1));
      expect(initial.first.id, 'user_grace');

      // Admin executes ban
      mailbox.banUser('user_grace');

      final afterBan = await mailbox.loadDirectory(
        includeSamples: false,
        isProduction: true,
      );
      expect(afterBan, isEmpty);
    });
  });
}
