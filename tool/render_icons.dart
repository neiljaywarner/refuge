import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Standalone script to render high-contrast Belong launcher icon assets on-demand.
///
/// Run via:
/// ```bash
/// flutter test tool/render_icons.dart
/// ```
///
/// This was previously located in `test/tool/render_icons_test.dart`, where it ran on every
/// `flutter test` invocation and mutated binary launcher assets in the working tree.
/// Moving it to `tool/` ensures test runs remain pure and deterministic while preserving
/// the vector canvas generation logic.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  stdout.writeln('Rendering high-contrast Belong launcher icon assets...');

  // Canvas dimensions for Android mipmaps + Master logo
  final targets = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png': 108,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png': 162,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png': 216,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png': 324,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
    'assets/images/belong_logo.png': 1024,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
    'web/favicon.png': 64,
  };

  for (final entry in targets.entries) {
    final path = entry.key;
    final size = entry.value;

    final isMasterLogo = path.contains('belong_logo.png');
    final isWebIcon = path.startsWith('web/icons') || path.contains('favicon');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    // For master logo and web icons, draw background #F3EFE6
    // For Android ic_launcher_foreground, keep background transparent (adaptive icon background provides #F3EFE6)
    if (isMasterLogo || isWebIcon) {
      final bgPaint = Paint()..color = const Color(0xFFF3EFE6);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        bgPaint,
      );
    }

    // Safe zone scaling:
    // Adaptive icon safe zone is 72dp out of 108dp (66.67%).
    // We scale our logo artwork to fill ~68% of the canvas height/width so it fills the mask boldly!
    final scale = size / 432.0;
    final cx = size / 2.0;
    final cy = size / 2.0;

    // 1. Draw Bold Infinity Symbol
    // Centered slightly above or around the middle
    final infinityStrokeWidth = 32.0 * scale;
    final loopWidth = 105.0 * scale;
    final loopHeight = 58.0 * scale;
    final infinityY = cy; // Center of loop

    final goldPaint = Paint()
      ..color =
          const Color(0xFFC89332) // Warm, high-contrast neurodivergent gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = infinityStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final infinityPath = Path();
    // Left loop: start at (cx, infinityY), curve up and left, loop around left, return to cx
    infinityPath.moveTo(cx, infinityY);
    infinityPath.cubicTo(
      cx - loopWidth * 0.45,
      infinityY - loopHeight * 1.1,
      cx - loopWidth,
      infinityY - loopHeight,
      cx - loopWidth,
      infinityY,
    );
    infinityPath.cubicTo(
      cx - loopWidth,
      infinityY + loopHeight,
      cx - loopWidth * 0.45,
      infinityY + loopHeight * 1.1,
      cx,
      infinityY,
    );
    // Right loop: start at (cx, infinityY), curve up and right, loop around right, return to cx
    infinityPath.cubicTo(
      cx + loopWidth * 0.45,
      infinityY - loopHeight * 1.1,
      cx + loopWidth,
      infinityY - loopHeight,
      cx + loopWidth,
      infinityY,
    );
    infinityPath.cubicTo(
      cx + loopWidth,
      infinityY + loopHeight,
      cx + loopWidth * 0.45,
      infinityY + loopHeight * 1.1,
      cx,
      infinityY,
    );

    canvas.drawPath(infinityPath, goldPaint);

    // 2. Draw Bold Vertical "B E L O N G" Lettering
    // Stacked vertically: B, E, L, O, N, G
    // We want thick, high-contrast navy glyphs
    final letters = ['B', 'E', 'L', 'O', 'N', 'G'];
    final letterSpacing = 42.0 * scale;
    final totalLetterHeight = letterSpacing * 5;
    final startY = cy - (totalLetterHeight / 2.0);

    for (var i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: const Color(0xFF112334), // Deep Midnight Navy
            fontSize: 34.0 * scale,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
            letterSpacing: 2.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final lx = cx - (textPainter.width / 2.0);
      final ly = startY + (i * letterSpacing) - (textPainter.height / 2.0);

      // Subtle warm glow/halo under text where it crosses the gold loop to ensure 100% legibility
      if (i == 2 || i == 3) {
        // L and O cross the loop
        final haloPaint = Paint()
          ..color = const Color(0xFFF3EFE6).withValues(alpha: 0.85)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * scale);
        canvas.drawCircle(
          Offset(cx, startY + (i * letterSpacing)),
          18.0 * scale,
          haloPaint,
        );
      }

      textPainter.paint(canvas, Offset(lx, ly));
    }

    // Convert picture to image and PNG bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    stdout.writeln('Rendered $path ($size x $size)');
  }

  stdout.writeln('All icon assets rendered successfully.');
}
