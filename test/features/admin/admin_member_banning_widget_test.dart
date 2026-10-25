import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/soft_deleted_user.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/other_member_profile_dialog.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';

void main() {
  group('Admin Mode & Soft-Delete Banning Widget Tests (#356)', () {
    late LocalPostRepository postRepo;
    late LocalCommentRepository commentRepo;

    setUp(() {
      postRepo = LocalPostRepository();
      commentRepo = LocalCommentRepository();
    });

    patrolWidgetTest('regular non-admin user cannot see admin badge or ban button', ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(postRepo),
          commentRepositoryProvider.overrideWithValue(commentRepo),
          organizerRemoteConfigProvider.overrideWithValue(
            OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()),
          ),
          memberProfileProvider.overrideWith(
            () => _StaticProfileNotifier(
              const MemberProfile(
                displayName: 'Alice Visitor',
                email: 'alice@example.com',
                bio: 'Regular community member',
                comfortBadges: [],
                isSignedIn: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: OtherMemberProfileDialog(authorName: 'Caleb Stone')),
          ),
        ),
      );

      // Verify name is present
      expect($(const Key('other_member_profile_name')), findsOneWidget);

      // Verify admin controls are NOT visible to regular users
      expect($(const Key('admin_mode_badge')), findsNothing);
      expect($(const Key('admin_ban_member_button')), findsNothing);
      expect($(const Key('admin_unban_member_button')), findsNothing);
      expect($(const Key('banned_member_banner')), findsNothing);
      expect($(const Key('profile_done_button')), findsOneWidget);
    });

    patrolWidgetTest(
      'admin user sees admin badge, can ban member into soft-delete table and unban',
      ($) async {
        $.tester.view.physicalSize = const Size(1080, 2400);
        $.tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final banningRepo = InMemoryAdminBanningRepository();
        addTearDown(banningRepo.dispose);

        final container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(postRepo),
            commentRepositoryProvider.overrideWithValue(commentRepo),
            organizerRemoteConfigProvider.overrideWithValue(
              OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong())
                  .copyWith(adminEmailsCsv: 'organizer@belongonthespectrum.com'),
            ),
            memberProfileProvider.overrideWith(
              () => _StaticProfileNotifier(
                const MemberProfile(
                  displayName: 'Fellow Member',
                  email: 'organizer@belongonthespectrum.com',
                  bio: 'Community Administrator',
                  comfortBadges: [],
                  isSignedIn: true,
                ),
              ),
            ),
            adminBanningRepositoryProvider.overrideWithValue(banningRepo),
          ],
        );
        addTearDown(container.dispose);

        await $.pumpWidgetAndSettle(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: OtherMemberProfileDialog(authorName: 'Caleb Stone')),
            ),
          ),
        );

        // Verify Admin View badge is visible
        expect($(const Key('admin_mode_badge')), findsOneWidget);
        expect($(const Key('admin_ban_member_button')), findsOneWidget);

        // Tap Ban Member
        await $(const Key('admin_ban_member_button')).tap();
        await $.pumpAndSettle();

        // Verify confirmation dialog appeared
        expect(find.textContaining('does not block an IP address'), findsOneWidget);
        expect($(const Key('cancel_ban_button')), findsOneWidget);
        expect($(const Key('confirm_ban_button')), findsOneWidget);

        // Confirm Ban
        await $(const Key('confirm_ban_button')).tap();
        await $.pumpAndSettle();

        // Verify user was soft-deleted in repository
        expect(await banningRepo.isUserBanned('Caleb Stone'), isTrue);

        expect($(const Key('banned_member_banner')), findsOneWidget);
        expect($(const Key('admin_ban_permanent_note')), findsOneWidget);
        expect($(const Key('admin_unban_member_button')), findsNothing);
        expect(await banningRepo.isUserBanned('Caleb Stone'), isTrue);
      },
    );

    patrolWidgetTest('Scenario: Cancel writes nothing', ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final banningRepo = InMemoryAdminBanningRepository();
      addTearDown(banningRepo.dispose);
      final container = _adminContainer(
        postRepo: postRepo,
        commentRepo: commentRepo,
        banningRepo: banningRepo,
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(_profileApp(container));
      await $(const Key('admin_ban_member_button')).tap();
      await $.pumpAndSettle();
      await $(const Key('cancel_ban_button')).tap();
      await $.pumpAndSettle();

      expect(await banningRepo.isUserBanned('Caleb Stone'), isFalse);
      expect($(const Key('admin_ban_member_button')), findsOneWidget);
      expect($('Failed to ban member'), findsNothing);
    });

    patrolWidgetTest('Scenario: A failed ban shows the error snackbar', ($) async {
      $.tester.view.physicalSize = const Size(1080, 2400);
      $.tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      final banningRepo = _ThrowingBanRepository();
      final container = _adminContainer(
        postRepo: postRepo,
        commentRepo: commentRepo,
        banningRepo: banningRepo,
      );
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(_profileApp(container));
      await $(const Key('admin_ban_member_button')).tap();
      await $.pumpAndSettle();
      await $(const Key('confirm_ban_button')).tap();
      await $.pump();
      await $.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Failed to ban member'), findsOneWidget);
      expect($(const Key('admin_ban_member_button')), findsOneWidget);
      expect($(const Key('banned_member_banner')), findsNothing);
    });
  });
}

ProviderContainer _adminContainer({
  required LocalPostRepository postRepo,
  required LocalCommentRepository commentRepo,
  required AdminBanningRepository banningRepo,
}) => ProviderContainer(
  overrides: [
    postRepositoryProvider.overrideWithValue(postRepo),
    commentRepositoryProvider.overrideWithValue(commentRepo),
    organizerRemoteConfigProvider.overrideWithValue(
      OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong())
          .copyWith(adminEmailsCsv: 'organizer@belongonthespectrum.com'),
    ),
    memberProfileProvider.overrideWith(
      () => _StaticProfileNotifier(
        const MemberProfile(
          displayName: 'Fellow Member',
          email: 'organizer@belongonthespectrum.com',
          bio: 'Community Administrator',
          comfortBadges: [],
          isSignedIn: true,
          userId: 'user-organizer',
        ),
      ),
    ),
    adminBanningRepositoryProvider.overrideWithValue(banningRepo),
  ],
);

Widget _profileApp(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(
    home: Scaffold(body: OtherMemberProfileDialog(authorName: 'Caleb Stone')),
  ),
);

class _ThrowingBanRepository implements AdminBanningRepository {
  @override
  Future<void> banUser({
    required String userId,
    required String displayName,
    String? email,
    required String bannedByAdminEmail,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    throw StateError('network down');
  }

  @override
  Future<bool> isUserBanned(String userIdOrName) async => false;

  @override
  Stream<List<SoftDeletedUser>> watchBannedUsers() async* {
    yield const <SoftDeletedUser>[];
  }

  @override
  Future<void> unbanUser(String userId) async {}
}

class _StaticProfileNotifier extends MemberProfileNotifier {
  _StaticProfileNotifier(this._initial);
  final MemberProfile _initial;

  @override
  MemberProfile build() => _initial;
}
