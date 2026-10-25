import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/presentation/account_paused_banner.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/other_member_profile_dialog.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'Scenario: Ban hides the directory card and pauses posting',
    ($) async {
      final banningRepo = InMemoryAdminBanningRepository();
      addTearDown(banningRepo.dispose);
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            LocalPostRepository(isDevMode: false),
          ),
          commentRepositoryProvider.overrideWithValue(LocalCommentRepository()),
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
      addTearDown(container.dispose);

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: OtherMemberProfileDialog(authorName: 'Caleb Stone'),
            ),
          ),
        ),
      );

      await $(const Key('admin_ban_member_button')).tap();
      await $.pumpAndSettle();
      await $(const Key('confirm_ban_button')).tap();
      await $.pumpAndSettle();
      expect($(const Key('banned_member_banner')), findsOneWidget);
      expect(await banningRepo.isUserBanned('Caleb Stone'), isTrue);

      await $(const Key('admin_unban_member_button')).tap();
      await $.pumpAndSettle();
      expect(await banningRepo.isUserBanned('Caleb Stone'), isFalse);
      expect($(const Key('banned_member_banner')), findsNothing);
    },
  );

  patrolWidgetTest('Scenario: Restore brings the card back and posting works', (
    $,
  ) async {
    final banningRepo = InMemoryAdminBanningRepository();
    addTearDown(banningRepo.dispose);
    await banningRepo.banUser(
      userId: 'caleb-123',
      displayName: 'Caleb Stone',
      email: 'caleb@example.com',
      bannedByAdminEmail: 'organizer@belongonthespectrum.com',
    );
    final container = ProviderContainer(
      overrides: [
        adminBanningRepositoryProvider.overrideWithValue(banningRepo),
        memberProfileProvider.overrideWith(
          () => _StaticProfileNotifier(
            const MemberProfile(
              displayName: 'Caleb Stone',
              email: 'caleb@example.com',
              bio: 'Audio ministry',
              comfortBadges: [],
              isSignedIn: true,
              userId: 'caleb-123',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: _PauseProbe())),
      ),
    );
    expect($(const Key('account_paused_lockout')), findsOneWidget);
    expect($('A quiet note from the feed'), findsNothing);

    await banningRepo.unbanUser('caleb-123');
    await $.pumpAndSettle();
    expect($(const Key('account_paused_lockout')), findsNothing);
    expect($('A quiet note from the feed'), findsOneWidget);
  });
}

class _PauseProbe extends ConsumerWidget {
  const _PauseProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(isCurrentMemberBannedProvider);
    if (!paused) return const Text('A quiet note from the feed');
    return const AccountPausedLockout();
  }
}

class _StaticProfileNotifier extends MemberProfileNotifier {
  _StaticProfileNotifier(this._initial);
  final MemberProfile _initial;

  @override
  MemberProfile build() => _initial;
}
