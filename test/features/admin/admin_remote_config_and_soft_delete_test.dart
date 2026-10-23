import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/soft_deleted_user.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

void main() {
  group('OrganizerRemoteConfig Admin Mode (#356)', () {
    test('defaults contain neilwarner@gmail.com as primary admin', () {
      final config =
          OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong());
      expect(config.adminEmailsCsv, 'neilwarner@gmail.com');
      expect(config.adminEmails, contains('neilwarner@gmail.com'));
      expect(config.isAdminEmail('neilwarner@gmail.com'), isTrue);
    });

    test('case-insensitive and trimmed email matching for admin access', () {
      final config =
          OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong());
      expect(config.isAdminEmail('NEILWARNER@GMAIL.COM'), isTrue);
      expect(config.isAdminEmail('  neilwarner@gmail.com  '), isTrue);
      expect(config.isAdminEmail('NeilWarner@Gmail.Com'), isTrue);
      expect(config.isAdminEmail('other@example.com'), isFalse);
      expect(config.isAdminEmail(''), isFalse);
      expect(config.isAdminEmail(null), isFalse);
    });

    test('supports custom CSV list of administrators', () {
      final config = OrganizerRemoteConfig.defaults(
        const CommunityBrandConfig.belong(),
      ).copyWith(
        adminEmailsCsv:
            'neilwarner@gmail.com, pastor.john@belong.church , deacon.sarah@gmail.com',
      );

      expect(config.adminEmails.length, 3);
      expect(config.isAdminEmail('neilwarner@gmail.com'), isTrue);
      expect(config.isAdminEmail('pastor.john@belong.church'), isTrue);
      expect(config.isAdminEmail('deacon.sarah@gmail.com'), isTrue);
      expect(config.isAdminEmail('unauthorized@test.com'), isFalse);
    });
  });

  group('AdminBanningRepository Soft-Delete (#356)', () {
    late InMemoryAdminBanningRepository repository;

    setUp(() {
      repository = InMemoryAdminBanningRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('moves user to soft-delete table with audit metadata', () async {
      expect(await repository.isUserBanned('Caleb Stone'), isFalse);

      await repository.banUser(
        userId: 'caleb-123',
        displayName: 'Caleb Stone',
        email: 'caleb@example.com',
        bannedByAdminEmail: 'neilwarner@gmail.com',
        reason: 'Testing remote soft-delete',
        additionalData: {'role': 'Audio Ministry'},
      );

      expect(await repository.isUserBanned('caleb-123'), isTrue);
      expect(await repository.isUserBanned('Caleb Stone'), isTrue);
      expect(await repository.isUserBanned('caleb stone'), isTrue);

      final streamValues = await repository.watchBannedUsers().first;
      expect(streamValues.length, 1);
      final banned = streamValues.first;
      expect(banned.displayName, 'Caleb Stone');
      expect(banned.bannedByAdminEmail, 'neilwarner@gmail.com');
      expect(banned.reason, 'Testing remote soft-delete');
      expect(banned.softDeleted, isTrue);
      expect(banned.originalData['role'], 'Audio Ministry');
    });

    test('unbanUser restores user back to active standing', () async {
      await repository.banUser(
        userId: 'sarah-456',
        displayName: 'Sarah Chen',
        bannedByAdminEmail: 'neilwarner@gmail.com',
      );
      expect(await repository.isUserBanned('sarah-456'), isTrue);

      await repository.unbanUser('sarah-456');
      expect(await repository.isUserBanned('sarah-456'), isFalse);
    });
  });

  group('SoftDeletedUser Domain Model Serialization (#356)', () {
    test('serializes to and from Map accurately', () {
      final now = DateTime.now();
      final model = SoftDeletedUser(
        userId: 'user-001',
        displayName: 'Test User',
        email: 'test@belong.org',
        bannedAt: now,
        bannedByAdminEmail: 'neilwarner@gmail.com',
        reason: 'Harassment',
        softDeleted: true,
        originalData: const {'church': 'DFW Church'},
      );

      final map = model.toMap();
      expect(map['userId'], 'user-001');
      expect(map['displayName'], 'Test User');
      expect(map['email'], 'test@belong.org');
      expect(map['bannedByAdminEmail'], 'neilwarner@gmail.com');
      expect(map['softDeleted'], isTrue);

      final restored = SoftDeletedUser.fromMap(map, id: 'user-001');
      expect(restored.userId, 'user-001');
      expect(restored.displayName, 'Test User');
      expect(restored.bannedByAdminEmail, 'neilwarner@gmail.com');
      expect(restored.reason, 'Harassment');
      expect(restored.originalData['church'], 'DFW Church');
    });
  });
}
