import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/admin/data/admin_banning_repository.dart';
import 'package:refuge4serverpod/src/features/admin/domain/circle_ban.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/messages/data/direct_message_mailbox.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/belong_members_directory_view.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

/// Firestore that refuses every read and write, the way a rules denial does.
class _EraseDeniedFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'erase denied',
    );
  }
}

class _NoopMirror implements ReflectionMirror {
  @override
  Future<void> upsertPost(Post post) async {}

  @override
  Future<void> incrementReaction({required String postId, required String column}) async {}

  @override
  Future<List<Post>> listPosts({required String spaceKey}) async => const [];

  @override
  Stream<Post> watchPosts({required String spaceKey}) => const Stream.empty();

  @override
  Future<void> upsertDigest({
    required String spaceKey,
    required String summary,
    required int reflectionCount,
    required int affirmationCount,
  }) async {}
}

void main() {
  test('a reflection erase failure is rethrown', () async {
    final repo = AppwritePostRepository(
      isDevMode: true,
      customFirestore: _EraseDeniedFirestore(),
      mirror: _NoopMirror(),
      fallback: LocalPostRepository(isDevMode: false),
    );

    expect(() => repo.deleteByAuthor(authorName: 'Caleb Stone'), throwsA(isA<FirebaseException>()));
  });

  test('a comment erase failure is rethrown', () async {
    final repo = LocalCommentRepository(isDevMode: false, customFirestore: _EraseDeniedFirestore());

    expect(() => repo.deleteByAuthor(authorName: 'Caleb Stone'), throwsA(isA<FirebaseException>()));
  });

  test('a direct-message erase failure is rethrown', () async {
    final mailbox = FirestoreDirectMessageMailbox(firestore: _EraseDeniedFirestore());

    expect(
      () => mailbox.deleteBySender(senderId: 'caleb-123', senderName: 'Caleb Stone'),
      throwsA(isA<FirebaseException>()),
    );
  });

  test('applyCircleBan keeps the ban and surfaces the erase failure', () async {
    final bans = InMemoryAdminBanningRepository();
    addTearDown(bans.dispose);
    final posts = AppwritePostRepository(
      isDevMode: true,
      customFirestore: _EraseDeniedFirestore(),
      mirror: _NoopMirror(),
      fallback: LocalPostRepository(isDevMode: false),
    );

    await expectLater(
      applyCircleBan(
        bans: bans,
        posts: posts,
        comments: LocalCommentRepository(isDevMode: false),
        mailbox: InMemoryDirectMessageMailbox(),
        userId: 'Caleb Stone',
        displayName: 'Caleb Stone',
        email: 'qa-ban-member-591@example.com',
        bannedByAdminEmail: 'qa-ban-admin-591@example.com',
      ),
      throwsA(isA<FirebaseException>()),
    );
    expect(await bans.isUserBanned('Caleb Stone'), isTrue);
  });

  testWidgets('Confirm Ban shows the erase failure instead of a success note', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bans = InMemoryAdminBanningRepository();
    addTearDown(bans.dispose);
    final posts = AppwritePostRepository(
      isDevMode: false,
      customFirestore: _EraseDeniedFirestore(),
      mirror: _NoopMirror(),
      fallback: LocalPostRepository(isDevMode: false),
    );
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(posts),
        commentRepositoryProvider.overrideWithValue(LocalCommentRepository(isDevMode: false)),
        adminBanningRepositoryProvider.overrideWithValue(bans),
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
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BelongMembersDirectoryView())),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('dev_member_card_caleb_stone'));
    await tester.scrollUntilVisible(card, 400, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('dev_member_card_caleb_stone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin_ban_member_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_ban_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Failed to ban member'), findsOneWidget);
    expect(
      find.text('Caleb Stone is banned. Their posts, comments, and messages were removed.'),
      findsNothing,
    );
    expect(await bans.isUserBanned('Caleb Stone'), isTrue);
  });
}

class _StaticProfileNotifier extends MemberProfileNotifier {
  _StaticProfileNotifier(this._initial);
  final MemberProfile _initial;

  @override
  MemberProfile build() => _initial;
}
