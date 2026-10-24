import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/widgets/calm_media_image.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/memes/presentation/meme_gallery_modal.dart';
import 'package:refuge4serverpod/src/features/profile/data/avatar_upload_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/avatar_models.dart';
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
    Widget buildModalHarness({
      required ValueChanged<CalmMeme> onSelectedMeme,
      FakeAvatarUploadService? avatarService,
    }) {
      final fake = avatarService ?? FakeAvatarUploadService();
      return ProviderScope(
        overrides: [
          avatarUploadServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_gallery_button'),
                onPressed: () => showMemeGalleryModal(
                  ctx,
                  onSelectedMeme: onSelectedMeme,
                ),
                child: const Text('Open Gallery'),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.implicitView?.devicePixelRatio = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView?.resetPhysicalSize();
      binding.platformDispatcher.implicitView?.resetDevicePixelRatio();
    });

    patrolWidgetTest('renders curated memes list and selects a meme', ($) async {
      CalmMeme? selectedMeme;

      await $.pumpWidget(buildModalHarness(onSelectedMeme: (meme) => selectedMeme = meme));
      await $('Open Gallery').tap();
      expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);
      expect($('Curated Calm Memes'), findsOneWidget);
      expect($('Attach Custom GIF / URL'), findsOneWidget);
      expect($('Upload Photo / Camera'), findsOneWidget);

      // Tap curated Elijah meme
      await $('Elijah Under the Broom Tree').tap();

      expect(selectedMeme, isNotNull);
      expect(selectedMeme!.title, equals('Elijah Under the Broom Tree'));
      expect(selectedMeme!.imageUrl, isNotNull);
    });

    patrolWidgetTest('attaches custom meme via preset button with live preview', ($) async {
      CalmMeme? selectedMeme;

      await $.pumpWidget(buildModalHarness(onSelectedMeme: (meme) => selectedMeme = meme));
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

    patrolWidgetTest('captures photo with camera and attaches to reflection', ($) async {
      CalmMeme? selectedMeme;
      final fakeService = FakeAvatarUploadService();

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (meme) => selectedMeme = meme,
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      // Switch to Upload Photo / Camera tab
      await $(const Key('tab_upload_photo')).tap();
      expect($(const Key('meme_upload_camera_button')), findsOneWidget);
      expect($(const Key('meme_upload_gallery_button')), findsOneWidget);

      // Tap camera button
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // Verify photo preview is displayed
      expect($(const Key('uploaded_photo_preview')), findsOneWidget);
      expect($(const Key('meme_upload_caption_input')), findsOneWidget);

      // Change caption
      await $(const Key('meme_upload_caption_input')).enterText('My Sanctuary Moment');

      // Attach photo
      await $(const Key('attach_uploaded_photo_button')).tap();

      expect(selectedMeme, isNotNull);
      expect(selectedMeme!.title, equals('My Sanctuary Moment'));
      expect(selectedMeme!.imageUrl, startsWith('data:image/png;base64,'));
      expect(selectedMeme!.icon, equals('📷'));
    });

    patrolWidgetTest('selects photo from gallery, previews, and allows removal', ($) async {
      CalmMeme? selectedMeme;
      final fakeService = FakeAvatarUploadService();

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (meme) => selectedMeme = meme,
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      // Switch to Upload Photo / Camera tab
      await $(const Key('tab_upload_photo')).tap();

      // Tap gallery button
      await $(const Key('meme_upload_gallery_button')).tap();
      await $.pumpAndSettle();

      // Verify preview
      expect($(const Key('uploaded_photo_preview')), findsOneWidget);

      // Remove photo
      await $(const Key('remove_uploaded_photo_button')).tap();
      await $.pumpAndSettle();

      // Verify preview is gone
      expect($(const Key('uploaded_photo_preview')), findsNothing);
    });

    patrolWidgetTest('handles camera permission denial gracefully without crash', ($) async {
      final fakeService = FakeAvatarUploadService(
        cameraPermission: AvatarPermissionStatus.denied,
      );

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (_) {},
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      await $(const Key('tab_upload_photo')).tap();
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // Verify denial banner
      expect($(const Key('meme_permission_denied_banner')), findsOneWidget);
      expect($('Camera permission was denied. Please allow access if you wish to use a photo.'), findsOneWidget);
      expect($(const Key('uploaded_photo_preview')), findsNothing);
    });

    patrolWidgetTest('handles camera permanent denial and allows opening settings', ($) async {
      final fakeService = FakeAvatarUploadService(
        cameraPermission: AvatarPermissionStatus.permanentlyDenied,
      );

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (_) {},
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      await $(const Key('tab_upload_photo')).tap();
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // Verify permanent denial banner and open settings button
      expect($(const Key('meme_permission_denied_banner')), findsOneWidget);
      expect($(const Key('meme_open_settings_button')), findsOneWidget);

      await $(const Key('meme_open_settings_button')).tap();
      expect(fakeService.appSettingsOpened, isTrue);
    });

    patrolWidgetTest('canceling photo picker without choosing leaves modal in clean state', ($) async {
      final fakeService = FakeAvatarUploadService(returnNullOnPick: true);

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (_) {},
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      await $(const Key('tab_upload_photo')).tap();
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // No preview is displayed, remains in initial upload state
      expect($(const Key('uploaded_photo_preview')), findsNothing);
      expect($(const Key('meme_upload_camera_button')), findsOneWidget);
    });

    patrolWidgetTest('hardware exception during photo selection displays calm error banner', ($) async {
      final fakeService = FakeAvatarUploadService(throwOnPick: true);

      await $.pumpWidget(
        buildModalHarness(
          onSelectedMeme: (_) {},
          avatarService: fakeService,
        ),
      );
      await $('Open Gallery').tap();

      await $(const Key('tab_upload_photo')).tap();
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // Error banner is displayed
      expect($(const Key('meme_permission_denied_banner')), findsOneWidget);
      expect($('Could not select photo: Exception: Simulated camera hardware disconnect'), findsOneWidget);
    });

    patrolWidgetTest('meme gallery close button dismisses modal', ($) async {
      await $.pumpWidget(buildModalHarness(onSelectedMeme: (_) {}));
      await $('Open Gallery').tap();

      expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);
      await $(const Key('meme_gallery_close_button')).tap();
      await $.pumpAndSettle();

      expect($('🖼️ Autism & Faith Meme Gallery'), findsNothing);
    });

    patrolWidgetTest('tab switching between custom presets and back to curated list', ($) async {
      await $.pumpWidget(buildModalHarness(onSelectedMeme: (_) {}));
      await $('Open Gallery').tap();

      // Switch to custom tab
      await $(const Key('tab_custom_meme')).tap();
      await $.pumpAndSettle();

      // Tap special interest preset
      await $(const Key('preset_special_interest')).tap();
      await $.pumpAndSettle();
      expect($(const Key('custom_meme_preview')), findsOneWidget);

      // Tap quiet waters preset
      await $(const Key('preset_quiet_waters')).tap();
      await $.pumpAndSettle();
      expect($(const Key('custom_meme_preview')), findsOneWidget);

      // Switch back to curated memes tab
      await $(const Key('tab_curated_memes')).tap();
      await $.pumpAndSettle();
      expect($('Elijah Under the Broom Tree'), findsOneWidget);
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

    patrolWidgetTest('renders data URI base64 images without network errors', ($) async {
      // 1x1 transparent PNG data URI
      const dataUri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final postWithDataUri = Post(
        id: 'post_meme_data_uri',
        authorName: 'Daniel S.',
        spaceKey: 'memes',
        toneTag: '[Autism & Faith Meme]',
        content: 'Snapshot from quiet prayer time.',
        imageUrl: dataUri,
        timestamp: DateTime.now(),
        reactions: {'relatable': 1},
      );

      await $.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(
                post: postWithDataUri,
                isContrast: false,
                onAddReaction: (_) {},
              ),
            ),
          ),
        ),
      );

      expect($(const Key('post_meme_image_post_meme_data_uri')), findsOneWidget);
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
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      String? submittedContent;
      String? submittedTone;
      String? submittedImage;

      await $.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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

    patrolWidgetTest('attaches uploaded photo and submits reflection with data URI', ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      String? submittedContent;
      String? submittedTone;
      String? submittedImage;

      final fakeService = FakeAvatarUploadService();

      await $.pumpWidget(
        ProviderScope(
          overrides: [
            avatarUploadServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
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
        ),
      );

      // Open meme gallery
      await $(const Key('add_meme_gif_button')).tap();

      // Switch to Upload Photo tab
      await $(const Key('tab_upload_photo')).tap();

      // Tap Use Camera
      await $(const Key('meme_upload_camera_button')).tap();
      await $.pumpAndSettle();

      // Tap Attach Photo
      await $(const Key('attach_uploaded_photo_button')).tap();
      await $.pumpAndSettle();

      // Verify banner
      expect($(const Key('attached_meme_banner')), findsOneWidget);

      // Publish
      await $(const Key('publish_reflection_button')).tap();

      expect(submittedContent, isNotNull);
      expect(submittedImage, startsWith('data:image/png;base64,'));
    });
  });

  group('CalmMediaImage Widget Unit Tests', () {
    testWidgets('renders fallback widget on empty or broken image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: 'broken_or_empty',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders custom fallbackWidget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: '',
              fallbackWidget: Text('Custom Fallback Calm'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Fallback Calm'), findsOneWidget);
    });

    testWidgets('renders fallback on malformed base64 data URI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: r'data:image/png;base64,invalid!@#$not_base64',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('renders custom fallbackWidget on malformed base64', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: r'data:image/png;base64,invalid!@#$',
              fallbackWidget: Text('Safe Fallback Base64'),
            ),
          ),
        ),
      );

      expect(find.text('Safe Fallback Base64'), findsOneWidget);
    });

    testWidgets('renders valid base64 image data URI using Image.memory', (tester) async {
      const dataUri =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: dataUri,
              width: 100,
              height: 100,
              semanticLabel: 'Calm 1x1 test image',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders network image using Image.network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600',
              width: 200,
              height: 150,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders asset image using Image.asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalmMediaImage(
              imageUrl: 'assets/images/belong_logo.png',
              width: 50,
              height: 50,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('CalmMediaImage.buildLoadingProgress displays progress indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => CalmMediaImage.buildLoadingProgress(
                context: ctx,
                child: const Text('Loaded Image Child'),
                loadingProgress: const ImageChunkEvent(
                  cumulativeBytesLoaded: 50,
                  expectedTotalBytes: 100,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CalmMediaImage.buildLoadingProgress handles indeterminate loading and null progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => CalmMediaImage.buildLoadingProgress(
                context: ctx,
                child: const Text('Loaded Image Child'),
                loadingProgress: const ImageChunkEvent(
                  cumulativeBytesLoaded: 50,
                  expectedTotalBytes: null,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => CalmMediaImage.buildLoadingProgress(
                context: ctx,
                child: const Text('Loaded Image Child'),
                loadingProgress: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Loaded Image Child'), findsOneWidget);
    });
  });
}
