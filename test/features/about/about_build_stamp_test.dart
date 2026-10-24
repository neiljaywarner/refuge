import 'package:flutter/material.dart';
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
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAboutRefugeDialog(
                context,
                primaryColor: Colors.teal,
                isContrast: false,
                buildIdentity: identity,
                loadVersion: loadVersion,
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

  testWidgets('About shows version, full SHA, UTC build time, and release', (
    tester,
  ) async {
    final builtAt = DateTime.utc(2026, 10, 24, 22, 42, 2, 123);
    final builtAtMs = builtAt.millisecondsSinceEpoch;

    await openAbout(
      tester,
      identity: BuildIdentity(
        gitCommitSha: _sha,
        buildTimeMs: '$builtAtMs',
        releaseTag: 'v0.9.1',
      ),
      loadVersion: () async =>
          const AppVersionLabel(version: '0.9.1', buildNumber: '2'),
    );

    expect(find.text('Belong on the Spectrum (v0.9.1+2)'), findsOneWidget);
    expect(find.text('Version: v0.9.1+2'), findsOneWidget);
    expect(find.text('Git commit: $_sha'), findsOneWidget);
    expect(
      find.text('Build time: 2026-10-24T22:42:02.123Z ($builtAtMs ms)'),
      findsOneWidget,
    );
    expect(find.text('Release: v0.9.1'), findsOneWidget);
    expect(find.text('$gitCommitUrlPrefix$_sha'), findsOneWidget);
    expect(find.text('Source: dev'), findsNothing);
  });

  testWidgets('About shows dev/unknown when dart-defines are missing', (
    tester,
  ) async {
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
    expect(
      find.textContaining('github.com/neiljaywarner/refuge/commit/'),
      findsNothing,
    );
    expect(BuildIdentity.fromEnvironment.commitLabel, 'unknown');
    expect(BuildIdentity.fromEnvironment.sourceLabel, 'dev');
  });

  testWidgets('invalid defines stay unknown and are not labeled as a SHA', (
    tester,
  ) async {
    await openAbout(
      tester,
      identity: const BuildIdentity(
        gitCommitSha: 'dev',
        buildTimeMs: 'soon',
        releaseTag: 'v0.9.1',
      ),
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
}
