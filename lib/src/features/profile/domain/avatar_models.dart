import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Image input source for member avatars.
enum AvatarImageSource {
  camera('Camera', 'Take a new photo with your device camera'),
  gallery('Gallery / Photos', 'Choose an image from your photo library');

  const AvatarImageSource(this.label, this.description);
  final String label;
  final String description;
}

/// Permission state for accessing device camera or photo library.
enum AvatarPermissionStatus {
  granted('Permission granted'),
  denied('Permission denied — you can grant access to continue'),
  permanentlyDenied('Permission permanently denied — please enable in Settings'),
  restricted('Permission restricted by system policy');

  const AvatarPermissionStatus(this.description);
  final String description;

  bool get isGranted => this == AvatarPermissionStatus.granted;
  bool get isPermanentlyDenied => this == AvatarPermissionStatus.permanentlyDenied;
  bool get isDenied => this == AvatarPermissionStatus.denied;
}

/// Result of an avatar crop operation.
@immutable
class AvatarCropResult {
  const AvatarCropResult({
    required this.bytes,
    required this.width,
    required this.height,
    this.cropRect,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final Rect? cropRect;
}
