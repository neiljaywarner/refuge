import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/domain/ban_standing.dart';
import 'package:refuge4serverpod/src/features/admin/domain/soft_deleted_user.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

void main() {
  final standing = SoftDeletedUser(
    userId: 'user-caleb',
    displayName: 'Caleb Stone',
    email: 'caleb@example.com',
    bannedAt: DateTime.utc(2026, 10, 24),
    bannedByAdminEmail: 'organizer@belongonthespectrum.com',
    softDeleted: true,
  );

  group('isIdentityBanned (#562)', () {
    test('matches user id, email, and display name', () {
      expect(
        isIdentityBanned(
          bans: [standing],
          userId: 'user-caleb',
          email: 'other@example.com',
          displayName: 'Someone Else',
        ),
        isTrue,
      );
      expect(
        isIdentityBanned(
          bans: [standing],
          userId: 'other',
          email: '  CALEB@example.com ',
          displayName: 'Someone Else',
        ),
        isTrue,
      );
      expect(
        isIdentityBanned(
          bans: [standing],
          userId: 'other',
          email: 'other@example.com',
          displayName: 'caleb stone',
        ),
        isTrue,
      );
    });

    test('does not match a different member', () {
      expect(
        isIdentityBanned(
          bans: [standing],
          userId: 'user-sarah',
          email: 'sarah@example.com',
          displayName: 'Sarah Chen',
        ),
        isFalse,
      );
    });

    test('softDeleted false is not banned', () {
      final restored = SoftDeletedUser(
        userId: standing.userId,
        displayName: standing.displayName,
        email: standing.email,
        bannedAt: standing.bannedAt,
        bannedByAdminEmail: standing.bannedByAdminEmail,
        softDeleted: false,
      );
      expect(
        isIdentityBanned(
          bans: [restored],
          userId: 'user-caleb',
          email: 'caleb@example.com',
          displayName: 'Caleb Stone',
        ),
        isFalse,
      );
    });
  });

  group('createContributionUnlessBanned (#562)', () {
    test('refuses a post when the member is paused', () async {
      var created = false;
      final allowed = await createContributionUnlessBanned(
        isBanned: true,
        create: () async {
          created = true;
        },
      );
      expect(allowed, isFalse);
      expect(created, isFalse);
    });

    test('creates a post when the member is active', () async {
      final posts = <Post>[];
      final allowed = await createContributionUnlessBanned(
        isBanned: false,
        create: () async {
          posts.add(
            Post(
              id: 'post-1',
              authorName: 'Caleb Stone',
              content: 'A quiet note',
              timestamp: DateTime.utc(2026, 10, 24),
              spaceKey: 'prayer',
              reactions: const {},
              toneTag: '[Prayer Request]',
            ),
          );
        },
      );
      expect(allowed, isTrue);
      expect(posts, hasLength(1));
    });
  });

  group('mergeAdminEmails (#562)', () {
    test('production ignores the dev admin define', () {
      expect(
        mergeAdminEmails(
          remoteCsv: '',
          devEmails: 'organizer@belongonthespectrum.com',
          isProduction: true,
        ),
        '',
      );
      expect(AppFlavor.prod.isProduction, isTrue);
      final config = OrganizerRemoteConfig.defaults(
        const CommunityBrandConfig.belong(),
      );
      expect(config.isAdminEmail('organizer@belongonthespectrum.com'), isFalse);
    });

    test('an empty dev define leaves the remote list unchanged', () {
      expect(
        mergeAdminEmails(
          remoteCsv: 'lead@belongonthespectrum.com',
          devEmails: '   ',
          isProduction: false,
        ),
        'lead@belongonthespectrum.com',
      );
    });

    test('dev flavor appends the define to the remote list', () {
      final merged = mergeAdminEmails(
        remoteCsv: 'lead@belongonthespectrum.com',
        devEmails: 'organizer@belongonthespectrum.com',
        isProduction: false,
      );
      final config = OrganizerRemoteConfig.defaults(
        const CommunityBrandConfig.belong(),
      ).copyWith(adminEmailsCsv: merged);
      expect(config.isAdminEmail('organizer@belongonthespectrum.com'), isTrue);
      expect(config.isAdminEmail('lead@belongonthespectrum.com'), isTrue);
      expect(AppFlavor.dev.isProduction, isFalse);
    });
  });
}
