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
      expect(
        identity.buildTimeLine,
        '2026-10-24T22:42:02.123Z ($builtAtMs ms)',
      );
      expect(identity.commitUrl, '$gitCommitUrlPrefix$_sha');
      expect(identity.releaseTagOrNull, 'v0.9.1');
      expect(identity.isLocalDevBuild, isFalse);
      expect(identity.sourceLabel, isNull);
    });

    test(
      'rejects short, empty, and non-hex SHAs instead of displaying them',
      () {
        for (final raw in ['', 'dev', 'deadbeef', 'g' * 40, '$_sha extra']) {
          final identity = BuildIdentity(gitCommitSha: raw);
          expect(identity.commitShaOrNull, isNull, reason: raw);
          expect(identity.commitLabel, 'unknown', reason: raw);
          expect(identity.commitUrl, isNull, reason: raw);
        }
      },
    );

    test('rejects missing or non-integer build times', () {
      for (final raw in ['', '0', '-1', '12.5', 'nope', '  ']) {
        expect(
          BuildIdentity(buildTimeMs: raw).buildTimeLine,
          'unknown',
          reason: raw,
        );
      }
    });

    test('pads a zero-millisecond timestamp', () {
      final ms = DateTime.utc(2026, 10, 24, 22, 42, 2).millisecondsSinceEpoch;
      expect(formatUtcEpochMillis(ms), '2026-10-24T22:42:02.000Z');
    });
  });

  group('ReleaseBuildStamp', () {
    test(
      'tryFromGitHead accepts rev-parse output and ignores a trailing newline',
      () {
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
        expect(stamp.flutterArgs('web'), [
          'build',
          'web',
          '--release',
          ...stamp.dartDefines,
        ]);
        expect(stamp.flutterArgs('apk').take(3), ['build', 'apk', '--release']);
      },
    );

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

    test(
      'version.json carries the stamp next to the existing release fields',
      () {
        final stamp = ReleaseBuildStamp(
          gitSha: _sha,
          buildTimeMs: builtAtMs,
          releaseTag: 'v0.9.1',
        );
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
      },
    );

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
      expect(
        stamped,
        contains('- Build time: 2026-10-24T22:42:02.123Z ($builtAtMs ms)'),
      );

      final missing = buildIdentityNotes(
        releaseTag: 'v0.9.1',
        gitSha: 'dev',
        buildTimeMs: null,
      );
      expect(missing, contains('- Git commit: unknown'));
      expect(missing, contains('- Build time: unknown'));
      expect(missing, isNot(contains('/commit/')));
    });

    test(
      'deploy_release passes the stamp into web, apk, version.json, and notes',
      () {
        final source = File('tool/deploy_release.dart').readAsStringSync();
        expect(source, contains("stamp.flutterArgs('web')"));
        expect(source, contains("stamp.flutterArgs('apk')"));
        expect(source, contains('webVersionPayload'));
        expect(source, contains('buildIdentityNotes'));
        expect(source, contains('tryFromGitHead'));
      },
      skip: kIsWeb,
    );
  });
}
