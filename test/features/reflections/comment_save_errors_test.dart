// #978: a failed Firestore comment write must be visible and must not
// look like a successful save.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/threaded_discussion_sheet.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

Comment _comment(String id) => Comment(
  id: id,
  postId: 'p1',
  authorName: 'Ana',
  content: 'Holding you in prayer.',
  toneTag: '[Support]',
  timestamp: DateTime.utc(2026, 11, 18, 12),
);

FirebaseException _permissionDenied() => FirebaseException(
  plugin: 'cloud_firestore',
  code: 'permission-denied',
  message: 'Missing or insufficient permissions.',
);

class _FailingCommentRepository extends LocalCommentRepository {
  _FailingCommentRepository() : super(isDevMode: false);

  @override
  Future<Comment> addComment(Comment comment) async {
    throw _permissionDenied();
  }
}

class _FakeProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile(
    displayName: 'Test Member',
    email: 'member@example.com',
    bio: '',
    comfortBadges: [],
    isSignedIn: true,
  );
}

final _post = Post(
  id: 'post-978',
  authorName: 'Test Author',
  spaceKey: 'prayer',
  toneTag: 'Gentle',
  content: 'A quiet evening reflection.',
  timestamp: DateTime(2026, 11, 1),
  reactions: const {},
);

const _reply = 'Holding you in prayer tonight.';

void main() {
  group('LocalCommentRepository addComment errors (#978)', () {
    test('does not swallow a Firestore write failure or keep the local comment', () async {
      // Throw at collection() so this test does not mock sealed Firestore types.
      final firestore = _MockFirestore();
      when(() => firestore.collection('comments')).thenThrow(_permissionDenied());

      final repo = LocalCommentRepository(
        isDevMode: false,
        customFirestore: firestore,
        currentUid: () => 'uid-ana',
      );

      await expectLater(repo.addComment(_comment('c-fail')), throwsA(isA<FirebaseException>()));
      expect(await repo.getComments(postId: 'p1'), isEmpty);
    });

    test('fails visibly when the signed-in uid is missing so createsAsSelf would deny the write', () async {
      final fs = FakeFirebaseFirestore();
      final repo = LocalCommentRepository(
        isDevMode: false,
        customFirestore: fs,
        currentUid: () => null,
      );

      await expectLater(repo.addComment(_comment('c-no-uid')), throwsA(isA<StateError>()));
      expect((await fs.collection('comments').doc('c-no-uid').get()).exists, isFalse);
      expect(await repo.getComments(postId: 'p1'), isEmpty);
    });
  });

  group('commentSendFailedMessage (#978)', () {
    test('includes the Firestore error code when one is present', () {
      expect(
        commentSendFailedMessage(_permissionDenied()),
        'This reply was not saved (permission-denied). Your words are still here.',
      );
    });

    test('keeps the generic wording when the error has no Firestore code', () {
      expect(
        commentSendFailedMessage(StateError('missing uid')),
        'This reply was not saved. Your words are still here.',
      );
    });
  });

  patrolWidgetTest('A failed send keeps the reply text, shows an error, and does not leave the comment in the thread', (
    $,
  ) async {
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    await $.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(_FailingCommentRepository()),
          memberProfileProvider.overrideWith(_FakeProfile.new),
        ],
        child: MaterialApp(
          home: Scaffold(body: ThreadedDiscussionSheet(post: _post)),
        ),
      ),
    );
    await $.pumpAndSettle();

    await $.tester.enterText(find.byKey(const Key('comment_input_field')), _reply);
    await $.pump();
    await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
    // Do not pumpAndSettle: the snackbar lasts 4 seconds.
    await $.pump();
    await $.pump(const Duration(milliseconds: 100));

    final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, _reply);
    expect(find.byKey(const Key('comment_send_failed_snackbar')), findsOneWidget);
    expect(
      find.text('This reply was not saved (permission-denied). Your words are still here.'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text(_reply)),
      findsNothing,
    );
  });
}
