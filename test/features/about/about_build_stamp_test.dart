import 'dart:io';
import 'dart:typed_data';
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

  testWidgets('invalid defines stay unknown and are not labeled as a SHA', (tester) async {
    await openAbout(
      tester,
      identity: const BuildIdentity(gitCommitSha: 'dev', buildTimeMs: 'soon', releaseTag: 'v0.9.1'),
      loadVersion: () async => AppVersionLabel.unknown,
    );

    expect(find.text('Version: unknown'), findsOneWidget);
    expect(find.text('Git commit: unknown'), findsOneWidget);
    expect(find.text('Git commit: dev'), findsNothing);
    expect(find.text('Build time: unknown'), findsOneWidget);
    expect(find.text('Release: v0.9.1'), findsOneWidget);
    expect(find.text('Source: dev'), findsNothing);
    expect(find.byKey(const Key('about_build_commit_url')), findsNothing);
  });

  testWidgets('About help copy says use in-app Vote & Feedback only (#495)', (tester) async {
    var feedbackOpened = false;
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final captureHelp = Platform.environment['ABOUT_HELP_SCREENSHOT']?.isNotEmpty ?? false;
    if (captureHelp) {
      await _loadRoboto(tester);
    }

    await openAbout(
      tester,
      identity: const BuildIdentity(),
      loadVersion: () async => AppVersionLabel.unknown,
      onOpenFeedback: () => feedbackOpened = true,
      fontFamily: captureHelp ? 'Roboto' : null,
    );
    await tester.ensureVisible(find.byKey(const Key('about_support_copy')));
    await tester.pumpAndSettle();

    expect(find.text('Community Support & Feedback:'), findsOneWidget);
    final support = tester.widget<Text>(find.byKey(const Key('about_support_copy')));
    expect(support.data, contains('Use in-app Vote & Feedback only'));
    expect(support.data, contains('Tap Vote & Feedback on the Home screen'));
    expect(support.data, contains('Share help, an idea, or a quirk there'));
    expect(support.data, isNot(contains('@')));
    expect(support.data, isNot(contains('mailto')));
    expect(support.data, isNot(contains('email')));

    final giphyLine = tester.widget<Text>(find.byKey(const Key('about_giphy_line')));
    expect(giphyLine.data, contains('gratefully powered by GIPHY'));
    expect(giphyLine.data, contains('does not endorse Belong'));
    expect(find.byKey(const Key('about_giphy_link')), findsOneWidget);

    expect(find.textContaining('grokbot'), findsNothing);
    expect(find.textContaining('mail.grokbot.com'), findsNothing);
    expect(find.textContaining('support@'), findsNothing);
    expect(find.textContaining('WCAG'), findsNothing);
    expect(find.textContaining('Firebase'), findsNothing);

    await _writeAboutHelpScreenshot(tester);

    final feedbackButton = find.byKey(const Key('about_dialog_open_feedback_button'));
    expect(feedbackButton, findsOneWidget);
    await tester.tap(feedbackButton);
    await tester.pumpAndSettle();

    expect(feedbackOpened, isTrue);
  });
}

Future<void> _loadRoboto(WidgetTester tester) async {
  final roots = [
    Platform.environment['FLUTTER_ROOT'],
    Platform.environment['HOME'] == null ? null : '${Platform.environment['HOME']}/sdk/flutter',
  ].whereType<String>();
  File? font;
  for (final root in roots) {
    for (final path in [
      '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      '$root/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        font = file;
        break;
      }
    }
    if (font != null) break;
  }
  final file = font;
  if (file == null) return;
  await tester.runAsync(() async {
    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final loader = FontLoader('Roboto')..addFont(Future.value(data));
    await loader.load();
  });
}

/// Writes a PNG of the open About dialog when ABOUT_HELP_SCREENSHOT is set.
Future<void> _writeAboutHelpScreenshot(WidgetTester tester) async {
  final out = Platform.environment['ABOUT_HELP_SCREENSHOT'];
  if (out == null || out.isEmpty) return;

  final dialog = find.byType(AlertDialog);
  expect(dialog, findsOneWidget);
  var boundary = tester.renderObject(dialog).parent;
  while (boundary != null && boundary is! RenderRepaintBoundary) {
    boundary = boundary.parent;
  }
  final layer = boundary;
  expect(layer, isA<RenderRepaintBoundary>());
  await tester.runAsync(() async {
    final image = await (layer! as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(out);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
