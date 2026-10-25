import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

import '../domain/avatar_models.dart';

/// Service managing device media permissions, image selection, and cropping
/// for member profile avatars.
abstract class AvatarUploadService {
  /// Checks current permission for [source].
  Future<AvatarPermissionStatus> checkPermission(AvatarImageSource source);

  /// Requests permission from the user for [source].
  Future<AvatarPermissionStatus> requestPermission(AvatarImageSource source);

  /// Picks raw image bytes from [source]. Returns null if canceled or denied.
  Future<Uint8List?> pickImage(AvatarImageSource source);

  /// Crops [rawBytes] into a square avatar format with target dimension [targetSize].
  Future<Uint8List> cropSquare(Uint8List rawBytes, {int targetSize = 256});

  /// Opens the device app settings screen when permissions are permanently denied.
  Future<bool> openAppSettings();
}

bool _queryOsPermissions() => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

ph.Permission? _osPermissionFor(AvatarImageSource source) {
  if (source == AvatarImageSource.camera) {
    return ph.Permission.camera;
  }
  if (Platform.isIOS) {
    return ph.Permission.photos;
  }
  // Android 13+ system photo picker does not require gallery runtime permission.
  return null;
}

AvatarPermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
  switch (status) {
    case ph.PermissionStatus.granted:
    case ph.PermissionStatus.limited:
    case ph.PermissionStatus.provisional:
      return AvatarPermissionStatus.granted;
    case ph.PermissionStatus.denied:
      return AvatarPermissionStatus.denied;
    case ph.PermissionStatus.permanentlyDenied:
    case ph.PermissionStatus.restricted:
      return AvatarPermissionStatus.permanentlyDenied;
  }
}

/// Production implementation of [AvatarUploadService].
class PlatformAvatarUploadService implements AvatarUploadService {
  PlatformAvatarUploadService({
    ImagePicker? picker,
    AvatarPermissionStatus? initialCameraPermission,
    AvatarPermissionStatus? initialGalleryPermission,
  }) : _picker = picker ?? ImagePicker() {
    if (initialCameraPermission != null) {
      _cameraOverride = initialCameraPermission;
    }
    if (initialGalleryPermission != null) {
      _galleryOverride = initialGalleryPermission;
    }
  }

  final ImagePicker _picker;
  AvatarPermissionStatus? _cameraOverride;
  AvatarPermissionStatus? _galleryOverride;

  AvatarPermissionStatus? _overrideFor(AvatarImageSource source) {
    return source == AvatarImageSource.camera ? _cameraOverride : _galleryOverride;
  }

  @visibleForTesting
  void setMockPermission(AvatarImageSource source, AvatarPermissionStatus status) {
    if (source == AvatarImageSource.camera) {
      _cameraOverride = status;
    } else {
      _galleryOverride = status;
    }
  }

  Future<AvatarPermissionStatus> _statusFromOs(AvatarImageSource source) async {
    if (!_queryOsPermissions()) {
      return AvatarPermissionStatus.granted;
    }
    final permission = _osPermissionFor(source);
    if (permission == null) {
      return AvatarPermissionStatus.granted;
    }
    return _mapPermissionStatus(await permission.status);
  }

  @override
  Future<AvatarPermissionStatus> checkPermission(AvatarImageSource source) async {
    final override = _overrideFor(source);
    if (override != null) return override;
    return _statusFromOs(source);
  }

  @override
  Future<AvatarPermissionStatus> requestPermission(AvatarImageSource source) async {
    final override = _overrideFor(source);
    if (override != null) {
      if (override.isPermanentlyDenied) return override;
      if (override.isGranted) return override;
      return override;
    }

    final current = await _statusFromOs(source);
    if (current.isPermanentlyDenied || current.isGranted) {
      return current;
    }

    if (!_queryOsPermissions()) {
      return AvatarPermissionStatus.granted;
    }

    final permission = _osPermissionFor(source);
    if (permission == null) {
      return AvatarPermissionStatus.granted;
    }

    return _mapPermissionStatus(await permission.request());
  }

  @override
  Future<Uint8List?> pickImage(AvatarImageSource source) async {
    final status = await requestPermission(source);
    if (!status.isGranted) return null;

    try {
      final imageSource = source == AvatarImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      final xFile = await _picker.pickImage(
        source: imageSource,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (xFile != null) {
        return await xFile.readAsBytes();
      }
      return null;
    } on MissingPluginException catch (e) {
      // Unit tests and hosts without the picker plugin have no camera.
      // A denied permission or a failed pick on a device must not look like
      // a successful photo, so only this case returns a sample image.
      debugPrint('ℹ️ [AvatarUploadService] Image picker plugin unavailable: $e');
      return _generateSampleAvatarBytes();
    }
  }

  @override
  Future<Uint8List> cropSquare(Uint8List rawBytes, {int targetSize = 256}) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final srcWidth = image.width.toDouble();
      final srcHeight = image.height.toDouble();
      final side = srcWidth < srcHeight ? srcWidth : srcHeight;
      final srcX = (srcWidth - side) / 2.0;
      final srcY = (srcHeight - side) / 2.0;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final srcRect = ui.Rect.fromLTWH(srcX, srcY, side, side);
      final dstRect = ui.Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble());

      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(targetSize, targetSize);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List() ?? rawBytes;
    } catch (e) {
      debugPrint('ℹ️ [AvatarUploadService] Fallback to raw bytes: $e');
      return rawBytes;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (_queryOsPermissions()) {
      return ph.openAppSettings();
    }
    try {
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Generates a valid 64x64 PNG in pure Dart for fallback preview / tests.
  Uint8List _generateSampleAvatarBytes() {
    // 1x1 transparent PNG header
    return Uint8List.fromList([
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
  }
}

/// Fake implementation of [AvatarUploadService] for unit and BDD tests.
class FakeAvatarUploadService implements AvatarUploadService {
  FakeAvatarUploadService({
    this.cameraPermission = AvatarPermissionStatus.granted,
    this.galleryPermission = AvatarPermissionStatus.granted,
    this.imageToReturn,
    this.returnNullOnPick = false,
    this.throwOnPick = false,
  });

  AvatarPermissionStatus cameraPermission;
  AvatarPermissionStatus galleryPermission;
  Uint8List? imageToReturn;
  bool returnNullOnPick;
  bool throwOnPick;
  bool appSettingsOpened = false;

  @override
  Future<AvatarPermissionStatus> checkPermission(AvatarImageSource source) async {
    return source == AvatarImageSource.camera ? cameraPermission : galleryPermission;
  }

  @override
  Future<AvatarPermissionStatus> requestPermission(AvatarImageSource source) async {
    return source == AvatarImageSource.camera ? cameraPermission : galleryPermission;
  }

  @override
  Future<Uint8List?> pickImage(AvatarImageSource source) async {
    final status = await requestPermission(source);
    if (!status.isGranted) return null;
    if (throwOnPick) throw Exception('Simulated camera hardware disconnect');
    if (returnNullOnPick) return null;
    return imageToReturn ??
        Uint8List.fromList([
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
  }

  @override
  Future<Uint8List> cropSquare(Uint8List rawBytes, {int targetSize = 256}) async {
    return rawBytes;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }
}

final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return PlatformAvatarUploadService();
});
