import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone surfaces and keyboard insets for form clipping checks.
///
/// Insets sit in the 300–340 range a phone keyboard occupies in logical pixels.
const List<(String, Size, double)> keyboardPhoneSurfaces =
    <(String, Size, double)>[
      ('411x914', Size(411, 914), 336),
      ('360x640', Size(360, 640), 320),
    ];

/// Installs a logical phone size, text scale, and keyboard [viewInsets].
///
/// The inset is [MediaQueryData.viewInsets.bottom]. Call this before pumping
/// the form. The form should set [Scaffold.resizeToAvoidBottomInset] and give
/// each field a [TextField.scrollPadding] that includes
/// [MediaQueryData.viewInsets].
void prepareKeyboardSurface(
  WidgetTester tester, {
  required Size logicalSize,
  required double textScale,
  required double keyboardInset,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
  });
}

/// Collects RenderFlex and other overflow reports until the test ends.
List<FlutterErrorDetails> captureOverflowErrors() {
  final overflows = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed') || message.contains('RenderFlex')) {
      overflows.add(details);
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  return overflows;
}

/// Fails when [overflows] contains a layout overflow.
void expectNoOverflow(List<FlutterErrorDetails> overflows, String reason) {
  if (overflows.isEmpty) return;
  final rendered = overflows
      .map((details) => details.exceptionAsString())
      .join('\n---\n');
  fail('$reason painted an overflow:\n$rendered');
}

/// Asserts [finder] is fully inside the screen above the keyboard.
void expectFullyAboveKeyboard(
  WidgetTester tester,
  Finder finder, {
  required double keyboardInset,
  required String reason,
}) {
  expect(finder, findsOneWidget, reason: reason);
  expect(tester.takeException(), isNull, reason: reason);
  final rect = tester.getRect(finder);
  final logical = Size(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    tester.view.physicalSize.height / tester.view.devicePixelRatio,
  );
  final visibleBottom = logical.height - keyboardInset;
  expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$reason top $rect');
  expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$reason left $rect');
  expect(
    rect.right,
    lessThanOrEqualTo(logical.width + 0.5),
    reason: '$reason right $rect',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(visibleBottom + 0.5),
    reason:
        '$reason bottom ${rect.bottom} must be above the keyboard at $visibleBottom ($rect)',
  );
  expect(rect.width, greaterThan(8), reason: reason);
  expect(rect.height, greaterThan(8), reason: reason);
}

/// Focuses [field] and checks that it and [pinned] both clear the keyboard.
///
/// Pass [scrollable] when the field may start off screen.
Future<void> expectFocusedFieldAboveKeyboard(
  WidgetTester tester, {
  required Finder field,
  required Finder pinned,
  required double keyboardInset,
  required String reason,
  Finder? scrollable,
}) async {
  if (scrollable != null) {
    await tester.scrollUntilVisible(field, 48, scrollable: scrollable);
    await tester.pump();
  }
  await tester.showKeyboard(field);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expectFullyAboveKeyboard(
    tester,
    field,
    keyboardInset: keyboardInset,
    reason: reason,
  );
  expectFullyAboveKeyboard(
    tester,
    pinned,
    keyboardInset: keyboardInset,
    reason: '$reason pinned action',
  );
}
