import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/soft_deleted_user.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

void main() {
  group('OrganizerRemoteConfig Admin Mode (#356)', () {
    test('defaults to empty string so missing Remote Config fails closed', () {
      final config = OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong());
      expect(config.adminEmailsCsv, '');
      expect(config.adminEmails, isEmpty);
      expect(config.isAdminEmail('organizer@belongonthespectrum.com'), isFalse);
    });

    test('case-insensitive and trimmed email matching for admin access', () {
      final config = OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong())
          .copyWith(adminEmailsCsv: 'organizer@belongonthespectrum.com');
      expect(config.isAdminEmail('ORGANIZER@BELONGONTHESPECTRUM.COM'), isTrue);
      expect(config.isAdminEmail('  organizer@belongonthespectrum.com  '), isTrue);
      expect(config.isAdminEmail('Organizer@BelongOnTheSpectrum.com'), isTrue);
      expect(config.isAdminEmail('other@example.com'), isFalse);
      expect(config.isAdminEmail(''), isFalse);
      expect(config.isAdminEmail(null), isFalse);
    });

    test('supports custom CSV list of administrators', () {
      final config = OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()).copyWith(
        adminEmailsCsv: 'organizer@belongonthespectrum.com, lead@belongonthespectrum.com , moderator@belongonthespectrum.com',
      );

      expect(config.adminEmails.length, 3);
      expect(config.isAdminEmail('organizer@belongonthespectrum.com'), isTrue);
      expect(config.isAdminEmail('lead@belongonthespectrum.com'), isTrue);
      expect(config.isAdminEmail('moderator@belongonthespectrum.com'), isTrue);
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
        bannedByAdminEmail: 'organizer@belongonthespectrum.com',
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
      expect(banned.bannedByAdminEmail, 'organizer@belongonthespectrum.com');
      expect(banned.reason, 'Testing remote soft-delete');
      expect(banned.softDeleted, isTrue);
      expect(banned.originalData['role'], 'Audio Ministry');
    });

    test('unbanUser restores user back to active standing across userId and displayName', () async {
      await repository.banUser(
        userId: 'sarah-456',
        displayName: 'Sarah Chen',
        bannedByAdminEmail: 'organizer@belongonthespectrum.com',
      );
      expect(await repository.isUserBanned('sarah-456'), isTrue);
      expect(await repository.isUserBanned('Sarah Chen'), isTrue);

      await repository.unbanUser('sarah-456');
      expect(await repository.isUserBanned('sarah-456'), isFalse);
      expect(await repository.isUserBanned('Sarah Chen'), isFalse);
      final streamValues = await repository.watchBannedUsers().first;
      expect(streamValues, isEmpty);
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
        bannedByAdminEmail: 'organizer@belongonthespectrum.com',
        reason: 'Harassment',
        softDeleted: true,
        originalData: const {'church': 'DFW Church'},
      );

      final map = model.toMap();
      expect(map['userId'], 'user-001');
      expect(map['displayName'], 'Test User');
      expect(map['email'], 'test@belong.org');
      expect(map['bannedByAdminEmail'], 'organizer@belongonthespectrum.com');
      expect(map['softDeleted'], isTrue);

      final restored = SoftDeletedUser.fromMap(map, id: 'user-001');
      expect(restored.userId, 'user-001');
      expect(restored.displayName, 'Test User');
      expect(restored.bannedByAdminEmail, 'organizer@belongonthespectrum.com');
      expect(restored.reason, 'Harassment');
      expect(restored.originalData['church'], 'DFW Church');
    });

    test('converts Firestore Timestamp to DateTime properly in fromMap', () {
      final now = DateTime.utc(2026, 10, 22, 12, 0);
      final timestamp = Timestamp.fromDate(now);
      final model = SoftDeletedUser.fromMap({
        'userId': 'user-ts',
        'displayName': 'Timestamp User',
        'bannedAt': timestamp,
        'bannedByAdminEmail': 'organizer@belongonthespectrum.com',
      });

      expect(model.bannedAt.isAtSameMomentAs(now), isTrue);
    });
  });
}
