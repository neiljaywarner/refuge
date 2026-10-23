/// # Belong on the Spectrum release pipeline (`tool/deploy_release.dart`)
///
/// One command that ships a release to every channel with the **same**
/// honest, plain-language release notes:
///
/// 1. Builds Flutter Web (and, with `--distribute-android`, a release APK).
/// 2. Deploys a Firebase Hosting **preview channel** and captures its URL.
/// 3. Generates `build/RELEASE_NOTES_<version>.md` from merged PR titles since
///    the previous tag, plus optional hand-written highlights.
/// 4. Optionally deploys production (`https://belongonthespectrum.web.app`).
/// 5. Optionally creates/updates the GitHub Release.
/// 6. Optionally uploads the APK to Firebase App Distribution for a tester
///    group (default `pre-alpha-testers`). Firebase emails the release notes,
///    which include the web preview link, so testers get Android + Web at once.
///
/// ## Usage
///
/// ```bash
/// dart run tool/deploy_release.dart --version v0.7.0 --prod --github-release
/// dart run tool/deploy_release.dart --version v0.8.0-alpha --prod \
///   --github-release --distribute-android \
///   --highlights-file docs/release_highlights/v0.8.0-alpha.md
/// dart run tool/deploy_release.dart --version v0.7.0 --dry-run
/// ```
///
/// ## Flags
///
/// | Flag | Default | Meaning |
/// | --- | --- | --- |
/// | `--version` | required | Tag / release name, e.g. `v0.7.0` |
/// | `--channel` | version with dots→dashes | Hosting preview channel id |
/// | `--prod` | off | Also deploy live production |
/// | `--github-release` | off | Create or edit the GitHub Release |
/// | `--distribute-android` | off | Build APK + upload to App Distribution |
/// | `--android-app-id` | `$FIREBASE_ANDROID_APP_ID` or auto-detect | Firebase Android app id |
/// | `--groups` | `pre-alpha-testers` | App Distribution group alias(es) |
/// | `--highlights-file` | none | Markdown prepended under "Highlights" |
/// | `--attach` | none (repeatable) | File paths (images/videos) to upload to GitHub Release |
/// | `--skip-build` | off | Reuse existing `build/web` / APK |
/// | `--dry-run` | off | Print notes only; build/deploy nothing |
///
/// Tester emails are **never** stored here (public repo). They live only in
/// the App Distribution group in the Firebase console.
library;

import 'dart:convert';
import 'dart:io';

const _project = 'belongonthespectrum';
const _repo = 'neiljaywarner/refuge';
const _prodUrl = 'https://belongonthespectrum.web.app';

/// Resolves a tool from `$<NAME>_BIN` or falls back to PATH.
String _bin(String name) =>
    Platform.environment['${name.toUpperCase()}_BIN'] ?? name;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('See the library doc at the top of tool/deploy_release.dart '
        'or DEPLOYMENT.md.');
    return;
  }
  final version = _arg(args, '--version');
  if (version == null) {
    stderr.writeln('--version is required (e.g. --version v0.7.0)');
    exit(64);
  }
  final channel = _arg(args, '--channel') ?? version.replaceAll('.', '-');
  final prod = args.contains('--prod');
  final ghRelease = args.contains('--github-release');
  final android = args.contains('--distribute-android');
  final groups = _arg(args, '--groups') ?? 'pre-alpha-testers';
  final highlightsPath = _arg(args, '--highlights-file');
  final skipBuild = args.contains('--skip-build');
  final dryRun = args.contains('--dry-run');
  final attachments = _argsAll(args, '--attach');

  _log('Release $version | channel=$channel prod=$prod gh=$ghRelease '
      'android=$android groups=$groups attachments=${attachments.length} dryRun=$dryRun');

  if (dryRun) {
    final notes = await _writeNotes(version, previewUrl: '(preview URL)',
        highlightsPath: highlightsPath, android: android);
    stdout.writeln(await notes.readAsString());
    return;
  }

  // Resolve the Android app id early so we fail fast before deploying anything.
  String? androidAppId;
  if (android) {
    androidAppId = _arg(args, '--android-app-id') ??
        Platform.environment['FIREBASE_ANDROID_APP_ID'] ??
        await _detectAndroidAppId();
    if (androidAppId == null) {
      stderr.writeln('No Firebase Android app found. Pass --android-app-id.');
      exit(65);
    }
  }

  if (!skipBuild) {
    _log('Building Flutter Web...');
    await _run(_bin('flutter'), ['build', 'web', '--release']);
    await _writeWebVersionJson(version);
    if (android) {
      _log('Building release APK...');
      await _run(_bin('flutter'), ['build', 'apk', '--release']);
    }
  }

  _log('Deploying preview channel "$channel"...');
  final previewOut = await _run(_bin('firebase'), [
    'hosting:channel:deploy', channel, '--project', _project,
    '--expires', '14d', '--json',
  ]);
  final previewUrl = _extractPreviewUrl(previewOut) ?? '(see Firebase console)';
  _log('Preview: $previewUrl');

  final notes = await _writeNotes(version, previewUrl: previewUrl,
      highlightsPath: highlightsPath, android: android);
  _log('Release notes: ${notes.path}');

  if (prod) {
    _log('Deploying production $_prodUrl ...');
    await _run(_bin('firebase'), [
      'deploy', '--only', 'hosting', '--project', _project,
      '--message', 'Release $version',
    ]);
  }

  if (ghRelease) {
    _log('Publishing GitHub Release $version ...');
    final exists = await Process.run(
        _bin('gh'), ['release', 'view', version, '--repo', _repo]);
    await _run(_bin('gh'), [
      'release', exists.exitCode == 0 ? 'edit' : 'create', version,
      '--repo', _repo, '--title', '$version: Belong on the Spectrum',
      '--notes-file', notes.path,
      if (exists.exitCode != 0) '--prerelease',
    ]);
    if (attachments.isNotEmpty) {
      final validFiles = attachments.where((p) => File(p).existsSync()).toList();
      if (validFiles.isNotEmpty) {
        _log('Uploading ${validFiles.length} release asset(s) to GitHub Release $version ...');
        await _run(_bin('gh'), [
          'release', 'upload', version, ...validFiles,
          '--repo', _repo, '--clobber',
        ]);
      }
    }
  }

  if (android) {
    _log('Uploading APK to App Distribution (groups: $groups)...');
    await _run(_bin('firebase'), [
      'appdistribution:distribute',
      'build/app/outputs/flutter-apk/app-release.apk',
      '--app', androidAppId!, '--groups', groups,
      '--release-notes-file', notes.path, '--project', _project,
    ]);
  }

  _log('Done. Web: $_prodUrl | Preview: $previewUrl');
}

