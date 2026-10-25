import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/ban_standing.dart';
import 'package:refuge4serverpod/src/features/admin/presentation/account_paused_banner.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

void main() {
  patrolWidgetTest('Scenario: Ban hides the directory card and pauses posting', ($) async {
    $.tester.view.physicalSize = const Size(1080, 2400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    final banningRepo = InMemoryAdminBanningRepository();
    final postRepo = LocalPostRepository(isDevMode: false);
    final commentRepo = LocalCommentRepository();
    addTearDown(banningRepo.dispose);

    await postRepo.createPost(
      Post(
        id: 'post-caleb',
        authorName: 'Caleb Stone',
        content: 'A note that should be removed',
        timestamp: DateTime.utc(2026, 10, 24),
        spaceKey: 'prayer',
        reactions: const {},
        toneTag: '[Prayer Request]',
      ),
    );

    final admin = _container(
      banningRepo: banningRepo,
      postRepo: postRepo,
      commentRepo: commentRepo,
      profile: const MemberProfile(
        displayName: 'Fellow Member',
        email: 'organizer@belongonthespectrum.com',
        bio: 'Community Administrator',
        comfortBadges: [],
        isSignedIn: true,
        userId: 'user-organizer',
      ),
    );
    addTearDown(admin.dispose);

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: admin,
        child: const MaterialApp(home: Scaffold(body: BelongMembersDirectoryView())),
      ),
    );

    await $(const Key('dev_member_card_caleb_stone')).scrollTo();
    await $(const Key('dev_member_card_caleb_stone')).tap();
    await $.pumpAndSettle();
    await $(const Key('admin_ban_member_button')).tap();
    await $.pumpAndSettle();
    await $(const Key('confirm_ban_button')).tap();
    await $.pumpAndSettle();
    await $(const Key('profile_done_button')).tap();
    await $.pumpAndSettle();

    expect($(const Key('dev_member_card_caleb_stone')), findsNothing);

    final caleb = _container(
      banningRepo: banningRepo,
      postRepo: postRepo,
      commentRepo: commentRepo,
      profile: const MemberProfile(
        displayName: 'Caleb Stone',
        email: 'caleb@example.com',
        bio: 'Audio ministry',
        comfortBadges: [],
        isSignedIn: true,
        userId: 'user-caleb',
      ),
    );
    addTearDown(caleb.dispose);

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: caleb,
        child: const MaterialApp(home: Scaffold(body: _PausedPostHost())),
      ),
    );

    expect($(const Key('account_paused_lockout')), findsOneWidget);
    expect($("This account can't sign in."), findsOneWidget);
    expect($('A quiet note from the feed'), findsNothing);
    expect(await postRepo.getPosts(spaceKey: 'prayer'), isEmpty);

    await $(const Key('try_post_button')).tap();
    await $.pumpAndSettle();
    expect(await postRepo.getPosts(spaceKey: 'prayer'), isEmpty);
  });

  patrolWidgetTest('Scenario: A ban is not undone from the app', ($) async {
    $.tester.view.physicalSize = const Size(1080, 2400);
    $.tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    final banningRepo = InMemoryAdminBanningRepository();
    final postRepo = LocalPostRepository(isDevMode: false);
    final commentRepo = LocalCommentRepository();
    addTearDown(banningRepo.dispose);
    await banningRepo.banUser(
      userId: 'user-caleb',
      displayName: 'Caleb Stone',
      email: 'caleb@example.com',
      bannedByAdminEmail: 'organizer@belongonthespectrum.com',
    );
    final admin = _container(
      banningRepo: banningRepo,
      postRepo: postRepo,
      commentRepo: commentRepo,
      profile: const MemberProfile(
        displayName: 'Fellow Member',
        email: 'organizer@belongonthespectrum.com',
        bio: 'Community Administrator',
        comfortBadges: [],
        isSignedIn: true,
        userId: 'user-organizer',
      ),
    );
    addTearDown(admin.dispose);

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: admin,
        child: const MaterialApp(home: Scaffold(body: BelongMembersDirectoryView())),
      ),
    );
    expect($(const Key('dev_member_card_caleb_stone')), findsNothing);

    final caleb = _container(
      banningRepo: banningRepo,
      postRepo: postRepo,
      commentRepo: commentRepo,
      profile: const MemberProfile(
        displayName: 'Caleb Stone',
        email: 'caleb@example.com',
        bio: 'Audio ministry',
        comfortBadges: [],
        isSignedIn: true,
        userId: 'user-caleb',
      ),
    );
    addTearDown(caleb.dispose);

    await $.pumpWidgetAndSettle(
      UncontrolledProviderScope(
        container: caleb,
        child: const MaterialApp(home: Scaffold(body: _PausedPostHost())),
      ),
    );
    expect($(const Key('account_paused_lockout')), findsOneWidget);
    expect($('A quiet note from the feed'), findsNothing);
    await $(const Key('try_post_button')).tap();
    await $.pumpAndSettle();
    expect(await postRepo.getPosts(spaceKey: 'prayer'), isEmpty);
  });
}

ProviderContainer _container({
  required InMemoryAdminBanningRepository banningRepo,
  required LocalPostRepository postRepo,
  required LocalCommentRepository commentRepo,
  required MemberProfile profile,
}) => ProviderContainer(
  overrides: [
    postRepositoryProvider.overrideWithValue(postRepo),
    commentRepositoryProvider.overrideWithValue(commentRepo),
    organizerRemoteConfigProvider.overrideWithValue(
      OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong())
          .copyWith(adminEmailsCsv: 'organizer@belongonthespectrum.com'),
    ),
    memberProfileProvider.overrideWith(() => _StaticProfileNotifier(profile)),
    adminBanningRepositoryProvider.overrideWithValue(banningRepo),
  ],
);

class _PausedPostHost extends ConsumerWidget {
  const _PausedPostHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(isCurrentMemberBannedProvider);
    return Column(
      children: [
        if (paused) const AccountPausedLockout() else const Text('A quiet note from the feed'),
        TextButton(
          key: const Key('try_post_button'),
          onPressed: () async {
            await createContributionUnlessBanned(
              isBanned: ref.read(isCurrentMemberBannedProvider),
              create: () async {
                await ref
                    .read(postRepositoryProvider)
                    .createPost(
                      Post(
                        id: 'post-caleb',
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
          },
          child: const Text('Try post'),
        ),
      ],
    );
  }
}

class _StaticProfileNotifier extends MemberProfileNotifier {
  _StaticProfileNotifier(this._initial);
  final MemberProfile _initial;

  @override
  MemberProfile build() => _initial;
}
