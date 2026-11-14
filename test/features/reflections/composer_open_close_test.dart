import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

Future<void> _pump(WidgetTester tester, Widget composer, {double textScale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1400);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: composer)),
    ),
  );
}

void main() {
  Future<PostPublishStatus> publish({
    required String content,
    required String toneTag,
    String? specialInterestTag,
    String? imageUrl,
  }) async => PostPublishStatus.confirmed;

  testWidgets('expand, edit, publish, and collapse the inline composer', (tester) async {
    String? published;
    await _pump(
      tester,
      ReflectionComposer(
        selectedSpace: 'prayer',
        primaryColor: const Color(0xFF2E6B56),
        isContrast: false,
        onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async {
          published = content;
          return PostPublishStatus.confirmed;
        },
      ),
    );

    expect(find.byKey(const Key('composer_expand_button')), findsOneWidget);
    expect(find.byKey(const Key('composer_collapse_button')), findsNothing);

    await tester.tap(find.byKey(const Key('composer_expand_button')));
    await tester.pumpAndSettle();
    expect(find.text('Intent Tag: '), findsOneWidget);
    expect(find.byKey(const Key('publish_reflection_button')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reflection_composer_input')), 'A quiet thought.');
    await tester.tap(find.byKey(const Key('publish_reflection_button')));
    await tester.pumpAndSettle();

    expect(published, 'A quiet thought.');
    expect(find.byKey(const Key('composer_expand_button')), findsOneWidget);
  });

  testWidgets('an empty publish stays open and says the draft is empty', (tester) async {
    await _pump(
      tester,
      ReflectionComposer(
        selectedSpace: 'prayer',
        primaryColor: const Color(0xFF2E6B56),
        isContrast: true,
        onSubmit: publish,
      ),
    );

    await tester.tap(find.byKey(const Key('reflection_composer_input')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('publish_reflection_button')));
    await tester.pump();

    expect(find.byKey(const Key('empty_reflection_warning_snackbar')), findsOneWidget);
    expect(find.byKey(const Key('composer_collapse_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('composer_collapse_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('composer_expand_button')), findsOneWidget);
  });

  testWidgets('an image post shows the url and alt fields at a large text scale', (tester) async {
    await _pump(
      tester,
      ReflectionComposer(
        selectedSpace: 'special_interests',
        primaryColor: const Color(0xFF2E6B56),
        isContrast: false,
        isImagePost: true,
        onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async {
          expect(content, 'A picture.');
          expect(imageUrl, 'https://example.com/calm.png');
          return PostPublishStatus.pending;
        },
      ),
      textScale: 2,
    );

    expect(find.byKey(const Key('special_interest_tag_input')), findsOneWidget);
    expect(find.byKey(const Key('image_post_url_input')), findsOneWidget);
    expect(find.byKey(const Key('image_post_alt_text_input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('image_post_url_input')),
      'https://example.com/calm.png',
    );
    await tester.pump();
    expect(find.byKey(const Key('image_post_preview_container')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reflection_composer_input')), 'A picture.');
    await tester.tap(find.byKey(const Key('publish_reflection_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reflection_publish_pending_snackbar')), findsOneWidget);
  });

  testWidgets('a failed publish leaves the draft open', (tester) async {
    await _pump(
      tester,
      ReflectionComposer(
        selectedSpace: 'prayer',
        primaryColor: const Color(0xFF2E6B56),
        isContrast: false,
        onSubmit: ({required content, required toneTag, specialInterestTag, imageUrl}) async =>
            PostPublishStatus.failed,
      ),
    );
    await tester.tap(find.byKey(const Key('composer_expand_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reflection_composer_input')), 'Still here.');
    await tester.tap(find.byKey(const Key('publish_reflection_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reflection_publish_failed_snackbar')), findsOneWidget);
    expect(find.text('Still here.'), findsOneWidget);
  });
}
