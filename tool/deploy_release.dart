import 'dart:io';

/// Pure-Dart Deployment & Release Notes CLI for Belong on the Spectrum.
///
/// Builds the Flutter Web release bundle, generates structured human +
/// neurodivergent-friendly release notes (`build/RELEASE_NOTES_<version>.md`),
/// deploys to a Firebase Hosting Preview Channel, optionally deploys to live
/// production (`https://belongonthespectrum.web.app`), and publishes a GitHub
/// Release.
///
/// Usage:
///   `/opt/homebrew/bin/dart run tool/deploy_release.dart --version v0.8.0-alpha --channel v0-8-0-alpha --prod --github-release`
Future<void> main(List<String> args) async {
  final version = _argValue(args, '--version') ?? 'v0.6.0-alpha';
  final channel =
      _argValue(args, '--channel') ??
      version.replaceAll('.', '-').replaceAll('_', '-');
  final deployProd = args.contains('--prod');
  final createGhRelease = args.contains('--github-release');
  final skipBuild = args.contains('--skip-build');
  final dryRun = args.contains('--dry-run');

  stdout.writeln('==========================================================');
  stdout.writeln('🚀 Belong on the Spectrum — Release & Deployment Pipeline');
  stdout.writeln('   Version        : $version');
  stdout.writeln('   Preview Channel: $channel');
  stdout.writeln('   Deploy Prod    : $deployProd (https://belongonthespectrum.web.app)');
  stdout.writeln('   GitHub Release : $createGhRelease');
  stdout.writeln('   Dry Run        : $dryRun');
  stdout.writeln('==========================================================');

  // 1. Generate structured Release Notes
  final notesFile = await _generateReleaseNotes(version);
  stdout.writeln('==> 1. Generated Release Notes: ${notesFile.path}');

  if (dryRun) {
    stdout.writeln('==> [Dry-Run] Release notes contents:\n');
    stdout.writeln(await notesFile.readAsString());
    return;
  }

  // 2. Build Flutter Web release bundle
  if (!skipBuild) {
    stdout.writeln('==> 2. Building Flutter Web Release Bundle (lib/main.dart)...');
    await _run('/opt/homebrew/bin/flutter', [
      'build',
      'web',
      '--release',
    ]);
  }

  // 3. Deploy to Firebase Hosting Preview Channel
  stdout.writeln('==> 3. Deploying to Firebase Hosting Preview Channel "$channel"...');
  await _run('/opt/homebrew/bin/firebase', [
    'hosting:channel:deploy',
    channel,
    '--project',
    'belongonthespectrum',
    '--expires',
    '14d',
  ]);

  // 4. Deploy to Live Production (https://belongonthespectrum.web.app)
  if (deployProd) {
    stdout.writeln(
      '==> 4. Deploying to Live Production (https://belongonthespectrum.web.app)...',
    );
    await _run('/opt/homebrew/bin/firebase', [
      'deploy',
      '--only',
      'hosting',
      '--project',
      'belongonthespectrum',
      '--message',
      'Release $version — Belong on the Spectrum',
    ]);
  }

  // 5. Create or update GitHub Release with structured notes
  if (createGhRelease) {
    stdout.writeln('==> 5. Publishing GitHub Release $version...');
    final existing = await Process.run('/opt/homebrew/bin/gh', [
      'release',
      'view',
      version,
      '--repo',
      'neiljaywarner/refuge',
    ]);
    if (existing.exitCode == 0) {
      await _run('/opt/homebrew/bin/gh', [
        'release',
        'edit',
        version,
        '--repo',
        'neiljaywarner/refuge',
        '--title',
        '$version — Belong on the Spectrum Community Alpha',
        '--notes-file',
        notesFile.path,
      ]);
    } else {
      await _run('/opt/homebrew/bin/gh', [
        'release',
        'create',
        version,
        '--repo',
        'neiljaywarner/refuge',
        '--title',
        '$version — Belong on the Spectrum Community Alpha',
        '--notes-file',
        notesFile.path,
        '--prerelease',
      ]);
    }
  }

  stdout.writeln('🎉 Release $version complete! Live at https://belongonthespectrum.web.app');
}

String? _argValue(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx != -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  for (final arg in args) {
    if (arg.startsWith('$flag=')) {
      return arg.substring(flag.length + 1);
    }
  }
  return null;
}

Future<File> _generateReleaseNotes(String version) async {
  final gitLog = await Process.run('git', [
    'log',
    '-n',
    '10',
    '--oneline',
    '--no-decorate',
  ]);
  final commits = (gitLog.stdout as String).trim();
  final now = DateTime.now().toUtc().toIso8601String();

  final notes = '''
# 🌿 Belong on the Spectrum — Release `$version`

* **Published**: `$now`
* **Live Production Web / PWA**: https://belongonthespectrum.web.app
* **Partner Community**: [DFW Church](https://dfwchurch.org) & [Belong on the Spectrum](https://www.belongonthespectrum.com/)
* **Audio MP3 Summary (`week1` Issue #59)**: *Coming in Week 1 — "Listen to What's New in 60 Seconds"*

---

## 💚 What's New for Community Members (Calm, Plain-Language Summary)
1. **Circle-Parity Home & Spaces Navigation**: Browse `PINNED`, `WELCOME`, `COMMUNITY`, `ACTUALLY AUTISTIC`, and `LINKS` spaces with calm, sensory-safe colors and zero visual clutter.
2. **Literal 3-Intent Feedback & 1-Tap Feature Voting (`ADR-0007`)**: Tap **"Feedback & Vote"** in the top bar to share praise (💚 *Works Great*), ideas (💡 *Idea / Tweak*), or private bug reports (🛠️ *Bug / Confusing*), and upvote upcoming community features with 1 tap.
3. **Frictionless Community Sign-In & Member Profile (`v0.8.0-alpha`)**: Sign in with your display name and email, customize your self-identification badge, and post directly to community spaces.
4. **Direct Messages (`Msgs`), Calm Notification Bell & Actually Autistic Events Calendar**: RSVP to sensory-friendly events and toggle batched notification digests.

## 🛠️ What's New for Organizers & Engineers
- **Live Organizer Banner (`OrganizerRemoteConfigService`)**: Update the pinned community announcement banner via Firebase Remote Config without redeploying code.
- **Clean Backend Adapter Architecture (`ADR-0009`)**: Pluggable `InMemory`, `Serverpod`, `Appwrite`, and `Firebase` repository adapters tested across Unit, Widget BDD (`patrolWidgetTest`), Integration, and Maestro E2E layers.
- **Circle.so CSV Migration Tooling (`tool/import_circle_csv.dart`)**: Ready for the October 24 overlap window and October 31 Circle.so cutover.

## 📜 Recent Commits Included
```text
$commits
```
''';

  final dir = Directory('build');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final file = File('build/RELEASE_NOTES_$version.md');
  await file.writeAsString(notes);
  return file;
}

Future<void> _run(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  final out = (result.stdout as String).trim();
  final err = (result.stderr as String).trim();
  if (out.isNotEmpty) stdout.writeln(out);
  if (err.isNotEmpty) stderr.writeln(err);
  if (result.exitCode != 0) {
    stderr.writeln('Command failed ($executable ${args.join(' ')}): exit ${result.exitCode}');
    exit(result.exitCode);
  }
}
