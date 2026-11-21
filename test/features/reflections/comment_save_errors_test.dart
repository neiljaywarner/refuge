import 'dart:async';

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

class _HangingWriteRepo extends LocalCommentRepository {
  _HangingWriteRepo({super.initialComments})
    : super(
        isDevMode: false,
        customFirestore: FakeFirebaseFirestore(),
        currentUid: () => 'uid-ana',
        firestoreTimeout: const Duration(milliseconds: 20),
      );

  final Completer<void> hang = Completer<void>();

  @override
  Future<void> persistCommentToFirestore(FirebaseFirestore fs, Comment comment, String? authorId) =>
      hang.future;
}

class _TimeoutCommentRepository extends LocalCommentRepository {
  _TimeoutCommentRepository() : super(isDevMode: false);

  @override
  Future<Comment> addComment(Comment comment) async {
    await super.addComment(comment);
    throw TimeoutException('Firestore write timed out');
  }
}

class _SlowFailingCommentRepository extends LocalCommentRepository {
  _SlowFailingCommentRepository() : super(isDevMode: false);

  final Completer<void> gate = Completer<void>();

  @override
  Future<Comment> addComment(Comment comment) async {
    await gate.future;
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

    test(
      'fails visibly when the signed-in uid is missing so createsAsSelf would deny the write',
      () async {
        final fs = FakeFirebaseFirestore();
        final repo = LocalCommentRepository(
          isDevMode: false,
          customFirestore: fs,
          currentUid: () => null,
        );

        await expectLater(repo.addComment(_comment('c-no-uid')), throwsA(isA<StateError>()));
        expect((await fs.collection('comments').doc('c-no-uid').get()).exists, isFalse);
        expect(await repo.getComments(postId: 'p1'), isEmpty);
      },
    );

    test('a write timeout keeps the local comment so a late success can stand', () async {
      final repo = _HangingWriteRepo();

      await expectLater(repo.addComment(_comment('c-slow')), throwsA(isA<TimeoutException>()));
      expect((await repo.getComments(postId: 'p1')).map((c) => c.id), ['c-slow']);

      repo.hang.complete();
      await Future<void>.delayed(Duration.zero);
      expect((await repo.getComments(postId: 'p1')).map((c) => c.id), ['c-slow']);
    });

    test('a write timeout rolls back later if Firestore then rejects the write', () async {
      final repo = _HangingWriteRepo();

      await expectLater(repo.addComment(_comment('c-late-fail')), throwsA(isA<TimeoutException>()));
      expect(await repo.getComments(postId: 'p1'), isNotEmpty);

      repo.hang.completeError(_permissionDenied());
      await Future<void>.delayed(Duration.zero);
      expect(await repo.getComments(postId: 'p1'), isEmpty);
    });

    test('a timed-out write reports the later rejection for the sheet', () async {
      final repo = _HangingWriteRepo();
      final outcomes = <CommentWriteSettlement>[];
      final sub = repo.commentWriteSettlements.listen(outcomes.add);
      addTearDown(sub.cancel);

      await expectLater(repo.addComment(_comment('c-late-fail')), throwsA(isA<TimeoutException>()));

      repo.hang.completeError(_permissionDenied());
      await Future<void>.delayed(Duration.zero);

      expect(outcomes, hasLength(1));
      expect(outcomes.single.commentId, 'c-late-fail');
      expect(outcomes.single.succeeded, isFalse);
      expect(outcomes.single.error, isA<FirebaseException>());
      expect(await repo.getComments(postId: 'p1'), isEmpty);
    });

    test('a timed-out write reports the later success for the sheet', () async {
      final repo = _HangingWriteRepo();
      final outcomes = <CommentWriteSettlement>[];
      final sub = repo.commentWriteSettlements.listen(outcomes.add);
      addTearDown(sub.cancel);

      await expectLater(repo.addComment(_comment('c-slow')), throwsA(isA<TimeoutException>()));

      repo.hang.complete();
      await Future<void>.delayed(Duration.zero);

      expect(outcomes, hasLength(1));
      expect(outcomes.single.commentId, 'c-slow');
      expect(outcomes.single.succeeded, isTrue);
      expect((await repo.getComments(postId: 'p1')).map((c) => c.id), ['c-slow']);
    });
  });

  group('restoreFailedCommentComposer (#981)', () {
    test('restores the failed reply when the composer is still empty', () {
      final controller = TextEditingController();
      final replyingTo = ValueNotifier<Comment?>(null);
      final target = _comment('c-target');

      restoreFailedCommentComposer(
        textController: controller,
        replyingTo: replyingTo,
        text: _reply,
        replyTarget: target,
      );

      expect(controller.text, _reply);
      expect(replyingTo.value, target);
      controller.dispose();
      replyingTo.dispose();
    });

    test('does not overwrite a newer draft or reply target', () {
      final controller = TextEditingController(text: 'Checking in again tomorrow.');
      final newerTarget = _comment('c-newer');
      final replyingTo = ValueNotifier<Comment?>(newerTarget);

      restoreFailedCommentComposer(
        textController: controller,
        replyingTo: replyingTo,
        text: _reply,
        replyTarget: _comment('c-target'),
      );

      expect(controller.text, 'Checking in again tomorrow.');
      expect(replyingTo.value, newerTarget);
      controller.dispose();
      replyingTo.dispose();
    });

    test('does not restore either field when only the draft text changed', () {
      final controller = TextEditingController(text: 'Checking in again tomorrow.');
      final replyingTo = ValueNotifier<Comment?>(null);
      final target = _comment('c-target');

      restoreFailedCommentComposer(
        textController: controller,
        replyingTo: replyingTo,
        text: _reply,
        replyTarget: target,
      );

      expect(controller.text, 'Checking in again tomorrow.');
      expect(replyingTo.value, isNull);
      controller.dispose();
      replyingTo.dispose();
    });

    test('does not restore either field when only the reply target changed', () {
      final controller = TextEditingController();
      final newerTarget = _comment('c-newer');
      final replyingTo = ValueNotifier<Comment?>(newerTarget);

      restoreFailedCommentComposer(
        textController: controller,
        replyingTo: replyingTo,
        text: _reply,
        replyTarget: _comment('c-target'),
      );

      expect(controller.text, isEmpty);
      expect(replyingTo.value, newerTarget);
      controller.dispose();
      replyingTo.dispose();
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

  patrolWidgetTest(
    'A failed send keeps the reply text, shows an error, and does not leave the comment in the thread',
    ($) async {
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
      expect(find.descendant(of: find.byType(ListView), matching: find.text(_reply)), findsNothing);
    },
  );

  patrolWidgetTest('A timed-out send keeps the reply in the thread and does not restore the text', (
    $,
  ) async {
    await _setSheetSurface($);
    await $.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(_TimeoutCommentRepository()),
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
    await $.pump();
    await $.pump(const Duration(milliseconds: 100));

    final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, isEmpty);
    expect(find.byKey(const Key('comment_send_pending_snackbar')), findsOneWidget);
    expect(find.text(commentSendPendingMessage), findsOneWidget);
    expect(find.byKey(const Key('comment_send_failed_snackbar')), findsNothing);
    expect(find.descendant(of: find.byType(ListView), matching: find.text(_reply)), findsOneWidget);
  });

  patrolWidgetTest('A failed send does not overwrite a newer draft typed while saving', ($) async {
    await _setSheetSurface($);
    const draftB = 'Checking in again tomorrow.';
    final repo = _SlowFailingCommentRepository();
    await $.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(repo),
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
    await $.pump();

    await $.tester.enterText(find.byKey(const Key('comment_input_field')), draftB);
    await $.pump();
    repo.gate.complete();
    await $.pump();
    await $.pump(const Duration(milliseconds: 100));

    final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, draftB);
    expect(find.byKey(const Key('comment_send_failed_snackbar')), findsOneWidget);
    expect(find.text(_reply), findsNothing);
  });

  patrolWidgetTest(
    'A timed-out send that later fails restores the text and reply target inside the sheet',
    ($) async {
      await _setSheetSurface($);
      final parent = Comment(
        id: 'c-parent',
        postId: _post.id,
        authorName: 'Jordan',
        content: 'An earlier thought.',
        timestamp: DateTime.utc(2026, 11, 18, 11),
      );
      final repo = _HangingWriteRepo(initialComments: [parent]);
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            commentRepositoryProvider.overrideWithValue(repo),
            memberProfileProvider.overrideWith(_FakeProfile.new),
          ],
          child: MaterialApp(
            home: Scaffold(body: ThreadedDiscussionSheet(post: _post)),
          ),
        ),
      );
      await $.pumpAndSettle();

      await $.tester.tap(find.byKey(const Key('reply_button_c-parent')));
      await $.pump();
      await $.tester.enterText(find.byKey(const Key('comment_input_field')), _reply);
      await $.pump();
      await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
      await $.pump();
      await $.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('comment_send_pending_snackbar')), findsOneWidget);
      expect(find.text('Replying to @Jordan'), findsNothing);

      repo.hang.completeError(_permissionDenied());
      await $.pump();
      await $.pump(const Duration(milliseconds: 50));

      final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
      expect(field.controller!.text, _reply);
      expect(find.text('Replying to @Jordan'), findsOneWidget);
      expect(find.byKey(const Key('comment_send_failed_snackbar')), findsOneWidget);
      expect(
        find.text('This reply was not saved (permission-denied). Your words are still here.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('comment_send_pending_snackbar')), findsNothing);
      expect(find.descendant(of: find.byType(ListView), matching: find.text(_reply)), findsNothing);
    },
  );

  patrolWidgetTest(
    'A timed-out send that later succeeds clears the pending notice and keeps the reply',
    ($) async {
      await _setSheetSurface($);
      final repo = _HangingWriteRepo();
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            commentRepositoryProvider.overrideWithValue(repo),
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
      await $.pump();
      await $.pump(const Duration(milliseconds: 50));

      expect(find.text(commentSendPendingMessage), findsOneWidget);

      repo.hang.complete();
      await $.pump();
      await $.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('comment_send_pending_snackbar')), findsNothing);
      expect(find.byKey(const Key('comment_send_failed_snackbar')), findsNothing);
      final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
      expect(field.controller!.text, isEmpty);
      expect(
        find.descendant(of: find.byType(ListView), matching: find.text(_reply)),
        findsOneWidget,
      );
    },
  );

  patrolWidgetTest('A late rejection does not replace a newer draft or reply target', ($) async {
    await _setSheetSurface($);
    const draftB = 'Checking in again tomorrow.';
    final parent = Comment(
      id: 'c-parent',
      postId: _post.id,
      authorName: 'Jordan',
      content: 'An earlier thought.',
      timestamp: DateTime.utc(2026, 11, 18, 11),
    );
    final other = Comment(
      id: 'c-other',
      postId: _post.id,
      authorName: 'Riley',
      content: 'Another thought.',
      timestamp: DateTime.utc(2026, 11, 18, 11, 30),
    );
    final repo = _HangingWriteRepo(initialComments: [parent, other]);
    await $.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(repo),
          memberProfileProvider.overrideWith(_FakeProfile.new),
        ],
        child: MaterialApp(
          home: Scaffold(body: ThreadedDiscussionSheet(post: _post)),
        ),
      ),
    );
    await $.pumpAndSettle();

    await $.tester.tap(find.byKey(const Key('reply_button_c-parent')));
    await $.pump();
    await $.tester.enterText(find.byKey(const Key('comment_input_field')), _reply);
    await $.pump();
    await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
    await $.pump();
    await $.pump(const Duration(milliseconds: 50));

    await $.tester.enterText(find.byKey(const Key('comment_input_field')), draftB);
    await $.pump();
    await $.tester.tap(find.byKey(const Key('reply_button_c-other')));
    await $.pump();

    repo.hang.completeError(_permissionDenied());
    await $.pump();
    await $.pump(const Duration(milliseconds: 50));

    final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, draftB);
    expect(find.text('Replying to @Riley'), findsOneWidget);
    expect(find.text('Replying to @Jordan'), findsNothing);
    expect(find.text(_reply), findsNothing);
    expect(find.byKey(const Key('comment_send_failed_snackbar')), findsOneWidget);
  });

  patrolWidgetTest('A failed send shows the error inside the discussion sheet', ($) async {
    await _setSheetSurface($);
    await $.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(_FailingCommentRepository()),
          memberProfileProvider.overrideWith(_FakeProfile.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const Key('open_discussion_sheet'),
                onPressed: () => ThreadedDiscussionSheet.show(context, post: _post),
                child: const Text('Open discussion'),
              ),
            ),
          ),
        ),
      ),
    );
    await $.pumpAndSettle();
    await $.tester.tap(find.byKey(const Key('open_discussion_sheet')));
    await $.pumpAndSettle();

    await $.tester.enterText(find.byKey(const Key('comment_input_field')), _reply);
    await $.pump();
    await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
    await $.pump();
    await $.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(ThreadedDiscussionSheet),
        matching: find.byKey(const Key('comment_send_failed_snackbar')),
      ),
      findsOneWidget,
    );
    expect(
      find.text('This reply was not saved (permission-denied). Your words are still here.'),
      findsOneWidget,
    );
  });
}

Future<void> _setSheetSurface(PatrolTester $) async {
  $.tester.view.devicePixelRatio = 1.0;
  $.tester.view.physicalSize = const Size(1200, 2400);
  addTearDown(() {
    $.tester.view.resetPhysicalSize();
    $.tester.view.resetDevicePixelRatio();
  });
}
