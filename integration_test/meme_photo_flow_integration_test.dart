import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/memes/domain/calm_meme.dart';
import 'package:refuge4serverpod/src/features/memes/presentation/meme_gallery_modal.dart';
import 'package:refuge4serverpod/src/features/profile/data/avatar_upload_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/avatar_picker_sheet.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Meme & Avatar Photo Native Flow Integration Tests', () {
    patrolWidgetTest(
      'Full End-to-End Meme Photo Capture Flow: Open Gallery -> Camera Tab -> Capture -> Caption -> Reflection Composer',
      ($) async {
        $.tester.view.devicePixelRatio = 1.0;
        $.tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(() {
          $.tester.view.resetPhysicalSize();
          $.tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeAvatarUploadService();
        String? submittedContent;
        String? submittedTone;
        String? submittedImage;

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              avatarUploadServiceProvider.overrideWithValue(fakeService),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(title: const Text('Belong Memes Integration')),
                body: ReflectionComposer(
                  selectedSpace: 'memes',
                  primaryColor: Colors.teal,
                  isContrast: false,
                  isModal: true,
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

        // 1. Verify composer is rendered
        expect($(const Key('reflection_composer_input')), findsOneWidget);
        expect($(const Key('add_meme_gif_button')), findsOneWidget);

        // 2. Open Meme Gallery
        await $(const Key('add_meme_gif_button')).tap();
        await $.pumpAndSettle();
        expect($('🖼️ Autism & Faith Meme Gallery'), findsOneWidget);

        // 3. Switch to Upload Photo / Camera Tab
        await $(const Key('tab_upload_photo')).tap();
        await $.pumpAndSettle();
        expect($(const Key('meme_upload_camera_button')), findsOneWidget);
        expect($(const Key('meme_upload_gallery_button')), findsOneWidget);

        // 4. Capture photo with camera
        await $(const Key('meme_upload_camera_button')).tap();
        await $.pumpAndSettle();

        // 5. Verify live preview and custom caption
        expect($(const Key('uploaded_photo_preview')), findsOneWidget);
        await $(const Key('meme_upload_caption_input')).enterText('Sanctuary Nature Walk');
        await $.pumpAndSettle();

        // 6. Attach photo
        await $(const Key('attach_uploaded_photo_button')).tap();
        await $.pumpAndSettle();

        // 7. Verify attached banner in composer
        expect($(const Key('attached_meme_banner')), findsOneWidget);
        expect($('Attached: Sanctuary Nature Walk'), findsOneWidget);

        // 8. Publish reflection
        await $(const Key('publish_reflection_button')).tap();
        await $.pumpAndSettle();

        expect(submittedContent, contains('Sanctuary Nature Walk'));
        expect(submittedTone, equals('[Autism & Faith Meme]'));
        expect(submittedImage, startsWith('data:image/png;base64,'));
      },
    );

    patrolWidgetTest(
      'Full End-to-End Avatar Camera Flow: Open Sheet -> Select Camera -> Zero Storage Perms -> Update Profile',
      ($) async {
        final fakeService = FakeAvatarUploadService();
        final storageRepo = InMemoryStorageRepository();

        await $.pumpWidgetAndSettle(
          ProviderScope(
            overrides: [
              avatarUploadServiceProvider.overrideWithValue(fakeService),
              storageRepositoryProvider.overrideWithValue(storageRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Builder(
                    builder: (ctx) => ElevatedButton(
                      key: const Key('open_avatar_sheet_btn'),
                      onPressed: () => AvatarPickerSheet.show(ctx),
                      child: const Text('Open Avatar Sheet'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Open avatar sheet
        await $(const Key('open_avatar_sheet_btn')).tap();
        await $.pumpAndSettle();
        expect($('Profile Avatar'), findsOneWidget);

        // 2. Select camera
        await $(const Key('avatar_source_camera')).tap();
        await $.pumpAndSettle();

        // 3. Verify peaceful confirmation
        expect($('Avatar updated peacefully.'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Reflection Card Renders Inline Base64 Photo Without Network Latency',
      ($) async {
        const photoDataUri =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

        final postWithPhoto = Post(
          id: 'post_integration_photo',
          authorName: 'Sarah K.',
          spaceKey: 'memes',
          toneTag: '[Autism & Faith Meme]',
          content: 'Found a cozy quiet corner in the garden today 🌿',
          imageUrl: photoDataUri,
          timestamp: DateTime.now(),
          reactions: {'gentle': 4},
        );

        await $.pumpWidgetAndSettle(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReflectionCard(
                  post: postWithPhoto,
                  isContrast: false,
                  onAddReaction: (_) {},
                ),
              ),
            ),
          ),
        );

        expect($('Sarah K.'), findsOneWidget);
        expect($('Found a cozy quiet corner in the garden today 🌿'), findsOneWidget);
        expect($(const Key('post_meme_image_post_integration_photo')), findsOneWidget);
      },
    );
  });
}
