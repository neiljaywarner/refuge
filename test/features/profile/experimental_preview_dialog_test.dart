import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_backend_target.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/experimental_preview_dialog.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';

void main() {
  setUp(ProfileStorageService.instance.clear);
  tearDown(ProfileStorageService.instance.clear);

  test('the feature list follows the video-call compile flag', () {
    final on = experimentalPreviewEntries(videoCalls: true);
    expect(on.map((entry) => entry.title), ['Video calls', 'Screen share']);
    expect(experimentalPreviewEntries(videoCalls: false), isEmpty);
  });

  testWidgets('turning the preview switch on shows the dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
        ],
        child: const MaterialApp(home: Scaffold(body: MemberProfileDialog())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview_mode_switch')));
    await tester.pumpAndSettle();

    expect(find.text('Experimental features are on'), findsOneWidget);
    expect(find.textContaining('Vote & Feedback'), findsOneWidget);
    expect(find.textContaining('same switch'), findsOneWidget);
    expect(find.byKey(const Key('experimental_preview_ok')), findsOneWidget);

    await tester.tap(find.byKey(const Key('experimental_preview_ok')));
    await tester.pumpAndSettle();
    expect(find.text('Experimental features are on'), findsNothing);

    await tester.tap(find.byKey(const Key('preview_mode_switch')));
    await tester.pumpAndSettle();
    expect(find.text('Experimental features are on'), findsNothing);
  });

  for (final scale in const [1.0, 1.3, 2.0, 3.0]) {
    testWidgets(
      'the preview dialog button stays on screen at text scale $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ExperimentalPreviewDialog(
                      entries: experimentalPreviewEntries(videoCalls: true),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Video calls'), findsOneWidget);
        expect(find.text('Screen share'), findsOneWidget);
        final button = find.byKey(const Key('experimental_preview_ok'));
        final rect = tester.getRect(button);
        expect(rect.height, greaterThanOrEqualTo(48), reason: 'scale $scale');
        expect(rect.top, greaterThanOrEqualTo(-0.5), reason: 'scale $scale');
        expect(rect.bottom, lessThanOrEqualTo(640.5), reason: 'scale $scale');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('golden: preview dialog at text scale 3', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    showDialog<void>(
      context: context,
      builder: (_) => ExperimentalPreviewDialog(
        entries: experimentalPreviewEntries(videoCalls: true),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Dialog),
      matchesGoldenFile('goldens/experimental_preview_scale_3.png'),
    );
  });
}
