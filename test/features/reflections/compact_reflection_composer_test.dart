import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

void main() {
  group('Compact Reflection Composer Widget Tests (#447)', () {
    patrolWidgetTest(
      'Inline composer renders in compact state with single-line hint and action buttons',
      ($) async {
        var submitted = false;

        await $.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReflectionComposer(
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
                    }) async {
                      submitted = true;
                    },
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        // 1. Compact elements exist
        expect($(Key('reflection_composer_input')), findsOneWidget);
        expect(
          $(find.textContaining('Share an unhurried thought in #General Chat')),
          findsOneWidget,
        );
        expect($(Key('composer_add_meme_compact_button')), findsOneWidget);
        expect($(Key('composer_expand_button')), findsOneWidget);

        // 2. Expanded elements are NOT yet visible
        expect($(Key('publish_reflection_button')), findsNothing);
        expect($(Key('composer_collapse_button')), findsNothing);
        expect($('Intent Tag: '), findsNothing);
        expect(submitted, isFalse);
      },
    );

    patrolWidgetTest(
      'Tapping expand button expands the composer to show Intent Tag and Publish button',
      ($) async {
        await $.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReflectionComposer(
                selectedSpace: 'prayer',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: false,
                onSubmit: ({
                  required String content,
                  required String toneTag,
                  String? specialInterestTag,
                  String? imageUrl,
                }) async {},
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        // Tap expand
        await $(Key('composer_expand_button')).tap();
        await $.pumpAndSettle();

        // Now expanded elements appear
        expect($('Intent Tag: '), findsOneWidget);
        expect($(Key('composer_collapse_button')), findsOneWidget);
        expect($(Key('publish_reflection_button')), findsOneWidget);
        expect($(Key('add_meme_gif_button')), findsOneWidget);

        // Tap collapse
        await $(Key('composer_collapse_button')).tap();
        await $.pumpAndSettle();

        // Collapsed again
        expect($(Key('publish_reflection_button')), findsNothing);
        expect($(Key('composer_expand_button')), findsOneWidget);
      },
    );

    patrolWidgetTest('Entering text into compact input expands the composer automatically', (
      $,
    ) async {
      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReflectionComposer(
              selectedSpace: 'general_chat',
              primaryColor: Colors.teal,
              isContrast: false,
              isModal: false,
              onSubmit: ({
                required String content,
                required String toneTag,
                String? specialInterestTag,
                String? imageUrl,
              }) async {},
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      await $(Key('reflection_composer_input')).enterText('A quiet rest in God.');
      await $.pumpAndSettle();

      // Auto-expanded
      expect($(Key('publish_reflection_button')), findsOneWidget);
      expect($('Intent Tag: '), findsOneWidget);
    });

    patrolWidgetTest(
      'Publishing a reflection submits content and collapses composer back to compact state',
      ($) async {
        String? submittedText;
        String? submittedTone;

        await $.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReflectionComposer(
                selectedSpace: 'prayer',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: false,
                onSubmit:
                    ({
                      required String content,
                      required String toneTag,
                      String? specialInterestTag,
                      String? imageUrl,
                    }) async {
                      submittedText = content;
                      submittedTone = toneTag;
                    },
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        // Expand and type
        await $(Key('composer_expand_button')).tap();
        await $.pumpAndSettle();

        await $(Key('reflection_composer_input')).enterText('Walking in gentle grace today.');
        await $.pumpAndSettle();

        // Publish
        await $(Key('publish_reflection_button')).tap();
        await $.pumpAndSettle();

        expect(submittedText, equals('Walking in gentle grace today.'));
        expect(submittedTone, equals('[Prayer Request]'));

        // Verify composer collapsed back to compact state
        expect($(Key('publish_reflection_button')), findsNothing);
        expect($(Key('composer_expand_button')), findsOneWidget);
        expect(
          $(find.textContaining('Share an unhurried thought in #Prayer Sanctuary')),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest('expanded action row does not overflow on 360px phone width (#557)', (
      $,
    ) async {
      await $.tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => $.tester.binding.setSurfaceSize(null));

      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReflectionComposer(
                selectedSpace: 'memes',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: false,
                onSubmit: ({
                  required String content,
                  required String toneTag,
                  String? specialInterestTag,
                  String? imageUrl,
                }) async {},
              ),
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      await $(Key('composer_expand_button')).tap();
      await $.pumpAndSettle();

      expect($(Key('add_meme_gif_button')), findsOneWidget);
      expect($(Key('publish_reflection_button')), findsOneWidget);
      expect($.tester.takeException(), isNull);
    });

    patrolWidgetTest(
      'Modal mode (isModal: true) renders in expanded state by default without collapse button',
      ($) async {
        await $.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReflectionComposer(
                selectedSpace: 'general_chat',
                primaryColor: Colors.teal,
                isContrast: false,
                isModal: true,
                onSubmit: ({
                  required String content,
                  required String toneTag,
                  String? specialInterestTag,
                  String? imageUrl,
                }) async {},
              ),
            ),
          ),
        );
        await $.pumpAndSettle();

        // In modal mode, it is already expanded
        expect($('Intent Tag: '), findsOneWidget);
        expect($(Key('publish_reflection_button')), findsOneWidget);
        // Modal mode does NOT show inline collapse button (the modal sheet has its own close X)
        expect($(Key('composer_collapse_button')), findsNothing);
        expect($(Key('composer_expand_button')), findsNothing);
      },
    );
  });
}
