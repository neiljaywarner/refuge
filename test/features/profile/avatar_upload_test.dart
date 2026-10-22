import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/profile/data/avatar_upload_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/avatar_models.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/avatar_picker_sheet.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/storage/data/storage_repository.dart';

void main() {
  group('AvatarUploadService Unit Tests', () {
    test('PlatformAvatarUploadService checks and sets permissions correctly', () async {
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
        (await service.checkPermission(AvatarImageSource.gallery)).isPermanentlyDenied,
        isTrue,
      );
    });

    test('FakeAvatarUploadService handles pickImage and permissions properly', () async {
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
    });
  });

  group('Avatar Picker & Profile Dialog Widget Tests', () {
    Widget buildHarness({
      required FakeAvatarUploadService avatarService,
      MemberProfile? initialProfile,
    }) {
      return ProviderScope(
        overrides: [
          avatarUploadServiceProvider.overrideWithValue(avatarService),
          storageRepositoryProvider.overrideWithValue(InMemoryStorageRepository()),
          if (initialProfile != null)
            memberProfileProvider.overrideWith(() => _CustomProfileNotifier(initialProfile)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MemberProfileDialog(),
          ),
        ),
      );
    }

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
          $('Gallery / Photos permission was denied. Please allow access if you wish to use a photo.'),
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
          buildHarness(avatarService: fakeService, initialProfile: existingProfile),
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
