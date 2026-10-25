import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:refuge4serverpod/src/features/profile/presentation/belong_image_crop_page.dart';

Uint8List _twoTonePhoto() {
  final image = img.Image(width: 128, height: 96);
  img.fill(image, color: img.ColorRgb8(45, 106, 106));
  img.fillRect(image, x1: 0, y1: 0, x2: 40, y2: 40, color: img.ColorRgb8(220, 30, 30));
  return Uint8List.fromList(img.encodePng(image));
}

Future<void> _openCrop(WidgetTester tester, {required bool circular}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () async {
              final result = await BelongImageCropPage.show(
                context,
                bytes: _twoTonePhoto(),
                circular: circular,
              );
              captured = result;
            },
            child: const Text('open'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump();
  expect(find.text('Crop photo'), findsOneWidget);
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pump();
}

Uint8List? captured;

void main() {
  setUp(() => captured = null);

  testWidgets('Use this crop returns the framed photo', (tester) async {
    await _openCrop(tester, circular: true);

    final button = tester.widget<FilledButton>(find.byKey(const Key('use_cropped_photo_button')));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('use_cropped_photo_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.length, greaterThan(32));
    expect(find.text('Crop photo'), findsNothing);
    expect(find.text('Could not crop that photo.'), findsNothing);
  });

  testWidgets('a pinch changes the bytes that Use this crop returns', (tester) async {
    await _openCrop(tester, circular: false);
    await tester.tap(find.byKey(const Key('use_cropped_photo_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    await tester.pump();
    final untouched = captured;
    expect(untouched, isNotNull);

    captured = null;
    await _openCrop(tester, circular: false);
    final cropRect = tester.getRect(find.byType(Crop));
    final center = cropRect.center;
    final left = await tester.startGesture(center - const Offset(30, 0));
    final right = await tester.startGesture(center + const Offset(30, 0));
    await left.moveBy(const Offset(-50, 0));
    await right.moveBy(const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await left.up();
    await right.up();
    await tester.pump();

    await tester.tap(find.byKey(const Key('use_cropped_photo_button')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump();
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured, isNot(untouched));
  });

  testWidgets('cancel leaves the photo uncropped', (tester) async {
    await _openCrop(tester, circular: false);
    await tester.tap(find.byKey(const Key('cancel_crop_button')));
    await tester.pump();
    await tester.pump();

    expect(captured, isNull);
    expect(find.text('Crop photo'), findsNothing);
  });
}
