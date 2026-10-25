/// Deploys the stable **dev** web app to
/// `https://dev-belongonthespectrum.web.app`.
///
/// This is not a production release. It does not deploy
/// `belongonthespectrum.web.app`, a preview channel, or a GitHub Release.
///
/// The dev Hosting site is a long-lived place to open the `dev` flavor
/// (Android's `.dev` application id, web's `dev-` site prefix). Release
/// candidates still go out through `tool/deploy_release.dart` as prod-flavor
/// preview channels.
///
/// Both sites live in the one Firebase project `belongonthespectrum`.
/// Auth and Firestore are shared. The app keeps dev posts in
/// `reflections_dev` instead of `reflections`. A second Firebase project
/// would be a later step if dev must not share Auth users with prod.
/// `stg` and `qa` are not deployed.
///
/// ## One-time setup (after `firebase login`)
///
/// ```bash
/// dart run tool/deploy_dev_web.dart --create-site
/// ```
///
/// That runs `firebase hosting:sites:create dev-belongonthespectrum`.
/// The site id has to exist before the first deploy. As of this change the
/// public URL returns Firebase's "Site Not Found" page until that succeeds.
///
/// ## Deploy
///
/// ```bash
/// dart run tool/deploy_dev_web.dart --dry-run
/// dart run tool/deploy_dev_web.dart
/// dart run tool/deploy_dev_web.dart --skip-build
/// dart run tool/deploy_dev_web.dart --build-android
/// dart run tool/deploy_dev_web.dart --build-android --distribute-android
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:refuge4serverpod/src/core/build/release_build_stamp.dart';

import 'firebase_test_lab_support.dart';

const _project = 'belongonthespectrum';
const _siteId = 'dev-belongonthespectrum';
const _devUrl = 'https://dev-belongonthespectrum.web.app';
const _defaultTesterGroups = 'pre-alpha-testers';

