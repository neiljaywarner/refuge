import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/memes/presentation/meme_gallery_modal.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

void main() {
  group('CalmMeme & Post Domain Model Tests', () {
    test('CalmMeme serializes and deserializes imageUrl accurately', () {
      const meme = CalmMeme(
        title: 'Elijah Snack & Nap',
        icon: '🍞 💤',
        subtitle: '1 Kings 19:5',
        tag: 'Burnout & Recovery',
        body: 'Warm cake of bread and a nap under the broom tree.',
        imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
      );

      final map = meme.toMap();
      expect(map['title'], equals('Elijah Snack & Nap'));
      expect(map['imageUrl'], equals('https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600'));

      final restored = CalmMeme.fromMap(map);
      expect(restored.title, equals(meme.title));
      expect(restored.imageUrl, equals(meme.imageUrl));
      expect(restored.body, equals(meme.body));
    });

    test('Post copyWith and equality support optional imageUrl', () {
      final now = DateTime.now();
      final post1 = Post(
        id: 'post_1',
        authorName: 'Caleb T.',
        spaceKey: 'memes',
        toneTag: '[Autism & Faith Meme]',
        content: 'Me staring at Paul\'s missionary map for 45 minutes.',
        timestamp: now,
        reactions: {'relatable': 5},
      );

      expect(post1.imageUrl, isNull);

      final postWithMeme = post1.copyWith(
        imageUrl: 'https://example.com/calm_map.gif',
      );

      expect(postWithMeme.imageUrl, equals('https://example.com/calm_map.gif'));
      expect(postWithMeme.id, equals(post1.id));
      expect(postWithMeme == post1, isFalse);

      final duplicate = postWithMeme.copyWith();
      expect(duplicate == postWithMeme, isTrue);
      expect(duplicate.hashCode, equals(postWithMeme.hashCode));
    });

    test('kCuratedCalmMemes has curated wholesome memes', () {
      expect(kCuratedCalmMemes, isNotEmpty);
      expect(kCuratedCalmMemes.any((m) => m.title.contains('Elijah')), isTrue);
      expect(kCuratedCalmMemes.any((m) => m.imageUrl != null), isTrue);
    });
  });

  group('MemeGalleryModal Widget Tests', () {
    patrolWidgetTest('renders curated memes list and selects a meme', ($) async {
      CalmMeme? selectedMeme;

      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(\n              builder: (ctx) => ElevatedButton(\n                key: const Key('open_gallery_button'),\n                onPressed: () => showMemeGalleryModal(\n                  ctx,\n                  onSelectedMeme: (meme) => selectedMeme = meme,\n                ),\n                child: const Text('Open Gallery'),\n              ),\n            ),\n          ),\n        ),\n      );\n\n      await $('Open Gallery').tap();\n      expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);\n      expect($('Curated Calm Memes'), findsOneWidget);\n      expect($('Attach Custom GIF / URL'), findsOneWidget);\n\n      // Tap curated Elijah meme\n      await $('Elijah Under the Broom Tree').tap();\n\n      expect(selectedMeme, isNotNull);\n      expect(selectedMeme!.title, equals('Elijah Under the Broom Tree'));\n      expect(selectedMeme!.imageUrl, isNotNull);\n    });\n\n    patrolWidgetTest('attaches custom meme via preset button with live preview', ($) async {\n      CalmMeme? selectedMeme;\n\n      await $.pumpWidget(\n        MaterialApp(\n          home: Scaffold(\n            body: Builder(\n              builder: (ctx) => ElevatedButton(\n                onPressed: () => showMemeGalleryModal(\n                  ctx,\n                  onSelectedMeme: (meme) => selectedMeme = meme,\n                ),\n                child: const Text('Open Gallery'),\n              ),\n            ),\n          ),\n        ),\n      );\n\n      await $('Open Gallery').tap();\n\n      // Switch to custom GIF / URL tab\n      await $(const Key('tab_custom_meme')).tap();\n      expect($('Image or GIF URL'), findsOneWidget);\n      expect($('Meme Title or Caption'), findsOneWidget);\n\n      // Tap Elijah preset\n      await $(const Key('preset_elijah')).tap();\n\n      // Verify input fields populated and preview shown\n      expect($(const Key('custom_meme_preview')), findsOneWidget);\n\n      // Attach meme\n      await $(const Key('attach_custom_meme_button')).tap();\n\n      expect(selectedMeme, isNotNull);\n      expect(selectedMeme!.title, contains('Elijah'));\n      expect(selectedMeme!.imageUrl, contains('images.unsplash.com'));\n    });\n  });\n\n  group('ReflectionCard Media & Meme Rendering Tests', () {\n    patrolWidgetTest('renders meme image container when imageUrl is present', ($) async {\n      final postWithMeme = Post(\n        id: 'post_meme_1',\n        authorName: 'Hannah W.',\n        spaceKey: 'memes',\n        toneTag: '[Autism & Faith Meme]',\n        content: 'When the sanctuary lighting is dim and peaceful.',\n        imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',\n        timestamp: DateTime.now(),\n        reactions: {'relatable': 3},\n      );\n\n      await $.pumpWidget(\n        ProviderScope(\n          child: MaterialApp(\n            home: Scaffold(\n              body: ReflectionCard(\n                post: postWithMeme,\n                isContrast: false,\n                onAddReaction: (_) {},\n              ),\n            ),\n          ),\n        ),\n      );\n\n      expect($('Hannah W.'), findsOneWidget);\n      expect($('[Autism & Faith Meme]'), findsOneWidget);\n      expect($(const Key('post_meme_image_post_meme_1')), findsOneWidget);\n    });\n\n    patrolWidgetTest('omits image container when imageUrl is null', ($) async {\n      final postWithoutMeme = Post(\n        id: 'post_text_only',\n        authorName: 'David M.',\n        spaceKey: 'prayer',\n        toneTag: '[Prayer Request]',\n        content: 'Quiet prayer for sensory rest.',\n        timestamp: DateTime.now(),\n        reactions: {'pray': 2},\n      );\n\n      await $.pumpWidget(\n        ProviderScope(\n          child: MaterialApp(\n            home: Scaffold(\n              body: ReflectionCard(\n                post: postWithoutMeme,\n                isContrast: false,\n                onAddReaction: (_) {},\n              ),\n            ),\n          ),\n        ),\n      );\n\n      expect($(const Key('post_meme_image_post_text_only')), findsNothing);\n    });\n  });\n\n  group('ReflectionComposer Meme Publishing Flow Tests', () {\n    patrolWidgetTest('attaches meme and submits imageUrl with reflection', ($) async {\n      $.tester.view.devicePixelRatio = 1.0;\n      $.tester.view.physicalSize = const Size(1080, 2400);\n      addTearDown(() {\n        $.tester.view.resetPhysicalSize();\n        $.tester.view.resetDevicePixelRatio();\n      });\n\n      String? submittedContent;\n      String? submittedTone;\n      String? submittedImage;\n\n      await $.pumpWidget(\n        MaterialApp(\n          home: Scaffold(\n            body: ReflectionComposer(\n              selectedSpace: 'memes',\n              primaryColor: Colors.teal,\n              isContrast: false,\n              onSubmit: ({\n                required content,\n                required toneTag,\n                specialInterestTag,\n                imageUrl,\n              }) async {\n                submittedContent = content;\n                submittedTone = toneTag;\n                submittedImage = imageUrl;\n              },\n            ),\n          ),\n        ),\n      );\n\n      // Verify initial tone tag is [Autism & Faith Meme] because space is 'memes'\n      expect($('[Autism & Faith Meme]'), findsOneWidget);\n\n      // Open meme gallery\n      await $(const Key('add_meme_gif_button')).tap();\n\n      // Tap curated Elijah meme\n      await $('Elijah Under the Broom Tree').tap();\n\n      // Attached meme banner is visible\n      expect($(const Key('attached_meme_banner')), findsOneWidget);\n      expect($('Attached: Elijah Under the Broom Tree'), findsOneWidget);\n\n      // Publish reflection\n      await $(const Key('publish_reflection_button')).tap();\n\n      expect(submittedContent, isNotNull);\n      expect(submittedContent, contains('Elijah Under the Broom Tree'));\n      expect(submittedTone, equals('[Autism & Faith Meme]'));\n      expect(submittedImage, isNotNull);\n      expect(submittedImage, contains('images.unsplash.com'));\n\n      // Banner is reset after publishing\n      expect($(const Key('attached_meme_banner')), findsNothing);\n    });\n  });\n}\n