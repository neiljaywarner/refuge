import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

/// Steps for `async_buttons_single_tap.feature` (#977).
class _SlowSaveRepository extends LocalPostRepository {
  _SlowSaveRepository(this.gate) : super(isDevMode: false);
  final Completer<void> gate;
  int toggles = 0;

  @override
  Future<void> toggleSavePost({required String postId}) async {
    toggles++;
    await gate.future;
  }
}

Finder _spinnerIn(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byType(CircularProgressIndicator),
);

void main() {
  patrolWidgetTest('Publishing a reflection twice in a row posts it once', (
    $,
  ) async {
    // Given the reflection composer with a slow connection
    final gate = Completer<PostPublishStatus>();
    var submits = 0;
    await $.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReflectionComposer(
              selectedSpace: 'general_chat',
              primaryColor: Colors.teal,
              isContrast: false,
              isModal: true,
              onSubmit:
                  ({
                    required String content,
                    required String toneTag,
                    String? specialInterestTag,
                    String? imageUrl,
                  }) {
                    submits++;
                    return gate.future;
                  },
            ),
          ),
        ),
      ),
    );
    await $.pumpAndSettle();

    // When I write a reflection and tap Publish twice
    await $.tester.enterText(
      find.byKey(const Key('reflection_composer_input')),
      'A gentle evening.',
    );
    await $.pump();
    const publish = Key('publish_reflection_button');
    await $.tester.ensureVisible(find.byKey(publish));
    await $.tester.tap(find.byKey(publish));
    await $.tester.tap(find.byKey(publish), warnIfMissed: false);
    await $.pump();

    // Then Publish shows a spinner
    expect(_spinnerIn(publish), findsOneWidget);
    // And the reflection is submitted once
    expect(submits, 1);

    gate.complete(PostPublishStatus.confirmed);
    await $.pumpAndSettle();
    expect(submits, 1);
  });

  patrolWidgetTest('Tapping Save for Later twice in a row saves it once', (
    $,
  ) async {
    // Given a reflection card with a slow connection
    final gate = Completer<void>();
    final repo = _SlowSaveRepository(gate);
    final post = Post(
      id: 'post-977-save',
      authorName: 'Test Author',
      spaceKey: 'prayer',
      toneTag: 'Gentle',
      content: 'A quiet evening reflection.',
      timestamp: DateTime(2026, 11, 1),
      reactions: const {},
    );
    await $.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReflectionCard(
                post: post,
                isContrast: false,
                onAddReaction: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await $.pumpAndSettle();

    // When I tap Save for Later twice
    final save = Key('save_post_button_${post.id}');
    await $.tester.tap(find.byKey(save));
    await $.tester.tap(find.byKey(save), warnIfMissed: false);
    await $.pump();

    // Then the save button shows a spinner
    expect(_spinnerIn(save), findsOneWidget);
    // And the post is toggled once
    expect(repo.toggles, 1);

    gate.complete();
    await $.pumpAndSettle();
    expect(repo.toggles, 1);
  });

  patrolWidgetTest(
    'Collapsing and expanding mid-publish does not submit twice',
    ($) async {
      // Given the feed composer with a slow connection
      final gate = Completer<PostPublishStatus>();
      var submits = 0;
      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReflectionComposer(
                selectedSpace: 'general_chat',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: false,
                onSubmit:
                    ({
                      required String content,
                      required String toneTag,
                      String? specialInterestTag,
                      String? imageUrl,
                    }) {
                      submits++;
                      return gate.future;
                    },
              ),
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      // When I write a reflection, tap Publish, collapse, expand, and tap Publish again
      await $.tester.enterText(
        find.byKey(const Key('reflection_composer_input')),
        'A gentle evening.',
      );
      await $.pump();
      const publish = Key('publish_reflection_button');
      await $.tester.ensureVisible(find.byKey(publish));
      await $.tester.tap(find.byKey(publish));
      await $.pump();
      expect(submits, 1);

      await $.tester.ensureVisible(
        find.byKey(const Key('composer_collapse_button')),
      );
      await $.tester.tap(find.byKey(const Key('composer_collapse_button')));
      await $.pump();
      expect(find.byKey(publish), findsNothing);

      await $.tester.tap(find.byKey(const Key('reflection_composer_input')));
      await $.pump();
      await $.tester.ensureVisible(find.byKey(publish));
      await $.tester.tap(find.byKey(publish));
      await $.pump();

      // Then the reflection is submitted once
      expect(submits, 1);
      // And Publish shows a spinner
      expect(_spinnerIn(publish), findsOneWidget);

      gate.complete(PostPublishStatus.confirmed);
      await $.pumpAndSettle();
      expect(submits, 1);
    },
  );
}
