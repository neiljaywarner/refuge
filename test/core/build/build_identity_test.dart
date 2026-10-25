import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/build/build_identity.dart';
import 'package:refuge4serverpod/src/core/build/release_build_stamp.dart';

const _sha = '0123456789abcdef0123456789abcdef01234567';

void main() {
  final builtAt = DateTime.utc(2026, 10, 24, 22, 42, 2, 123);
  final builtAtMs = builtAt.millisecondsSinceEpoch;

  group('BuildIdentity', () {
    test('fromEnvironment is dev/unknown when defines were not passed', () {
      const identity = BuildIdentity.fromEnvironment;
      expect(identity.commitShaOrNull, isNull);
      expect(identity.commitLabel, 'unknown');
      expect(identity.buildTimeUtcLabel, 'unknown');
      expect(identity.buildTimeLine, 'unknown');
      expect(identity.commitUrl, isNull);
      expect(identity.releaseTagOrNull, isNull);
      expect(identity.isLocalDevBuild, isTrue);
      expect(identity.sourceLabel, 'dev');
      expect(identity.gitCommitSha, isEmpty);
    });

    test('shows a full SHA, UTC time, epoch millis, and release tag', () {
      final identity = BuildIdentity(
        gitCommitSha: _sha.toUpperCase(),
        buildTimeMs: '$builtAtMs',
        releaseTag: 'v0.9.1',
      );

      expect(identity.commitShaOrNull, _sha);
      expect(identity.commitLabel, _sha);
      expect(identity.buildTimeEpochMs, builtAtMs);
      expect(identity.buildTimeUtcLabel, '2026-10-24T22:42:02.123Z');
      expect(identity.buildTimeLine, '2026-10-24T22:42:02.123Z ($builtAtMs ms)');
      expect(identity.commitUrl, '$gitCommitUrlPrefix$_sha');
      expect(identity.releaseTagOrNull, 'v0.9.1');
      expect(identity.isLocalDevBuild, isFalse);
      expect(identity.sourceLabel, isNull);
    });

    test('rejects short, empty, and non-hex SHAs instead of displaying them', () {
      for (final raw in ['', 'dev', 'deadbeef', 'g' * 40, '$_sha extra']) {
        final identity = BuildIdentity(gitCommitSha: raw);
        expect(identity.commitShaOrNull, isNull, reason: raw);
        expect(identity.commitLabel, 'unknown', reason: raw);
        expect(identity.commitUrl, isNull, reason: raw);
      }
    });

    test('rejects missing or non-integer build times', () {
      for (final raw in ['', '0', '-1', '12.5', 'nope', '  ']) {
        expect(BuildIdentity(buildTimeMs: raw).buildTimeLine, 'unknown', reason: raw);
      }
    });

    test('pads a zero-millisecond timestamp', () {
      final ms = DateTime.utc(2026, 10, 24, 22, 42, 2).millisecondsSinceEpoch;
      expect(formatUtcEpochMillis(ms), '2026-10-24T22:42:02.000Z');
    });
  });

  group('ReleaseBuildStamp', () {
    test('tryFromGitHead accepts rev-parse output and ignores a trailing newline', () {
      final stamp = ReleaseBuildStamp.tryFromGitHead(
        gitExitCode: 0,
        gitStdout: '$_sha\n',
        releaseTag: ' v0.9.1 ',
        buildTimeMs: builtAtMs,
      );
      expect(stamp, isNotNull);
      expect(stamp!.gitSha, _sha);
      expect(stamp.releaseTag, 'v0.9.1');
      expect(stamp.buildTimeUtc, '2026-10-24T22:42:02.123Z');
      expect(stamp.dartDefines, [
        '--dart-define=GIT_COMMIT_SHA=$_sha',
        '--dart-define=BUILD_TIME_MS=$builtAtMs',
        '--dart-define=RELEASE_TAG=v0.9.1',
      ]);
      expect(stamp.flutterArgs('web'), ['build', 'web', '--release', ...stamp.dartDefines]);
      expect(stamp.flutterArgs('apk').take(3), ['build', 'apk', '--release']);
      expect(stamp.flutterArgs('web', targetFile: 'lib/main_prod.dart', flavor: 'prod'), [
        'build',
        'web',
        '--release',
        '-t',
        'lib/main_prod.dart',
        '--dart-define=FLAVOR=prod',
        ...stamp.dartDefines,
      ]);
      expect(
        stamp.flutterArgs(
          'web',
          extraDefines: const ['--dart-define=POSTHOG_HOST=https://example.test'],
        ),
        [
          'build',
          'web',
          '--release',
          ...stamp.dartDefines,
          '--dart-define=POSTHOG_HOST=https://example.test',
        ],
      );
    });

    test('analyticsDartDefines prefers Belong env names and omits empty keys', () {
      expect(analyticsDartDefines(const {}), [
        '--dart-define=POSTHOG_HOST=https://us.i.posthog.com',
      ]);
      expect(
        analyticsDartDefines(const {
          'APTABASE_KEY': 'generic-aptabase',
          'APTABASE_BELONG_KEY': 'belong-aptabase',
          'POSTHOG_KEY': 'generic-posthog',
          'POSTHOG_BELONG_PROJECT_TOKEN': 'belong-posthog',
          'POSTHOG_HOST': 'https://eu.i.posthog.com',
        }),
        [
          '--dart-define=APTABASE_KEY=belong-aptabase',
          '--dart-define=POSTHOG_KEY=belong-posthog',
          '--dart-define=POSTHOG_HOST=https://eu.i.posthog.com',
        ],
      );
      expect(
        analyticsDartDefines(const {'APTABASE_KEY': '   ', 'POSTHOG_KEY': 'unit-test-capture-key'}),
        [
          '--dart-define=POSTHOG_KEY=unit-test-capture-key',
          '--dart-define=POSTHOG_HOST=https://us.i.posthog.com',
        ],
      );
      expect(
        analyticsDartDefinesLogLine(const {'POSTHOG_KEY': 'unit-test-capture-key'}),
        contains('POSTHOG_KEY=set'),
      );
      expect(
        analyticsDartDefinesLogLine(const {'POSTHOG_KEY': 'unit-test-capture-key'}),
        isNot(contains('unit-test-capture-key')),
      );
      expect(
        joinArgsRedactingAnalyticsDefines(const [
          'build',
          'web',
          '--dart-define=POSTHOG_KEY=unit-test-capture-key',
          '--dart-define=FLAVOR=prod',
        ]),
        'build web --dart-define=POSTHOG_KEY=<redacted> --dart-define=FLAVOR=prod',
      );
      expect(
        joinArgsRedactingAnalyticsDefines(const [
          '--dart-define=DEV_EXAMPLE_PASSWORD=unit-test-secret',
        ]),
        '--dart-define=DEV_EXAMPLE_PASSWORD=<redacted>',
      );
      expect(devExamplePasswordDartDefines(const {}), isEmpty);
      expect(devExamplePasswordDartDefines(const {'DEV_EXAMPLE_PASSWORD': 'unit-test-secret'}), [
        '--dart-define=DEV_EXAMPLE_PASSWORD=unit-test-secret',
      ]);
      expect(
        devExamplePasswordDartDefinesLogLine(const {'DEV_EXAMPLE_PASSWORD': 'unit-test-secret'}),
        allOf(contains('DEV_EXAMPLE_PASSWORD=set'), isNot(contains('unit-test-secret'))),
      );
    });

    test('tryFromGitHead returns null instead of inventing a SHA', () {
      expect(
        ReleaseBuildStamp.tryFromGitHead(
          gitExitCode: 1,
          gitStdout: _sha,
          releaseTag: 'v0.9.1',
          buildTimeMs: builtAtMs,
        ),
        isNull,
      );
      expect(
        ReleaseBuildStamp.tryFromGitHead(
          gitExitCode: 0,
          gitStdout: 'dev',
          releaseTag: 'v0.9.1',
          buildTimeMs: builtAtMs,
        ),
        isNull,
      );
      expect(
        ReleaseBuildStamp.tryFromGitHead(
          gitExitCode: 0,
          gitStdout: '',
          releaseTag: 'v0.9.1',
          buildTimeMs: builtAtMs,
        ),
        isNull,
      );
      expect(
        ReleaseBuildStamp.tryFromGitHead(
          gitExitCode: 0,
          gitStdout: _sha,
          releaseTag: '  ',
          buildTimeMs: builtAtMs,
        ),
        isNull,
      );
    });

    test('version.json carries the stamp next to the existing release fields', () {
      final stamp = ReleaseBuildStamp(gitSha: _sha, buildTimeMs: builtAtMs, releaseTag: 'v0.9.1');
      final payload = webVersionPayload(
        releaseTag: 'v0.9.1',
        pubspecVersionLine: '0.9.1+2',
        stamp: stamp,
      );
      expect(payload, {
        'app_name': 'refuge4serverpod',
        'version': '0.9.1',
        'build_number': '2',
        'package_name': 'refuge4serverpod',
        'release_tag': 'v0.9.1',
        'git_sha': _sha,
        'build_time_ms': builtAtMs,
        'build_time_utc': '2026-10-24T22:42:02.123Z',
      });
      expect(payload['build_time_ms'], isA<int>());
      final encoded = jsonEncode(payload);
      expect(encoded, contains('"build_time_ms":$builtAtMs'));
      expect(encoded, isNot(contains('"build_time_ms":"')));
      expect(
        cachedWebFlavorMismatch(versionJson: encoded, expectedFlavor: 'prod'),
        contains('missing'),
      );
      final stampedFlavor = webVersionPayload(
        releaseTag: 'v0.9.1',
        pubspecVersionLine: '0.9.1+2',
        stamp: stamp,
        flavor: 'dev',
      );
      expect(
        cachedWebFlavorMismatch(versionJson: jsonEncode(stampedFlavor), expectedFlavor: 'dev'),
        isNull,
      );
      expect(
        cachedWebFlavorMismatch(versionJson: jsonEncode(stampedFlavor), expectedFlavor: 'prod'),
        contains('expected prod'),
      );
    });

    test('release notes include the SHA and omit a URL when it is missing', () {
      final stamped = buildIdentityNotes(
        releaseTag: 'v0.9.1',
        gitSha: _sha,
        buildTimeMs: builtAtMs,
      );
      expect(stamped, contains('## Build'));
      expect(stamped, contains('- Release: v0.9.1'));
      expect(stamped, contains('- Git commit: $_sha'));
      expect(stamped, contains('- $gitCommitUrlPrefix$_sha'));
      expect(stamped, contains('- Build time: 2026-10-24T22:42:02.123Z ($builtAtMs ms)'));

      final missing = buildIdentityNotes(releaseTag: 'v0.9.1', gitSha: 'dev', buildTimeMs: null);
      expect(missing, contains('- Git commit: unknown'));
      expect(missing, contains('- Build time: unknown'));
      expect(missing, isNot(contains('/commit/')));
    });

    test('deploy_release passes the stamp into web, apk, version.json, and notes', () {
      final source = File('tool/deploy_release.dart').readAsStringSync();
      expect(source, contains('stamp.flutterArgs('));
      expect(source, contains('analyticsDartDefines(Platform.environment)'));
      expect(source, contains('joinArgsRedactingAnalyticsDefines'));
      expect(source, contains("targetFile: 'lib/main_prod.dart'"));
      expect(source, contains("flavor: 'prod'"));
      expect(source, isNot(contains('DEV_EXAMPLE_PASSWORD')));
      expect(source, isNot(contains("'--config'")));
      final devDeploy = File('tool/deploy_dev_web.dart').readAsStringSync();
      expect(devDeploy, contains('https://dev-belongonthespectrum.web.app'));
      expect(devDeploy, contains("targetFile: 'lib/main_dev.dart'"));
      expect(devDeploy, contains("flavor: 'dev'"));
      expect(devDeploy, contains('--dart-define=ENABLE_SERVERPOD=false'));
      expect(devDeploy, contains('analyticsDartDefines(Platform.environment)'));
      expect(devDeploy, contains('devExamplePasswordDartDefines(Platform.environment)'));
      expect(devDeploy, contains('joinArgsRedactingAnalyticsDefines'));
      expect(devDeploy, contains('firebase.dev.json'));
      expect(
        File('firebase.dev.json').readAsStringSync(),
        contains('"site": "dev-belongonthespectrum"'),
      );
      expect(File('firebase.json').readAsStringSync(), contains('"site": "belongonthespectrum"'));
      expect(source, contains('webVersionPayload'));
      expect(source, contains('buildIdentityNotes'));
      expect(source, contains('tryFromGitHead'));
      final deployWorkflow = File('.github/workflows/deploy.yml').readAsStringSync();
      expect(deployWorkflow, contains('secrets.APTABASE_KEY'));
      expect(deployWorkflow, contains('secrets.POSTHOG_KEY'));
      expect(deployWorkflow, contains("tags: ['v*']"));
      expect(deployWorkflow, contains('tool/deploy_dev_web.dart'));
      expect(
        deployWorkflow,
        contains(
          'Push to main deploys the dev site only. Production is a v* tag or an explicit release run.',
        ),
      );
    }, skip: kIsWeb);
  });
}
