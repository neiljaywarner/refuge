import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scales exercised for large-text layout. 2.0 is Android's practical maximum
/// font size. 3.0 is a smoke scale past that (font size plus display size).
const List<double> largeTextScales = <double>[1.0, 1.3, 2.0, 3.0];

/// Logical phone surface. Overflows that only appear on a handset show up here.
const Size largeTextPhoneSurface = Size(390, 844);

/// True when a framework error is a layout overflow (RenderFlex or otherwise).
bool isTextOverflowReport(FlutterErrorDetails details) =>
    details.exceptionAsString().contains('overflowed');

/// Fails the test with the overflow text when [overflows] is not empty.
void expectNoTextOverflow(List<FlutterErrorDetails> overflows, {required double scale}) {
  if (overflows.isEmpty) return;
  final rendered = overflows
      .map((details) {
        final description = details.toString();
        return description.length > 1200 ? description.substring(0, 1200) : description;
      })
      .join('\n---\n');
  fail('Text scale $scale painted ${overflows.length} overflow(s):\n$rendered');
}

/// Overflow reports collected while a [pumpWithTextScale] widget is up.
final class TextScaleSession {
  TextScaleSession({required this.overflows, required this.scale});

  final List<FlutterErrorDetails> overflows;
  final double scale;

  void check() => expectNoTextOverflow(overflows, scale: scale);
}

/// Pumps [widget] at [scale] on a phone surface and fails on any overflow.
///
/// Overflow capture stays in place until the test tears down, so a later
/// [TextScaleSession.check] still sees overflows from the next interaction.
/// [shell] wraps the pumped tree (a provider scope, for example). When
/// [wrapMaterialApp] is true and [widget] is not already a [MaterialApp], the
/// helper supplies one and applies [scale] both on the test platform
/// dispatcher and in that app's builder. Pass a full app widget with
/// [wrapMaterialApp] false so that app's own builder is what the test reads.
Future<TextScaleSession> pumpWithTextScale(
  WidgetTester tester,
  Widget widget, {
  required double scale,
  bool wrapMaterialApp = true,
  Size surface = largeTextPhoneSurface,
  double devicePixelRatio = 1,
  Widget Function(Widget child)? shell,
}) async {
  final overflows = <FlutterErrorDetails>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (isTextOverflowReport(details)) {
      overflows.add(details);
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = surface;
  final dispatcher = tester.platformDispatcher;
  dispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    dispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  Widget built = widget;
  if (wrapMaterialApp && widget is! MaterialApp && widget is! WidgetsApp) {
    built = MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: widget,
    );
  }
  if (shell != null) {
    built = shell(built);
  }

  // A new key drops navigator and hook state so a dialog or thread opened at
  // the previous scale does not cover the next scale.
  await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: built));
  await settleLargeText(tester);
  final session = TextScaleSession(overflows: overflows, scale: scale);
  session.check();
  return session;
}

/// Settles animations. A ticker that never goes idle does not hide an overflow
/// that already painted; the overflow list is still checked by the caller.
Future<void> settleLargeText(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
  } on FlutterError catch (error) {
    if (!error.toString().contains('pumpAndSettle timed out')) rethrow;
    await tester.pump();
  }
}

/// The control is at least [min] dp on each side and inside the phone surface.
void expectMinTapTarget(
  WidgetTester tester,
  Finder finder, {
  double min = 48,
  Size surface = largeTextPhoneSurface,
}) {
  expect(finder, findsWidgets);
  final rect = tester.getRect(finder.first);
  expect(rect.width, greaterThanOrEqualTo(min), reason: 'tap width ${rect.width} < $min');
  expect(rect.height, greaterThanOrEqualTo(min), reason: 'tap height ${rect.height} < $min');
  expect(rect.left, greaterThanOrEqualTo(-0.5));
  expect(rect.top, greaterThanOrEqualTo(-0.5));
  expect(rect.right, lessThanOrEqualTo(surface.width + 0.5));
  expect(rect.bottom, lessThanOrEqualTo(surface.height + 0.5));
}