String? _arg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i != -1 && i + 1 < args.length) return args[i + 1];
  for (final a in args) {
    if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
  }
  return null;
}

List<String> _argsAll(List<String> args, String flag) {
  final result = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == flag && i + 1 < args.length) {
      result.add(args[i + 1]);
      i++;
    } else if (args[i].startsWith('$flag=')) {
      result.add(args[i].substring(flag.length + 1));
    }
  }
  return result;
}

void _log(String m) =>
    stdout.writeln('[${DateTime.now().toIso8601String().substring(11, 19)}] $m');

Future<String?> _detectAndroidAppId() async {
  final r = await Process.run(
      _bin('firebase'), ['apps:list', 'ANDROID', '--project', _project, '--json']);
  if (r.exitCode != 0) return null;
  final match = RegExp(r'"appId"\s*:\s*"([^"]+:android:[^"]+)"')
      .firstMatch(r.stdout as String);
  return match?.group(1);
}

String? _extractPreviewUrl(String jsonOut) {
  final m = RegExp(r'"url"\s*:\s*"(https://[^"]+)"').firstMatch(jsonOut);
  return m?.group(1);
}

/// Merged PR titles since the previous tag, newest first.
Future<List<String>> _changesSinceLastTag() async {
  final tag = await Process.run('git', ['describe', '--tags', '--abbrev=0', 'HEAD^']);
  final range = tag.exitCode == 0 ? '${(tag.stdout as String).trim()}..HEAD' : 'HEAD~15..HEAD';
  final log = await Process.run('git', ['log', range, '--no-merges', '--pretty=%s']);
  return (log.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

/// Writes `build/web/version.json` so hosting and smoke tests expose the
/// deployed release tag (not only the pubspec default).
Future<void> _writeWebVersionJson(String version) async {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionLine = RegExp(r'^version:\s*(.+)$', multiLine: true)
      .firstMatch(pubspec)
      ?.group(1)
      ?.trim();
  final buildNumber = versionLine?.contains('+') == true
      ? versionLine!.split('+').last
      : '0';
  final tagVersion = version.startsWith('v') ? version.substring(1) : version;
  final payload = {
    'app_name': 'refuge4serverpod',
    'version': tagVersion,
    'build_number': buildNumber,
    'package_name': 'refuge4serverpod',
    'release_tag': version,
  };
  final out = File('build/web/version.json');
  if (!out.parent.existsSync()) {
    await out.parent.create(recursive: true);
  }
  await out.writeAsString('${jsonEncode(payload)}\n');
  _log('Wrote ${out.path} ($tagVersion+$buildNumber)');
}

Future<File> _writeNotes(String version,
    {required String previewUrl, String? highlightsPath, required bool android}) async {
  final changes = await _changesSinceLastTag();
  final highlights = highlightsPath != null && File(highlightsPath).existsSync()
      ? File(highlightsPath).readAsStringSync().trim()
      : null;
  final b = StringBuffer()
    ..writeln('# Belong on the Spectrum $version')
    ..writeln()
    ..writeln('Thank you for testing! 💚 This is an early pre-alpha build.')
    ..writeln()
    ..writeln('## How to try it')
    ..writeln('- **Web / PWA (any phone or computer):** $_prodUrl')
    ..writeln('- **This exact build (preview link):** $previewUrl')
    ..writeln(android
        ? '- **Android:** install from the Firebase App Distribution email or app.'
        : '- **Android app:** coming soon. Use the web link and "Add to Home Screen".')
    ..writeln();
  if (highlights != null) {
    b
      ..writeln('## Highlights')
      ..writeln(highlights)
      ..writeln();
  }
  b
    ..writeln('## Changes in this release')
    ..writeAll(changes.map((c) => '- $c\n'))
    ..writeln()
    ..writeln('## Feedback')
    ..writeln('Tap **Feedback & Vote** in the top bar: 💚 works great, '
        '💡 idea, or 🛠️ bug/confusing. Private notes go only to organizers.')
    ..writeln()
    ..writeln('Full history: https://github.com/$_repo/releases');
  await Directory('build').create(recursive: true);
  final f = File('build/RELEASE_NOTES_$version.md');
  await f.writeAsString(b.toString());
  return f;
}

Future<String> _run(String exe, List<String> args) async {
  final r = await Process.run(exe, args);
  final out = (r.stdout as String).trim();
  final err = (r.stderr as String).trim();
  if (out.isNotEmpty) stdout.writeln(out);
  if (err.isNotEmpty) stderr.writeln(err);
  if (r.exitCode != 0) {
    stderr.writeln('FAILED (${r.exitCode}): $exe ${args.join(' ')}');
    exit(r.exitCode);
  }
  return out;
}
