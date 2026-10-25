import 'dart:convert';

import 'build_identity.dart';

/// Stamp resolved by `tool/deploy_release.dart` before `flutter build`.
///
/// The same object is passed as dart-defines, written into `version.json`,
/// and copied into release notes. Callers must use [tryFromGitHead] so a
/// missing or short SHA becomes null instead of a placeholder.
class ReleaseBuildStamp {
  const ReleaseBuildStamp({
    required this.gitSha,
    required this.buildTimeMs,
    required this.releaseTag,
  });

  final String gitSha;
  final int buildTimeMs;
  final String releaseTag;

  /// Null unless [gitStdout] is a full SHA, [gitExitCode] is 0, [releaseTag]
  /// is non-empty, and [buildTimeMs] is positive.
  static ReleaseBuildStamp? tryFromGitHead({
    required int gitExitCode,
    required String gitStdout,
    required String releaseTag,
    required int buildTimeMs,
  }) {
    if (gitExitCode != 0) return null;
    final sha = fullGitShaOrNull(gitStdout);
    if (sha == null) return null;
    final tag = releaseTag.trim();
    if (tag.isEmpty || buildTimeMs <= 0) return null;
    return ReleaseBuildStamp(
      gitSha: sha,
      buildTimeMs: buildTimeMs,
      releaseTag: tag,
    );
  }

  String get buildTimeUtc => formatUtcEpochMillis(buildTimeMs);

  List<String> get dartDefines => [
    '--dart-define=$gitCommitShaDefine=$gitSha',
    '--dart-define=$buildTimeMsDefine=$buildTimeMs',
    '--dart-define=$releaseTagDefine=$releaseTag',
  ];

  /// Arguments after the `flutter` executable for `flutter build <target>`.
  ///
  /// [targetFile] is the Flutter `-t` entrypoint (`lib/main_prod.dart` or
  /// `lib/main_dev.dart`). [flavor] is passed as `--dart-define=FLAVOR=`.
  /// Omit both only for callers that intentionally keep the default `main.dart`
  /// entrypoint (which resolves to `dev` unless `FLAVOR` is set).
  ///
  /// [extraDefines] is for compile-time keys that come from the process
  /// environment (`analyticsDartDefines`). Callers must redact those values
  /// before printing the argument list.
  List<String> flutterArgs(
    String target, {
    String? targetFile,
    String? flavor,
    List<String> extraDefines = const [],
  }) => [
    'build',
    target,
    '--release',
    if (targetFile != null) ...['-t', targetFile],
    if (flavor != null) '--dart-define=FLAVOR=$flavor',
    ...dartDefines,
    ...extraDefines,
  ];
}

const _defaultPostHogHost = 'https://us.i.posthog.com';

const _analyticsDartDefineNames = [
  'APTABASE_KEY',
  'APTABASE_BELONG_KEY',
  'POSTHOG_KEY',
  'POSTHOG_BELONG_PROJECT_TOKEN',
];

