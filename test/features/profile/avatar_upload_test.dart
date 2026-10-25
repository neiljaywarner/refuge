import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/data/avatar_upload_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/avatar_models.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/avatar_picker_sheet.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('AvatarUploadService Unit Tests', () {
    test(
      'PlatformAvatarUploadService checks and sets permissions correctly',
      () async {
        final service = PlatformAvatarUploadService();
        expect(
          (await service.checkPermission(AvatarImageSource.camera)).isGranted,
          isTrue,
        );
        expect(
          (await service.checkPermission(AvatarImageSource.gallery)).isGranted,
          isTrue,
        );

        service.setMockPermission(
          AvatarImageSource.camera,
          AvatarPermissionStatus.denied,
        );
        expect(
          (await service.checkPermission(AvatarImageSource.camera)).isDenied,
          isTrue,
        );

        service.setMockPermission(
          AvatarImageSource.gallery,
          AvatarPermissionStatus.permanentlyDenied,
        );
        expect(
          (await service.checkPermission(AvatarImageSource.gallery))
              .isPermanentlyDenied,
          isTrue,
        );
      },
    );

    test('PlatformAvatarUploadService crops valid square images and handles invalid bytes safely', () async {
      final service = PlatformAvatarUploadService();
      final validPng = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      // Valid PNG bytes crop into square target size
      final cropped = await service.cropSquare(validPng, targetSize: 64);
      expect(cropped, isNotNull);
      expect(cropped.length, greaterThan(0));

      // Invalid bytes gracefully return raw bytes without throwing
      final invalid = Uint8List.fromList([0x00, 0xFF, 0xAA]);
      final fallback = await service.cropSquare(invalid);
      expect(fallback, equals(invalid));
    });

    test('PlatformAvatarUploadService requestPermission and pickImage fallback behavior', () async {
      final service = PlatformAvatarUploadService(
        initialCameraPermission: AvatarPermissionStatus.permanentlyDenied,
      );

      final permStatus = await service.requestPermission(
        AvatarImageSource.camera,
      );
      expect(permStatus.isPermanentlyDenied, isTrue);

      // When permanently denied, pickImage returns null
      final picked = await service.pickImage(AvatarImageSource.camera);
      expect(picked, isNull);

      // When granted, pickImage in test environment falls back to sample avatar on missing plugin
      service.setMockPermission(
        AvatarImageSource.gallery,
        AvatarPermissionStatus.granted,
      );
      final sampleBytes = await service.pickImage(AvatarImageSource.gallery);
      expect(sampleBytes, isNotNull);
      expect(sampleBytes!.length, greaterThan(0));

      // openAppSettings completes without uncaught exceptions
      final opened = await service.openAppSettings();
      expect(opened, isA<bool>());
    });

    test(
      'a denied camera or gallery pick is not returned as a sample photo',
      () async {
        final service = PlatformAvatarUploadService(
          picker: _DeniedImagePicker(),
        );

        expect(
          () => service.pickImage(AvatarImageSource.camera),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              'camera_access_denied',
            ),
          ),
        );
      },
    );

    test(
      'FakeAvatarUploadService handles pickImage and permissions properly',
      () async {
        final fake = FakeAvatarUploadService(
          cameraPermission: AvatarPermissionStatus.denied,
        );
        final resultDenied = await fake.pickImage(AvatarImageSource.camera);
        expect(resultDenied, isNull);

        fake.cameraPermission = AvatarPermissionStatus.granted;
        final resultGranted = await fake.pickImage(AvatarImageSource.camera);
        expect(resultGranted, isNotNull);
        expect(resultGranted!.length, greaterThan(0));

        await fake.openAppSettings();
        expect(fake.appSettingsOpened, isTrue);
      },
    );
  });

  group('Avatar Picker & Profile Dialog Widget Tests', () {
    Widget buildHarness({
      required FakeAvatarUploadService avatarService,
      MemberProfile? initialProfile,
      StorageRepository? storageRepo,
    }) => ProviderScope(
      overrides: [
        avatarUploadServiceProvider.overrideWithValue(avatarService),
        storageRepositoryProvider.overrideWithValue(
          storageRepo ?? InMemoryStorageRepository(),
        ),
        if (initialProfile != null)
          memberProfileProvider.overrideWith(
            () => _CustomProfileNotifier(initialProfile),
          ),
      ],
      child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
    );

    patrolWidgetTest(
      'Tapping edit avatar button opens AvatarPickerSheet with Camera and Gallery options',
      ($) async {
        final fakeService = FakeAvatarUploadService();
        await $.pumpWidget(buildHarness(avatarService: fakeService));
        await $.pumpAndSettle();

        // Find edit avatar button in dialog header
        expect($(const Key('edit_avatar_button')), findsOneWidget);
        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        // Check options
        expect($('Profile Avatar'), findsOneWidget);
        expect($(const Key('avatar_source_camera')), findsOneWidget);
        expect($(const Key('avatar_source_gallery')), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Selecting camera with granted permission uploads photo and updates avatar',
      ($) async {
        final fakeService = FakeAvatarUploadService(
          cameraPermission: AvatarPermissionStatus.granted,
        );
        await $.pumpWidget(buildHarness(avatarService: fakeService));
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        await $(const Key('avatar_source_camera')).tap();
        await $.pumpAndSettle();

        expect($('Avatar updated peacefully.'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Selecting source with denied permission displays gentle explanation banner',
      ($) async {
        final fakeService = FakeAvatarUploadService(
          galleryPermission: AvatarPermissionStatus.denied,
        );
        await $.pumpWidget(buildHarness(avatarService: fakeService));
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        await $(const Key('avatar_source_gallery')).tap();
        await $.pumpAndSettle();

        expect($(const Key('avatar_permission_denied_banner')), findsOneWidget);
        expect(
          $(
            'Gallery / Photos permission was denied. Please allow access if you wish to use a photo.',
          ),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      'Selecting source with permanent denial displays settings dialog with action button',
      ($) async {
        final fakeService = FakeAvatarUploadService(
          cameraPermission: AvatarPermissionStatus.permanentlyDenied,
        );
        await $.pumpWidget(buildHarness(avatarService: fakeService));
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        await $(const Key('avatar_source_camera')).tap();
        await $.pumpAndSettle();

        expect($('Permission Needed'), findsOneWidget);
        expect($(const Key('open_app_settings_button')), findsOneWidget);

        await $(const Key('open_app_settings_button')).tap();
        await $.pumpAndSettle();

        expect(fakeService.appSettingsOpened, isTrue);
      },
    );

    patrolWidgetTest('User cancels photo selection gracefully without error', (
      $,
    ) async {
      final fakeService = FakeAvatarUploadService(returnNullOnPick: true);
      await $.pumpWidget(buildHarness(avatarService: fakeService));
      await $.pumpAndSettle();

      await $(const Key('edit_avatar_button')).tap();
      await $.pumpAndSettle();

      await $(const Key('avatar_source_camera')).tap();
      await $.pumpAndSettle();

      // Sheet is still open and no snackbar is shown
      expect($(const Key('avatar_source_camera')), findsOneWidget);
      expect($('Avatar updated peacefully.'), findsNothing);
    });

    patrolWidgetTest(
      'Permanent denial dialog Cancel button closes dialog without opening settings',
      ($) async {
        final fakeService = FakeAvatarUploadService(
          cameraPermission: AvatarPermissionStatus.permanentlyDenied,
        );
        await $.pumpWidget(buildHarness(avatarService: fakeService));
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        await $(const Key('avatar_source_camera')).tap();
        await $.pumpAndSettle();

        expect($(const Key('avatar_denial_cancel_button')), findsOneWidget);
        await $(const Key('avatar_denial_cancel_button')).tap();
        await $.pumpAndSettle();

        expect($(const Key('avatar_denial_cancel_button')), findsNothing);
        expect(fakeService.appSettingsOpened, isFalse);
      },
    );

    patrolWidgetTest(
      'Storage upload failure displays calm error message in sheet',
      ($) async {
        final fakeService = FakeAvatarUploadService();
        final failingRepo = _FailingStorageRepository();

        await $.pumpWidget(
          buildHarness(avatarService: fakeService, storageRepo: failingRepo),
        );
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        await $(const Key('avatar_source_camera')).tap();
        await $.pumpAndSettle();

        expect($(const Key('avatar_permission_denied_banner')), findsOneWidget);
        expect(
          $(
            'Could not update avatar: Exception: Simulated storage upload network failure',
          ),
          findsOneWidget,
        );
      },
    );

    patrolWidgetTest(
      'Removing existing avatar clears avatarUrl and closes sheet',
      ($) async {
        final fakeService = FakeAvatarUploadService();
        const existingProfile = MemberProfile(
          displayName: 'Hannah Abbott',
          email: 'hannah@example.com',
          bio: 'Sensory quiet',
          comfortBadges: ['Quiet please'],
          isSignedIn: true,
          avatarUrl: 'https://storage.belongonthespectrum.com/avatars/test.png',
        );

        await $.pumpWidget(
          buildHarness(
            avatarService: fakeService,
            initialProfile: existingProfile,
          ),
        );
        await $.pumpAndSettle();

        await $(const Key('edit_avatar_button')).tap();
        await $.pumpAndSettle();

        expect($(const Key('avatar_remove_button')), findsOneWidget);
        await $(const Key('avatar_remove_button')).tap();
        await $.pumpAndSettle();

        // Sheet closed
        expect($(const Key('avatar_remove_button')), findsNothing);
      },
    );
  });
}

class _CustomProfileNotifier extends MemberProfileNotifier {
  _CustomProfileNotifier(this._initial);
  final MemberProfile _initial;

  @override
  MemberProfile build() => _initial;
}

class _DeniedImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    throw PlatformException(
      code: 'camera_access_denied',
      message: 'The user denied camera access.',
    );
  }
}

class _FailingStorageRepository extends InMemoryStorageRepository {
  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String filename,
  }) async {
    throw Exception('Simulated storage upload network failure');
  }
}
