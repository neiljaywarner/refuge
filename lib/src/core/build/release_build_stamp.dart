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
  List<String> flutterArgs(
    String target, {
    String? targetFile,
    String? flavor,
  }) => [
    'build',
    target,
    '--release',
    if (targetFile != null) ...['-t', targetFile],
    if (flavor != null) '--dart-define=FLAVOR=$flavor',
    ...dartDefines,
  ];
}

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