String _bin(String name) => Platform.environment['${name.toUpperCase()}_BIN'] ?? name;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('See the library doc at the top of tool/deploy_dev_web.dart.');
    return;
  }
  if (args.contains('--prod')) {
    stderr.writeln(
      '--prod belongs to tool/deploy_release.dart. '
      'This command only deploys $_devUrl.',
    );
    exit(64);
  }

  final dryRun = args.contains('--dry-run');
  final skipBuild = args.contains('--skip-build');
  final createSite = args.contains('--create-site');
  final buildAndroid = args.contains('--build-android');
  final distributeAndroid = args.contains('--distribute-android');
  final version = _arg(args, '--version') ?? 'dev';
  final groups = _arg(args, '--groups') ?? _defaultTesterGroups;

  final git = await Process.run('git', ['rev-parse', 'HEAD']);
  final stamp = ReleaseBuildStamp.tryFromGitHead(
    gitExitCode: git.exitCode,
    gitStdout: git.stdout?.toString() ?? '',
    releaseTag: version,
    buildTimeMs: DateTime.now().toUtc().millisecondsSinceEpoch,
  );
  if (stamp == null) {
    stderr.writeln('Could not resolve a full git SHA. Refusing to invent one.');
    exit(65);
  }

  stdout.writeln(
    'Dev web $_devUrl | tag=$version sha=${stamp.gitSha} '
    'createSite=$createSite skipBuild=$skipBuild buildAndroid=$buildAndroid '
    'distributeAndroid=$distributeAndroid dryRun=$dryRun',
  );

  if (createSite) {
    await _run(_bin('firebase'), [
      'hosting:sites:create',
      _siteId,
      '--project',
      _project,
    ], dryRun: dryRun);
  }

  final analyticsDefines = analyticsDartDefines(Platform.environment);
  stdout.writeln(analyticsDartDefinesLogLine(Platform.environment));
  stdout.writeln(devExamplePasswordDartDefinesLogLine(Platform.environment));
  final extraDefines = [
    ...analyticsDefines,
    ...devExamplePasswordDartDefines(Platform.environment),
  ];

  if (skipBuild) {
    final cached = File('build/web/version.json');
    final mismatch = cachedWebFlavorMismatch(
      versionJson: cached.existsSync() ? cached.readAsStringSync() : null,
      expectedFlavor: 'dev',
    );
    if (mismatch != null) {
      stderr.writeln(mismatch);
      exit(65);
    }
  } else {
    // Dev and prod share one Firebase project and one Serverpod host.
    // The public dev site must stay on the local post repository so a
    // visitor cannot publish into the live community.
    await _run(_bin('flutter'), [
      ...stamp.flutterArgs(
        'web',
        targetFile: 'lib/main_dev.dart',
        flavor: 'dev',
        extraDefines: extraDefines,
      ),
      '--dart-define=ENABLE_SERVERPOD=false',
    ], dryRun: dryRun);
    if (!dryRun) {
      await _writeWebVersionJson(version, stamp);
    }
  }

  if (buildAndroid && !skipBuild) {
    stdout.writeln('Building release dev APK...');
    await _run(
      _bin('flutter'),
      devReleaseFlutterApkBuildArgs(stamp: stamp, extraDefines: extraDefines),
      dryRun: dryRun,
    );
    if (!dryRun) {
      final apk = resolveExistingApk(Directory.current.path, devReleaseApkRelativePaths());
      if (apk == null) {
        stderr.writeln('Dev APK build finished but no release APK was found.');
        exit(66);
      }
      final refusal = await devApkUploadRefusalForFile(apk);
      if (refusal != null) {
        stderr.writeln(refusal);
        exit(67);
      }
      stdout.writeln(
        'Verified dev APK ${apk.path} ($devAndroidPackageId / '
        '$devAndroidApplicationLabel).',
      );
    }
  }

  await _run(_bin('firebase'), [
    'deploy',
    '--config',
    'firebase.dev.json',
    '--only',
    'hosting',
    '--project',
    _project,
    '--message',
    'Dev web $version ${stamp.gitSha}',
  ], dryRun: dryRun);

  if (distributeAndroid) {
    if (!buildAndroid) {
      stderr.writeln('--distribute-android requires --build-android.');
      exit(64);
    }
    final androidAppId =
        _arg(args, '--android-app-id') ??
        Platform.environment['FIREBASE_ANDROID_DEV_APP_ID'] ??
        Platform.environment['FIREBASE_ANDROID_APP_ID'];
    if (androidAppId == null || androidAppId.isEmpty) {
      stderr.writeln(
        'Missing Firebase Android app id for dev distribution. '
        'Set FIREBASE_ANDROID_DEV_APP_ID or pass --android-app-id.',
      );
      exit(65);
    }
    final apk = resolveExistingApk(Directory.current.path, devReleaseApkRelativePaths());
    if (apk == null && !dryRun) {
      stderr.writeln('No dev release APK to upload.');
      exit(66);
    }
    final notes = File('build/DEV_ANDROID_RELEASE_NOTES_$version.txt');
    if (!dryRun) {
      await notes.writeAsString(
        'Dev Android $version\n'
        'Web: $_devUrl\n'
        'Package: $devAndroidPackageId\n'
        'Git: ${stamp.gitSha}\n',
      );
    }
    stdout.writeln('Uploading dev APK to App Distribution (groups: $groups)...');
    await _run(_bin('firebase'), [
      'appdistribution:distribute',
      apk?.path ?? devReleaseApkRelativePaths().first,
      '--app',
      androidAppId,
      '--groups',
      groups,
      '--release-notes-file',
      notes.path,
      '--project',
      _project,
    ], dryRun: dryRun);
  }

  stdout.writeln('Dev web target: $_devUrl');
}

String? _arg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i != -1 && i + 1 < args.length) return args[i + 1];
  for (final a in args) {
    if (a.startsWith('$flag=')) return a.substring(flag.length + 1);
  }
  return null;
}

Future<void> _writeWebVersionJson(String version, ReleaseBuildStamp stamp) async {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionLine = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(pubspec)?.group(1)?.trim();
  final payload = webVersionPayload(
    releaseTag: version,
    pubspecVersionLine: versionLine,
    stamp: stamp,
    flavor: 'dev',
  );
  final out = File('build/web/version.json');
  if (!out.parent.existsSync()) {
    await out.parent.create(recursive: true);
  }
  await out.writeAsString('${jsonEncode(payload)}\n');
}

Future<void> _run(String bin, List<String> args, {required bool dryRun}) async {
  final printable = '$bin ${joinArgsRedactingAnalyticsDefines(args)}';
  stdout.writeln(dryRun ? '[dry-run] $printable' : '\$ $printable');
  if (dryRun) return;
  final r = await Process.start(bin, args, mode: ProcessStartMode.inheritStdio);
  final code = await r.exitCode;
  if (code != 0) {
    stderr.writeln('$bin failed (exit $code)');
    exit(code);
  }
}
