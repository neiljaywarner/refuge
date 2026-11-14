import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/feedback_drawing_canvas.dart';

void main() {
  test('a wide short image is lifted to a readable canvas', () {
    final canvas = FeedbackScreenshotFrame.canvasSize(
      imageWidth: 2000,
      imageHeight: 20,
      screen: const Size(400, 800),
      availableWidth: 900,
    );

    expect(canvas.height, 140);
    expect(canvas.width, lessThanOrEqualTo(FeedbackScreenshotFrame.maxColumnWidth));
  });

  test('a tall image is limited by the screen, and a missing image stays short', () {
    final tall = FeedbackScreenshotFrame.canvasSize(
      imageWidth: 100,
      imageHeight: 2000,
      screen: const Size(360, 700),
      availableWidth: double.infinity,
    );
    expect(tall.height, lessThanOrEqualTo(640));
    expect(tall.width, lessThan(tall.height));

    final blank = FeedbackScreenshotFrame.canvasSize(
      screen: const Size(100, 200),
      availableWidth: 400,
    );
    expect(blank.width, 120);
    expect(blank.height, inInclusiveRange(150, 260));
  });

  test('contain keeps the whole image, and an empty size stays in the canvas', () {
    final fitted = FeedbackScreenshotFrame.containRect(
      image: const Size(200, 100),
      canvas: const Size(100, 100),
    );
    expect(fitted.width, 100);
    expect(fitted.height, 50);
    expect(fitted.top, 25);

    final empty = FeedbackScreenshotFrame.containRect(image: Size.zero, canvas: const Size(80, 40));
    expect(empty.size, const Size(80, 40));
  });
}
