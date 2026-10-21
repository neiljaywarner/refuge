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
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_gallery_button'),
                onPressed: () => showMemeGalleryModal(
                  ctx,
                  onSelectedMeme: (meme) => selectedMeme = meme,
                ),
                child: const Text('Open Gallery'),
              ),
            ),
          ),
        ),
      );

      await $('Open Gallery').tap();
      expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);
      expect($('Curated Calm Memes'), findsOneWidget);
      expect($('Attach Custom GIF / URL'), findsOneWidget);

      // Tap curated Elijah meme
      await $('Elijah Under the Broom Tree').tap();

      expect(selectedMeme, isNotNull);
      expect(selectedMeme!.title, equals('Elijah Under the Broom Tree'));
      expect(selectedMeme!.imageUrl, isNotNull);
    });

    patrolWidgetTest('attaches custom meme via preset button with live preview', ($) async {
      CalmMeme? selectedMeme;

      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showMemeGalleryModal(
                  ctx,
                  onSelectedMeme: (meme) => selectedMeme = meme,
                ),
                child: const Text('Open Gallery'),
              ),
            ),
          ),
        ),
      );

      await $('Open Gallery').tap();

      // Switch to custom GIF / URL tab
      await $(const Key('tab_custom_meme')).tap();
      expect($('Image or GIF URL'), findsOneWidget);
      expect($('Meme Title or Caption'), findsOneWidget);

      // Tap Elijah preset
      await $(const Key('preset_elijah')).tap();

      // Verify input fields populated and preview shown
      expect($(const Key('custom_meme_preview')), findsOneWidget);

      // Attach meme
      await $(const Key('attach_custom_meme_button')).tap();

      expect(selectedMeme, isNotNull);
      expect(selectedMeme!.title, contains('Elijah'));
      expect(selectedMeme!.imageUrl, contains('images.unsplash.com'));
    });
  });

  group('ReflectionCard Media & Meme Rendering Tests', () {
    patrolWidgetTest('renders meme image container when imageUrl is present', ($) async {
      final postWithMeme = Post(
        id: 'post_meme_1',
        authorName: 'Hannah W.',
        spaceKey: 'memes',
        toneTag: '[Autism & Faith Meme]',
        content: 'When the sanctuary lighting is dim and peaceful.',
        imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
        timestamp: DateTime.now(),
        reactions: {'relatable': 3},
      );

      await $.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(
                post: postWithMeme,
                isContrast: false,
                onAddReaction: (_) {},
              ),
            ),
          ),
        ),
      );

      expect($('Hannah W.'), findsOneWidget);
      expect($('[Autism & Faith Meme]'), findsOneWidget);
      expect($(const Key('post_meme_image_post_meme_1')), findsOneWidget);
    });

    patrolWidgetTest('omits image container when imageUrl is null', ($) async {
      final postWithoutMeme = Post(
        id: 'post_text_only',
        authorName: 'David M.',
        spaceKey: 'prayer',
        toneTag: '[Prayer Request]',
        content: 'Quiet prayer for sensory rest.',
        timestamp: DateTime.now(),
        reactions: {'pray': 2},
      );

      await $.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(
                post: postWithoutMeme,
                isContrast: false,
                onAddReaction: (_) {},
              ),
            ),
          ),
        ),
      );

      expect($(const Key('post_meme_image_post_text_only')), findsNothing);
    });
  });

  group('ReflectionComposer Meme Publishing Flow Tests', () {
    patrolWidgetTest('attaches meme and submits imageUrl with reflection', ($) async {
      String? submittedContent;
      String? submittedTone;
      String? submittedImage;

      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReflectionComposer(
              selectedSpace: 'memes',
              primaryColor: Colors.teal,
              isContrast: false,
              onSubmit: ({
                required content,
                required toneTag,
                specialInterestTag,
                imageUrl,
              }) async {
                submittedContent = content;
                submittedTone = toneTag;
                submittedImage = imageUrl;
              },
            ),
          ),
        ),
      );

      // Verify initial tone tag is [Autism & Faith Meme] because space is 'memes'
      expect($('[Autism & Faith Meme]'), findsOneWidget);

      // Open meme gallery
      await $(const Key('add_meme_gif_button')).tap();

      // Tap curated Elijah meme
      await $('Elijah Under the Broom Tree').tap();

      // Attached meme banner is visible
      expect($(const Key('attached_meme_banner')), findsOneWidget);
      expect($('Attached: Elijah Under the Broom Tree'), findsOneWidget);

      // Publish reflection
      await $(const Key('publish_reflection_button')).tap();

      expect(submittedContent, isNotNull);
      expect(submittedContent, contains('Elijah Under the Broom Tree'));
      expect(submittedTone, equals('[Autism & Faith Meme]'));
      expect(submittedImage, isNotNull);
      expect(submittedImage, contains('images.unsplash.com'));

      // Banner is reset after publishing
      expect($(const Key('attached_meme_banner')), findsNothing);
    });
  });
}
