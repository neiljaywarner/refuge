import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/build/build_identity.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_build_stamp.dart';
import 'package:refuge4serverpod/src/features/about/presentation/about_refuge_dialog.dart';

const _sha = '0123456789abcdef0123456789abcdef01234567';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openAbout(
    WidgetTester tester, {
    BuildIdentity? identity,
    Future<AppVersionLabel> Function()? loadVersion,
    VoidCallback? onOpenFeedback,
    String? fontFamily,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fontFamily == null ? null : ThemeData(fontFamily: fontFamily),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAboutRefugeDialog(
                context,
                primaryColor: Colors.teal,
                isContrast: false,
                buildIdentity: identity,
                loadVersion: loadVersion,
                onOpenFeedback: onOpenFeedback,
              ),
              child: const Text('Open About'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open About'));
    await tester.pumpAndSettle();
  }

  testWidgets('About shows version, full SHA, UTC build time, and release', (tester) async {
    final builtAt = DateTime.utc(2026, 10, 24, 22, 42, 2, 123);
    final builtAtMs = builtAt.millisecondsSinceEpoch;

    await openAbout(
      tester,
      identity: BuildIdentity(gitCommitSha: _sha, buildTimeMs: '$builtAtMs', releaseTag: 'v0.9.1'),
      loadVersion: () async => const AppVersionLabel(version: '0.9.1', buildNumber: '2'),
    );

    expect(find.text('Belong on the Spectrum (v0.9.1+2)'), findsOneWidget);
    expect(find.text('Version: v0.9.1+2'), findsOneWidget);
    expect(find.text('Git commit: $_sha'), findsOneWidget);
    expect(find.text('Build time: 2026-10-24T22:42:02.123Z ($builtAtMs ms)'), findsOneWidget);
    expect(find.text('Release: v0.9.1'), findsOneWidget);
    expect(find.text('$gitCommitUrlPrefix$_sha'), findsOneWidget);
    expect(find.text('Source: dev'), findsNothing);
  });

  testWidgets('About shows dev/unknown when dart-defines are missing', (tester) async {
    await openAbout(
      tester,
      identity: const BuildIdentity(),
      loadVersion: () async => AppVersionLabel.unknown,
    );

    expect(find.text('Version: unknown'), findsOneWidget);
    expect(find.text('Git commit: unknown'), findsOneWidget);
    expect(find.text('Build time: unknown'), findsOneWidget);
    expect(find.text('Source: dev'), findsOneWidget);
    expect(find.text('Release: dev'), findsNothing);
    expect(find.byKey(const Key('about_build_commit_url')), findsNothing);
    expect(find.textContaining('github.com/neiljaywarner/refuge/commit/'), findsNothing);
    expect(BuildIdentity.fromEnvironment.commitLabel, 'unknown');
    expect(BuildIdentity.fromEnvironment.sourceLabel, 'dev');
  });

  testWidgets('Copy build info puts the stamp on the clipboard', (tester) async {
    final builtAt = DateTime.utc(2026, 10, 24, 22, 42, 2, 123);
    final builtAtMs = builtAt.millisecondsSinceEpoch;
    final identity = BuildIdentity(
      gitCommitSha: _sha,
      buildTimeMs: '$builtAtMs',
      releaseTag: 'v0.9.1',
    );
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardText = methodCall.arguments['text'] as String?;
        }
        return null;
      },
    );

    await openAbout(
      tester,
      identity: identity,
      loadVersion: () async => const AppVersionLabel(version: '0.9.1', buildNumber: '2'),
    );

    await tester.tap(find.byKey(const Key('about_copy_build_info_button')));
    await tester.pumpAndSettle();

    expect(clipboardText, identity.supportClipboardBlock(versionLine: 'v0.9.1+2'));
    expect(find.text('Build info copied to clipboard'), findsOneWidget);
  });

  testWidgets('invalid defines stay unknown and are not labeled as a SHA', (tester) async {
    await openAbout(
      tester,
      identity: const BuildIdentity(gitCommitSha: 'broken', buildTimeMs: 'nope'),
      loadVersion: () async => AppVersionLabel.unknown,
    );

    expect(find.text('Git commit: unknown'), findsOneWidget);
    expect(find.text('Build time: unknown'), findsOneWidget);
    expect(find.text('Git commit: broken'), findsNothing);
    expect(find.textContaining('github.com/neiljaywarner/refuge/commit/'), findsNothing);
  });

  testWidgets('About help copy says use in-app Vote & Feedback only (#495)', (tester) async {
    await openAbout(tester);

    expect(find.text('Help & Feedback'), findsOneWidget);
    expect(
      find.text(
        'For feature ideas, bug reports, and feedback, please use the in-app Vote & Feedback button on the home screen.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vote & Feedback'), findsOneWidget);
  });

  testWidgets('About body text uses font size >= 14sp (#547)', (tester) async {
    await openAbout(tester);

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    var foundParagraph = false;
    for (final text in textWidgets) {
      final style = text.style;
      if (style != null &&
          style.fontSize != null &&
          text.data != null &&
          text.data!.contains('Belong on the Spectrum is a dedicated')) {
        foundParagraph = true;
        expect(style.fontSize, greaterThanOrEqualTo(14.0));
      }
    }
    expect(foundParagraph, isTrue);
  });

  testWidgets('About dialog fits in 320px logical width without RenderFlex overflow (#547)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await openAbout(
      tester,
      identity: const BuildIdentity(
        gitCommitSha: _sha,
        buildTimeMs: '1729813322123',
        releaseTag: 'v0.9.1',
      ),
      loadVersion: () async => const AppVersionLabel(version: '0.9.1', buildNumber: '2'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Belong on the Spectrum (v0.9.1+2)'), findsOneWidget);
  });

  testWidgets('About dialog renders with Outfit font when specified (#547)', (tester) async {
    await openAbout(tester, fontFamily: 'Outfit');

    expect(find.text('Belong on the Spectrum'), findsOneWidget);
    final textWidget = tester.widget<Text>(find.text('Belong on the Spectrum'));
    expect(textWidget.style?.fontFamily, 'Outfit');
  });

  testWidgets('About dialog scripture text has high contrast in high contrast mode (#547)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAboutRefugeDialog(
                context,
                primaryColor: Colors.teal,
                isContrast: true,
              ),
              child: const Text('Open About'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open About'));
    await tester.pumpAndSettle();

    final titleWidget = tester.widget<Text>(find.text('Belong on the Spectrum'));
    expect(titleWidget.style?.color, const Color(0xFFFFEB3B));

    final scriptureFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('God has placed the parts in the body'),
    );
    expect(scriptureFinder, findsOneWidget);
    final scriptureWidget = tester.widget<Text>(scriptureFinder);
    expect(scriptureWidget.style?.color, const Color(0xFFFFEB3B));
  });

  testWidgets('About dialog closes on Dismiss tap (#547)', (tester) async {
    await openAbout(tester);

    expect(find.text('Belong on the Spectrum'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Belong on the Spectrum'), findsNothing);
  });

  testWidgets('About dialog opens feedback sheet when Vote & Feedback tapped (#547)', (
    tester,
  ) async {
    var feedbackOpened = false;
    await openAbout(tester, onOpenFeedback: () => feedbackOpened = true);

    await tester.tap(find.text('Vote & Feedback'));
    await tester.pumpAndSettle();

    expect(feedbackOpened, isTrue);
  });

  testWidgets('About dialog gold accents match sensory calm aesthetic (#547)', (tester) async {
    await openAbout(tester);

    final divider = tester.widget<Divider>(find.byType(Divider).first);
    expect(divider.color, const Color(0xFFD4AF37));
  });

  testWidgets(
    'Golden: About dialog matches visual baseline',
    (tester) async {
      await tester.runAsync(() async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await openAbout(tester);

        final finder = find.byType(AlertDialog);
        expect(finder, findsOneWidget);

        final element = finder.evaluate().single;
        final renderObject = element.renderObject! as RenderRepaintBoundary;
        final image = await renderObject.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final goldenFile = File('test/features/about/goldens/about_refuge_dialog.png');
        if (!goldenFile.existsSync()) {
          goldenFile.parent.createSync(recursive: true);
          goldenFile.writeAsBytesSync(pngBytes);
        } else {
          final expectedBytes = goldenFile.readAsBytesSync();
          expect(pngBytes, equals(expectedBytes));
        }
      });
    },
    skip: !Platform.isMacOS,
  );
}
