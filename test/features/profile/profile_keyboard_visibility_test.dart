import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

import '../../support/test_font_loader.dart';

const _keyboardInset = 340.0;

const _fields = <Key>[
  Key('profile_display_name_field'),
  Key('profile_last_name_field'),
  Key('profile_email_field'),
  Key('profile_church_affiliation_dropdown'),
  Key('profile_bio_field'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestFontLoader.loadAppFonts();
  });

  setUp(() {
    ProfileStorageService.instance.clear();
  });

  tearDown(() {
    ProfileStorageService.instance.clear();
  });

  for (final surface in const <(String, Size, double)>[
    ('small phone', Size(360, 640), 1),
    ('Pixel 9a', Size(1080, 2424), 2.6),
    ('tablet or web', Size(1024, 768), 1),
  ]) {
    for (final scale in const <double>[1.0, 1.3, 2.0, 3.0]) {
      testWidgets('focused profile fields stay above the keyboard on ${surface.$1} at '
          'text scale $scale', (tester) async {
        final overflows = _captureOverflows();
        await _pumpProfile(
          tester,
          physicalSize: surface.$2,
          devicePixelRatio: surface.$3,
          textScale: scale,
        );
        _expectNoOverflow(overflows, '${surface.$1} scale $scale after open');

        for (final key in _fields) {
          final reason = '${surface.$1} scale $scale $key';
          await tester.showKeyboard(find.byKey(key, skipOffstage: false));
          await tester.pump(const Duration(milliseconds: 250));
          _expectNoOverflow(overflows, reason);
          _expectFullyVisible(tester, find.byKey(key), reason: reason);
        }

        const saveReason = 'Save';
        await tester.ensureVisible(
          find.byKey(const Key('profile_save_sign_in_button'), skipOffstage: false),
        );
        await tester.pump();
        _expectNoOverflow(overflows, '${surface.$1} scale $scale $saveReason');
        _expectFullyVisible(
          tester,
          find.byKey(const Key('profile_save_sign_in_button')),
          reason: '${surface.$1} scale $scale $saveReason',
        );
      });
    }
  }

  for (final scale in const <double>[1.0, 2.0, 3.0]) {
    testWidgets('golden: profile keyboard-up layout at text scale $scale', (tester) async {
      await _pumpProfile(
        tester,
        physicalSize: const Size(360, 640),
        devicePixelRatio: 1,
        textScale: scale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/profile_keyboard_scale_${scale.toStringAsFixed(0)}.png'),
      );
    });
  }
}

List<FlutterErrorDetails> _captureOverflows() {
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

void _expectNoOverflow(List<FlutterErrorDetails> overflows, String reason) {
  if (overflows.isEmpty) return;
  final rendered = overflows.map((details) => details.exceptionAsString()).join('\n---\n');
  fail('$reason painted an overflow:\n$rendered');
}

void _expectFullyVisible(WidgetTester tester, Finder finder, {required String reason}) {
  expect(finder, findsOneWidget, reason: reason);
  expect(tester.takeException(), isNull, reason: reason);
  final rect = tester.getRect(finder);
  final logical = Size(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    tester.view.physicalSize.height / tester.view.devicePixelRatio,
  );
  final visibleBottom = logical.height - _keyboardInset;
  expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$reason top $rect');
  expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$reason left $rect');
  expect(rect.right, lessThanOrEqualTo(logical.width + 0.5), reason: '$reason right $rect');
  expect(
    rect.bottom,
    lessThanOrEqualTo(visibleBottom + 0.5),
    reason: '$reason bottom ${rect.bottom} must be above the keyboard at $visibleBottom ($rect)',
  );
  expect(rect.width, greaterThan(8), reason: reason);
  expect(rect.height, greaterThan(8), reason: reason);
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required Size physicalSize,
  required double devicePixelRatio,
  required double textScale,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = physicalSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SensoryThemeData.getTheme(SensoryMode.clean),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              viewInsets: media.viewInsets.copyWith(bottom: _keyboardInset),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                key: const Key('open_profile_sheet'),
                tooltip: 'Open profile',
                onPressed: () => MemberProfileDialog.show(context),
                icon: const Icon(Icons.person_outline),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('open_profile_sheet')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
