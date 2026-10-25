/// Compile-time identity of the running binary.
///
/// Release builds pass these `--dart-define` names from `tool/deploy_release.dart`:
/// [gitCommitShaDefine], [buildTimeMsDefine], and [releaseTagDefine].
/// A local `flutter run` leaves them empty. Empty defines stay empty — this
/// type never substitutes a made-up commit SHA.
const gitCommitShaDefine = 'GIT_COMMIT_SHA';
const buildTimeMsDefine = 'BUILD_TIME_MS';
const releaseTagDefine = 'RELEASE_TAG';

/// `https://github.com/neiljaywarner/refuge/commit/<sha>`.
const gitCommitUrlPrefix = 'https://github.com/neiljaywarner/refuge/commit/';

final RegExp _fullGitSha = RegExp(r'^[0-9a-f]{40}$');
final RegExp _epochMillis = RegExp(r'^[1-9]\d{0,12}$');

/// Lowercase 40-hex commit, or null when [raw] is not exactly one full SHA.
///
/// Trailing newlines are ignored so `git rev-parse HEAD` output can be passed
/// through. Short SHAs, branch names, and the word `dev` are rejected.
String? fullGitShaOrNull(String raw) {
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length != 1) return null;
  final sha = lines.single.toLowerCase();
  if (!_fullGitSha.hasMatch(sha)) return null;
  return sha;
}

/// Positive Unix epoch milliseconds, or null when [raw] is missing or not a
/// plain integer (no sign, no fraction, at most 13 digits).
int? epochMillisOrNull(String raw) {
  final trimmed = raw.trim();
  if (!_epochMillis.hasMatch(trimmed)) return null;
  return int.tryParse(trimmed);
}

/// ISO-8601 UTC with millisecond precision, for example
/// `2026-10-24T22:42:02.123Z`.
String formatUtcEpochMillis(int epochMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
  String two(int n) => n.toString().padLeft(2, '0');
  String three(int n) => n.toString().padLeft(3, '0');
  final year = dt.year.toString().padLeft(4, '0');
  return '$year-${two(dt.month)}-${two(dt.day)}'
      'T${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}.'
      '${three(dt.millisecond)}Z';
}

/// Values baked in with `--dart-define` at compile time.
class BuildIdentity {
  const BuildIdentity({this.gitCommitSha = '', this.buildTimeMs = '', this.releaseTag = ''});

  /// Identity of this binary. Empty when the defines were not passed.
  static const fromEnvironment = BuildIdentity(
    gitCommitSha: String.fromEnvironment(gitCommitShaDefine),
    buildTimeMs: String.fromEnvironment(buildTimeMsDefine),
    releaseTag: String.fromEnvironment(releaseTagDefine),
  );

  final String gitCommitSha;
  final String buildTimeMs;
  final String releaseTag;

  /// Full lowercase SHA, or null when the define is missing or not a full SHA.
  String? get commitShaOrNull => fullGitShaOrNull(gitCommitSha);

  /// SHA suitable for display. `unknown` when [commitShaOrNull] is null.
  String get commitLabel => commitShaOrNull ?? 'unknown';

  int? get buildTimeEpochMs => epochMillisOrNull(buildTimeMs);

  /// ISO-8601 UTC, or `unknown` when [buildTimeMs] is missing or invalid.
  String get buildTimeUtcLabel {
    final ms = buildTimeEpochMs;
    if (ms == null) return 'unknown';
    return formatUtcEpochMillis(ms);
  }

  /// `2026-10-24T22:42:02.123Z (1761345722123 ms)`, or `unknown`.
  String get buildTimeLine {
    final ms = buildTimeEpochMs;
    if (ms == null) return 'unknown';
    return '${formatUtcEpochMillis(ms)} ($ms ms)';
  }

  String? get commitUrl {
    final sha = commitShaOrNull;
    if (sha == null) return null;
    return '$gitCommitUrlPrefix$sha';
  }

  String? get releaseTagOrNull {
    final tag = releaseTag.trim();
    if (tag.isEmpty) return null;
    return tag;
  }

  /// True for a normal local `flutter run` that passed none of the defines.
  bool get isLocalDevBuild =>
      gitCommitSha.trim().isEmpty && buildTimeMs.trim().isEmpty && releaseTag.trim().isEmpty;

  /// `dev` for an unstamped local binary. Null when any define was supplied.
  String? get sourceLabel => isLocalDevBuild ? 'dev' : null;
}
