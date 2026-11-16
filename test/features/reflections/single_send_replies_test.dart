import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/reflections/data/comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_comment_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/comment.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/threaded_discussion_sheet.dart';

/// Steps for `single_send_replies.feature` (#977).
///
/// The fake repository adds the reply locally right away (like the real one)
/// and then waits on [gate], standing in for a slow Firestore write on Android.
class _SlowCommentRepository extends LocalCommentRepository {
  _SlowCommentRepository() : super(isDevMode: false);

  final List<Comment> saved = [];
  Completer<void> gate = Completer<void>();

  @override
  Future<Comment> addComment(Comment comment) async {
    saved.add(comment);
    final result = super.addComment(comment);
    await gate.future;
    return result;
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
  id: 'post-977',
  authorName: 'Test Author',
  spaceKey: 'prayer',
  toneTag: 'Gentle',
  content: 'A quiet evening reflection.',
  timestamp: DateTime(2026, 11, 1),
  reactions: const {},
);

const _reply = 'Holding you in prayer tonight.';

Future<_SlowCommentRepository> _givenReflectionWithSlowSaves(PatrolTester $) async {
  $.tester.view.devicePixelRatio = 1.0;
  $.tester.view.physicalSize = const Size(1200, 2400);
  addTearDown(() {
    $.tester.view.resetPhysicalSize();
    $.tester.view.resetDevicePixelRatio();
  });
  final repo = _SlowCommentRepository();
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
  return repo;
}

Future<void> _writeAndTapSend(PatrolTester $, String text) async {
  await $.tester.enterText(find.byKey(const Key('comment_input_field')), text);
  await $.pump();
  await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
  await $.pump();
}

IconButton _sendButton(PatrolTester $) => $.tester.widget<IconButton>(
  find.descendant(
    of: find.byKey(const Key('submit_comment_button')),
    matching: find.byWidgetPredicate((w) => w is IconButton),
    matchRoot: true,
  ),
);

Finder _sendSpinner() => find.descendant(
  of: find.byKey(const Key('submit_comment_button')),
  matching: find.byType(CircularProgressIndicator),
);

void main() {
  patrolWidgetTest('Tapping Send twice while the first reply is still saving posts one reply', (
    $,
  ) async {
    // Given a reflection with no replies
    // And saving a reply is slow
    final repo = await _givenReflectionWithSlowSaves($);

    // When I write the reply and tap Send
    await _writeAndTapSend($, _reply);

    // And I tap Send again before the first reply has saved
    // (the Android keyboard can keep the text, so type it back like a member would)
    await _writeAndTapSend($, _reply);
    await $.tester.tap(find.byKey(const Key('submit_comment_button')), warnIfMissed: false);
    await $.pump();

    repo.gate.complete();
    await $.pumpAndSettle();

    // Then only one reply is saved
    expect(repo.saved, hasLength(1));
    // And the reply appears once in the thread
    expect(find.descendant(of: find.byType(ListView), matching: find.text(_reply)), findsOneWidget);
  });

  patrolWidgetTest('The composer clears as soon as Send is tapped', ($) async {
    // Given a reflection with no replies
    // And saving a reply is slow
    final repo = await _givenReflectionWithSlowSaves($);

    // When I write the reply and tap Send
    await _writeAndTapSend($, _reply);

    // Then the reply box is empty
    final field = $.tester.widget<TextField>(find.byKey(const Key('comment_input_field')));
    expect(field.controller!.text, isEmpty);
    // And Send is disabled until the reply has saved
    expect(_sendButton($).onPressed, isNull);

    repo.gate.complete();
    await $.pumpAndSettle();
    expect(repo.saved, hasLength(1));
  });

  patrolWidgetTest('Send shows a spinner while saving', ($) async {
    // Given a reflection with no replies
    // And saving a reply is slow
    final repo = await _givenReflectionWithSlowSaves($);

    // When I write the reply and tap Send
    await _writeAndTapSend($, _reply);

    // Then Send shows a spinner instead of the send icon
    expect(_sendSpinner(), findsOneWidget);

    // And the spinner goes away once the reply has saved
    repo.gate.complete();
    await $.pumpAndSettle();
    expect(_sendSpinner(), findsNothing);
  });

  patrolWidgetTest('A second, separate reply still posts after the first has saved', ($) async {
    // Given a reflection with one saved reply
    final repo = await _givenReflectionWithSlowSaves($);
    repo.gate.complete();
    await _writeAndTapSend($, _reply);
    await $.pumpAndSettle();
    expect(repo.saved, hasLength(1));

    // When I write another reply and tap Send
    repo.gate = Completer<void>()..complete();
    await _writeAndTapSend($, 'And for rest tomorrow.');
    await $.pumpAndSettle();

    // Then two different replies are saved
    expect(repo.saved, hasLength(2));
    expect(repo.saved.map((c) => c.content).toSet(), {_reply, 'And for rest tomorrow.'});
  });
}