String? _firstNonEmptyEnv(Map<String, String> environment, List<String> names) {
  for (final name in names) {
    final value = environment[name]?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// Compile-time analytics keys from the process environment.
///
/// Prefers Belong-specific names (`APTABASE_BELONG_KEY`,
/// `POSTHOG_BELONG_PROJECT_TOKEN`) so a generic key in the same shell cannot
/// silently point a Belong build at another project. Empty values are omitted
/// so open-source and CI builds without secrets stay in mock mode.
///
/// Never log the returned `--dart-define` values. Use
/// [joinArgsRedactingAnalyticsDefines] or [analyticsDartDefinesLogLine].
List<String> analyticsDartDefines(Map<String, String> environment) {
  final defines = <String>[];
  final aptabase = _firstNonEmptyEnv(environment, const [
    'APTABASE_BELONG_KEY',
    'APTABASE_KEY',
  ]);
  if (aptabase != null) {
    defines.add('--dart-define=APTABASE_KEY=$aptabase');
  }
  final posthog = _firstNonEmptyEnv(environment, const [
    'POSTHOG_BELONG_PROJECT_TOKEN',
    'POSTHOG_KEY',
  ]);
  if (posthog != null) {
    defines.add('--dart-define=POSTHOG_KEY=$posthog');
  }
  final host =
      _firstNonEmptyEnv(environment, const ['POSTHOG_HOST']) ??
      _defaultPostHogHost;
  defines.add('--dart-define=POSTHOG_HOST=$host');
  return defines;
}

/// Presence-only log line. Does not include secret values.
String analyticsDartDefinesLogLine(Map<String, String> environment) {
  final defines = analyticsDartDefines(environment);
  final aptabase = defines.any(
    (define) => define.startsWith('--dart-define=APTABASE_KEY='),
  );
  final posthog = defines.any(
    (define) => define.startsWith('--dart-define=POSTHOG_KEY='),
  );
  return 'Analytics dart-defines: '
      'APTABASE_KEY=${aptabase ? 'set' : 'missing'} '
      'POSTHOG_KEY=${posthog ? 'set' : 'missing'} '
      '(empty keys stay in mock mode; see #410)';
}

/// Replaces analytics dart-define values so failure logs cannot leak tokens.
String redactAnalyticsDartDefine(String arg) {
  for (final name in _analyticsDartDefineNames) {
    final prefix = '--dart-define=$name=';
    if (arg.startsWith(prefix) && arg.length > prefix.length) {
      return '$prefix<redacted>';
    }
  }
  return arg;
}

/// Joins process args after scrubbing analytics `--dart-define` values.
String joinArgsRedactingAnalyticsDefines(List<String> args) =>
    args.map(redactAnalyticsDartDefine).join(' ');

/// `build/web/version.json` body. Existing keys stay as they are today;
/// [ReleaseBuildStamp] adds `git_sha`, `build_time_ms`, and `build_time_utc`.
Map<String, Object> webVersionPayload({
  required String releaseTag,
  required String? pubspecVersionLine,
  required ReleaseBuildStamp stamp,
  String? flavor,
}) {
  final line = pubspecVersionLine?.trim() ?? '';
  final buildNumber = line.contains('+') ? line.split('+').last : '0';
  final tagVersion = releaseTag.startsWith('v')
      ? releaseTag.substring(1)
      : releaseTag;
  return {
    'app_name': 'refuge4serverpod',
    'version': tagVersion,
    'build_number': buildNumber,
    'package_name': 'refuge4serverpod',
    'release_tag': releaseTag,
    'git_sha': stamp.gitSha,
    'build_time_ms': stamp.buildTimeMs,
    'build_time_utc': stamp.buildTimeUtc,
    if (flavor != null) 'flavor': flavor,
  };
}

/// Null when [versionJson] records [expectedFlavor]. Otherwise a reason to
/// refuse `--skip-build`, so a prod bundle cannot be published to the dev
/// site or the reverse.
String? cachedWebFlavorMismatch({
  required String? versionJson,
  required String expectedFlavor,
}) {
  if (versionJson == null || versionJson.trim().isEmpty) {
    return 'build/web/version.json is missing. Rebuild without --skip-build.';
  }
  try {
    final decoded = jsonDecode(versionJson);
    final found = decoded is Map ? decoded['flavor'] : null;
    if (found == expectedFlavor) return null;
    return 'Cached web bundle flavor is ${found ?? 'missing'}, '
        'expected $expectedFlavor. Refusing --skip-build.';
  } on FormatException {
    return 'build/web/version.json is not valid JSON. '
        'Rebuild without --skip-build.';
  }
}

/// Markdown section for release notes. A missing or invalid SHA is written as
/// `unknown` and is not turned into a commit URL.
String buildIdentityNotes({
  required String releaseTag,
  String? gitSha,
  int? buildTimeMs,
}) {
  final sha = gitSha == null ? null : fullGitShaOrNull(gitSha);
  final buffer = StringBuffer()
    ..writeln('## Build')
    ..writeln('- Release: $releaseTag');
  if (sha == null) {
    buffer.writeln('- Git commit: unknown');
  } else {
    buffer
      ..writeln('- Git commit: $sha')
      ..writeln('- $gitCommitUrlPrefix$sha');
  }
  if (buildTimeMs == null || buildTimeMs <= 0) {
    buffer.writeln('- Build time: unknown');
  } else {
    buffer.writeln(
      '- Build time: ${formatUtcEpochMillis(buildTimeMs)} ($buildTimeMs ms)',
    );
  }
  return buffer.toString();
}
