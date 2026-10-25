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
  List<String> flutterArgs(String target) => [
    'build',
    target,
    '--release',
    ...dartDefines,
  ];
}

/// `build/web/version.json` body. Existing keys stay as they are today;
/// [ReleaseBuildStamp] adds `git_sha`, `build_time_ms`, and `build_time_utc`.
Map<String, Object> webVersionPayload({
  required String releaseTag,
  required String? pubspecVersionLine,
  required ReleaseBuildStamp stamp,
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
  };
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
