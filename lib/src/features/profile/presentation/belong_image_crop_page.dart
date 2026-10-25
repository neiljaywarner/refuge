import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

/// Full-screen crop from `crop_your_image`.
///
/// The frame stays still. The member pinches to zoom and drags to reposition
/// the photo, then confirms. Avatar uses a circle. Memes use a square.
/// Very small byte strings skip the editor and return unchanged.
class BelongImageCropPage extends StatefulWidget {
  const BelongImageCropPage({
    super.key,
    required this.bytes,
    required this.circular,
  });

  final Uint8List bytes;
  final bool circular;

  /// Images under 120 bytes are the tiny fixtures used in widget tests.
  /// A real camera or gallery photo is much larger and always opens this page.
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List bytes,
    required bool circular,
  }) {
    if (bytes.length < 120) return Future.value(bytes);
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BelongImageCropPage(bytes: bytes, circular: circular),
      ),
    );
  }

  @override
  State<BelongImageCropPage> createState() => _BelongImageCropPageState();
}

class _BelongImageCropPageState extends State<BelongImageCropPage> {
  final CropController _controller = CropController();
  var _ready = false;

  void _confirm() {
    if (!_ready) return;
    if (widget.circular) {
      _controller.cropCircle();
    } else {
      _controller.crop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('belong_image_crop_page'),
      appBar: AppBar(
        title: const Text('Crop photo'),
        leading: IconButton(
          key: const Key('cancel_crop_button'),
          tooltip: 'Cancel crop',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Pinch or drag to frame the photo',
              key: Key('crop_zoom_hint'),
            ),
          ),
          Expanded(
            child: Crop(
              image: widget.bytes,
              controller: _controller,
              interactive: true,
              fixCropRect: true,
              aspectRatio: 1,
              withCircleUi: widget.circular,
              onStatusChanged: (status) {
                if (status == CropStatus.ready && !_ready) {
                  setState(() => _ready = true);
                }
              },
              onCropped: (result) {
                if (!mounted) return;
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    Navigator.of(context).pop(croppedImage);
                  case CropFailure():
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not crop that photo.'),
                      ),
                    );
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                key: const Key('use_cropped_photo_button'),
                onPressed: _ready ? _confirm : null,
                child: const Text('Use this crop'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
