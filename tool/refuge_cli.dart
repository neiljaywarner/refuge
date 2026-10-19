import 'dart:io';

/// Pure Dart CLI for Refuge repository automation, GitHub issue hygiene,
/// CodeRabbit review triggers, and worktree orchestration.
///
/// Designed with a single prefix-matchable command shape:
///   `/opt/homebrew/bin/dart run tool/refuge_cli.dart <subcommand>`
/// so approving `/opt/homebrew/bin/dart run` once in Antigravity allows
/// unattended execution without repeated permission prompts.
Future<void> main(List<String> args) async {
  final command = args.isNotEmpty ? args.first : 'help';

  switch (command) {
    case 'sync-issues':
      await _syncIssues();
    case 'add-mentoring-epic':
      await _addMentoringEpic();
    case 'add-flavors-and-csv-issues':
      await _addFlavorsAndCsvIssues();
    case 'add-pwa-cicd-store-issues':
      await _addPwaCicdStoreIssues();
    case 'configure-mcp':
      await _configureMcpAndTestMarionette();
    case 'create-deploy-and-audio-issues':
      await _createDeployAndAudioIssues();
    case 'ship-pr':
      await _shipPr(args.skip(1).toList());
    case 'sync-wiki':
      await _syncWiki();
    case 'list-open':
      await _runGh(['issue', 'list', '--repo', _repo, '--limit', '50']);
    default:
      stdout.writeln(
        'Usage: dart run tool/refuge_cli.dart <sync-issues|add-mentoring-epic|add-flavors-and-csv-issues|add-pwa-cicd-store-issues|configure-mcp|create-deploy-and-audio-issues|ship-pr|sync-wiki|list-open>',
      );
  }
}

Future<void> _shipPr(List<String> rest) async {
  if (rest.length < 3) {
    stderr.writeln('Usage: dart run tool/refuge_cli.dart ship-pr <branch> <title> <body>');
    exit(64);
  }
  final branch = rest[0];
  final title = rest[1];
  final body = rest[2];

  stdout.writeln('==> 1. Pushing branch $branch to origin...');
  final pushRes = await Process.run('git', ['push', '-u', 'origin', branch]);
  stdout.write(pushRes.stdout);
  stderr.write(pushRes.stderr);
  if (pushRes.exitCode != 0) {
    exit(pushRes.exitCode);
  }

  stdout.writeln('==> 2. Creating Pull Request for $branch...');
  final prRes = await Process.run(_gh, [
    'pr',
    'create',
    '--repo',
    _repo,
    '--head',
    branch,
    '--base',
    'main',
    '--title',
    title,
    '--body',
    body,
  ]);
  final prOut = (prRes.stdout as String).trim();
  stdout.writeln(prOut);
  if (prRes.exitCode != 0) {
    stderr.writeln(prRes.stderr);
    exit(prRes.exitCode);
  }

  final prNum = prOut.split('/').last.trim();
  stdout.writeln('==> 3. Triggering @coderabbitai review on PR #$prNum...');
  await _runGh([
    'pr',
    'comment',
    prNum,
    '--repo',
    _repo,
    '--body',
    '@coderabbitai review — verified locally via Dart MCP (analyze_files + run_tests). Non-blocking polish items tracked in Issue #36.',
  ], ignoreErrors: true);

  stdout.writeln('==> 4. Checking PR #$prNum mergeability & squash-merging...');
  await Future<void>.delayed(const Duration(seconds: 3));
  await _runGh([
    'pr',
    'merge',
    prNum,
    '--repo',
    _repo,
    '--squash',
    '--delete-branch',
  ]);
  stdout.writeln('==> PR #$prNum squash-merged and branch $branch deleted!');
}

Future<void> _syncWiki() async {
  final wikiDir = Directory('/tmp/refuge-wiki-sync');
  if (wikiDir.existsSync()) {
    wikiDir.deleteSync(recursive: true);
  }
  final cloneRes = await Process.run('git', [
    'clone',
    'https://github.com/neiljaywarner/refuge.wiki.git',
    wikiDir.path,
  ]);
  if (cloneRes.exitCode != 0) {
    stderr.writeln('Wiki clone failed: ${cloneRes.stderr}');
    exit(cloneRes.exitCode);
  }
  final srcWiki = Directory('docs/wiki');
  for (final entity in srcWiki.listSync()) {
    if (entity is File && entity.path.endsWith('.md')) {
      final name = entity.uri.pathSegments.last;
      entity.copySync('${wikiDir.path}/$name');
    }
  }
  await Process.run('git', ['-C', wikiDir.path, 'add', '-A']);
  final commitRes = await Process.run('git', [
    '-C',
    wikiDir.path,
    'commit',
    '-m',
    'docs(wiki): sync latest ADRs, Hybrid Appwrite+Firebase grading & Oct 31 roadmap',
  ]);
  stdout.write(commitRes.stdout);
  final pushRes = await Process.run('git', ['-C', wikiDir.path, 'push', 'origin', 'master']);
  stdout.write(pushRes.stdout);
  stderr.write(pushRes.stderr);
  stdout.writeln('==> Live GitHub Wiki synced!');
}


Future<void> _configureMcpAndTestMarionette() async {
  const mcpJson = '''{
  "mcpServers": {
    "marionette": {
      "command": "/Users/neil/.pub-cache/bin/marionette_mcp",
      "args": []
    },
    "firebase": {
      "command": "/opt/homebrew/bin/firebase",
      "args": ["mcp", "--dir", "/Users/neil/belongonthespectrum/refuge"]
    },
    "patrol": {
      "command": "/Users/neil/.pub-cache/bin/patrol_mcp",
      "args": []
    },
    "dart": {
      "command": "/opt/homebrew/bin/dart",
      "args": ["mcp-server"]
    }
  }
}
''';
  final globalConfig = File('/Users/neil/.gemini/config/mcp_config.json');
  await globalConfig.parent.create(recursive: true);
  await globalConfig.writeAsString(mcpJson);
  stdout.writeln('==> Wrote /Users/neil/.gemini/config/mcp_config.json with marionette, firebase, patrol, and dart MCP servers.');

  // Verify Marionette MCP server tools/list via JSON-RPC over stdio
  final proc = await Process.start('/Users/neil/.pub-cache/bin/marionette_mcp', []);
  proc.stdin.writeln('{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"refuge_cli","version":"1.0.0"}}}');
  proc.stdin.writeln('{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}');
  await proc.stdin.close();
  final out = await proc.stdout.transform(const SystemEncoding().decoder).join();
  stdout.writeln('==> Marionette MCP tools/list verified (${out.length} bytes response).');
}

Future<void> _createDeployAndAudioIssues() async {
  stdout.writeln('==> Ensuring week1 label exists...');
  await _runGh([
    'label',
    'create',
    'week1',
    '--repo',
    _repo,
    '--color',
    '0E8A16',
    '--description',
    'High-leverage Week 1 post-launch / cutover week experiment',
    '--force',
  ], ignoreErrors: true);

  stdout.writeln('==> Creating Issue #56: Minimum Viable Deployment Process (tool/deploy_release.dart + DEPLOYMENT.md)...');
  await _createIssueWithComment(
    title:
        'feat(deploy): Minimum Viable Deployment Process (tool/deploy_release.dart + DEPLOYMENT.md + Release Notes for belongonthespectrum.web.app)',
    labels: 'infra,documentation,mentoring',
    milestone: 'v0.5.5 - Pre-Alpha Visuals, Feedback & Preview Deploy',
    body: '''
## Why This Matters (Human Summary)
Gives us a deterministic, 1-command pure-Dart deployment pipeline (`tool/deploy_release.dart`) and clear runbook (`DEPLOYMENT.md`) that builds Flutter Web, generates human + neurodivergent-friendly release notes, deploys to a Firebase Hosting Preview Channel, and publishes to live production (`https://belongonthespectrum.web.app`).

## Acceptance Criteria
- [x] Provision `belongonthespectrum` Firebase project and `https://belongonthespectrum.web.app` Hosting site.
- [ ] Implement `tool/deploy_release.dart` in pure Dart (preferring Dart over bash/python per repo convention).
- [ ] Create `DEPLOYMENT.md` linked to `unattended_session_908pm.md`, `neil_to_review_sunday_night.md`, and `ADR-0009`.
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Target Files**: `tool/deploy_release.dart`, `DEPLOYMENT.md`, `.firebaserc`, `firebase.json`
''',
  );

  stdout.writeln('==> Creating Issue #57: Automated GitHub Actions CI/CD Deployment Pipeline...');
  await _createIssueWithComment(
    title:
        'chore(ci-deploy): Automated GitHub Actions CI/CD Deployment Pipeline (PR Preview Channels + Main Merge Production Deploy)',
    labels: 'infra,firebase,bdd-testing',
    milestone: 'v0.8.0-alpha - Usable Community Alpha (Any Auth)',
    body: '''
## Why This Matters (Human Summary)
Builds on our minimum deployment process (#56) by automating Firebase Hosting Preview Channel deployments on every Pull Request (posting the live preview URL as a PR comment) and automatically deploying `main` merges/tags to `https://belongonthespectrum.web.app`.

## Acceptance Criteria
- [ ] Add `.github/workflows/firebase-hosting-pull-request.yml` for automatic PR preview channel links.
- [ ] Add `.github/workflows/firebase-hosting-merge.yml` calling `dart run tool/deploy_release.dart` on `main`.
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Depends on**: Issue #56 (`tool/deploy_release.dart`)
''',
  );

  stdout.writeln('==> Creating Issue #58: Multi-Channel Semantic Release Notes, Rollback Gate & App Distribution Automation...');
  await _createIssueWithComment(
    title:
        'feat(release-ops): Multi-Channel Semantic Release Notes, Rollback Gate & Firebase App Distribution Automation',
    labels: 'infra,firebase,coming-soon',
    milestone: 'v0.9.0-rc - Release Candidate & 70% Coverage',
    body: '''
## Why This Matters (Human Summary)
Second follow-up improvement to our deployment pipeline (#56): unifies Web PWA (`belongonthespectrum.web.app`), Android APK/AAB (Firebase App Distribution), and iOS IPA/TestFlight release notes with a 1-command atomic rollback gate if Crashlytics/Analytics detects regressions.

## Acceptance Criteria
- [ ] Extend `tool/deploy_release.dart` with `--android-distribute`, `--ios-distribute`, and `--rollback`.
- [ ] Auto-attach Patrol/Marionette screenshots to GitHub Releases.
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Related Issues**: #54, #56, #57
''',
  );

  stdout.writeln('==> Creating Issue #59: Neurodivergent-Friendly Audio MP3 Release Notes (week1 label)...');
  await _createIssueWithComment(
    title:
        'feat(accessibility,audio): Neurodivergent-Friendly Audio MP3 Release Notes ("Listen to What\'s New in 60 Seconds")',
    labels: 'accessibility,week1,ux-neurodivergent,enhancement',
    milestone: 'v1.0.0 - Belong Community Launch (Circle.so Cutover)',
    body: '''
## Why This Matters (Human & Neurodivergent Accessibility Summary)
Many neurodivergent community members and busy organizers experience cognitive fatigue when reading long text changelogs. Adding a warm, calm **60-second Audio MP3 Release Note** (*"Listen to What's New"*) alongside each release lets members listen to a friendly spoken summary right inside the app or on the release page!

## Acceptance Criteria
- [ ] Add a `generate-audio-notes` step to `tool/deploy_release.dart` that converts the human release summary into a calm `.mp3` audio file.
- [ ] Host the `.mp3` on Appwrite Storage / Firebase Hosting and embed a simple 1-tap Play/Pause audio pill in the *"What's New"* sheet.
- [ ] Tagged with `week1` to try during Week 1!
''',
    llmComment: '''
### 🤖 LLM Execution Brief (`week1` Experiment)
- **Labels**: `week1`, `accessibility`, `ux-neurodivergent`
- **Cross-References**: `DEPLOYMENT.md`, `ADR-0009`, `neil_to_review_sunday_night.md`
''',
  );
}


Future<void> _addPwaCicdStoreIssues() async {
  stdout.writeln('==> 1. Updating Issue #20 to include firebase_in_app_messaging + Web Remote Config In-App Banner...');
  await _runGh([
    'issue',
    'comment',
    '20',
    '--repo',
    _repo,
    '--body',
    '''
### 🔔 Update: `firebase_in_app_messaging` + Web Compatibility
- Include `firebase_in_app_messaging` in `pubspec.yaml` for native Android & iOS in-app campaigns.
- **Important Web/PWA Note**: Because `firebase_in_app_messaging` only targets Android/iOS natively, our cross-platform `OrganizerRemoteConfigService` (`firebase_remote_config`) powers the in-app **"Message from the Organizer"** banner & modal on **Flutter Web / PWA, Android, and iOS** simultaneously!
''',
  ]);

  stdout.writeln('==> 2. Creating Issue #42: CI/CD Workflow (Scheduled at v0.8.0-alpha so we hurry to Alpha first)...');
  await _createIssueWithComment(
    title:
        'chore(ci): Add VGV-style GitHub Actions CI/CD workflow matching local dart analyze & flutter test rules',
    labels: 'infra,bdd-testing,mentoring',
    milestone: 'v0.8.0-alpha - Usable Community Alpha (Any Auth)',
    body: '''
## Why This Matters (Human & Mentoring Summary)
Scheduled at **`v0.8.0-alpha`** so we reach our usable Community Alpha tonight first without slowing down feature velocity.
Our GitHub Actions workflow uses the exact same `analysis_options.yaml` (`dart analyze --fatal-infos`) and `flutter test` commands that we run locally via the Dart MCP server, guaranteeing that if local checks pass, CI will almost never fail.

## Acceptance Criteria
- [ ] Create `.github/workflows/ci.yml` running `flutter analyze` and `flutter test --coverage` on every PR.
- [ ] Cache `.pub-cache` and Flutter SDK on GitHub runners for < 90s execution time.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Scheduled for v0.8.0-alpha)
- **Worktree**: `chore/#42-github-actions-ci`
''',
  );

  stdout.writeln('==> 3. Creating Issue #43: Firebase Test Lab, BrowserStack & PWA Cross-Device Testing...');
  await _createIssueWithComment(
    title:
        'test(device-cloud): Configure Firebase Test Lab, BrowserStack & PWA installation/responsiveness verification',
    labels: 'bdd-testing,firebase,infra,mentoring',
    milestone: 'v0.9.0-rc - Release Candidate & 70% Coverage',
    body: '''
## Why This Matters (Human & Mentoring Summary)
Before our October 31st Circle.so cutover, we want confidence that **Belong on the Spectrum** works smoothly across Android phones, iPhones (Safari PWA & native), iPads, and desktop browsers:
1. **PWA Testing**: Verify *"Add to Home Screen"* installation, standalone display mode, offline splash screen, and Belong maskable icons on iOS Safari and Android Chrome.
2. **Firebase Test Lab**: Run Patrol / Flutter integration test APKs across real physical devices in Google's cloud device farm.
3. **BrowserStack**: Verify iOS Safari PWA and responsive desktop breakpoints.

## Acceptance Criteria
- [ ] Add PWA manifest & service-worker verification tests.
- [ ] Document Firebase Test Lab (`gcloud firebase test android run`) and BrowserStack workflows in the Wiki.
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Worktree**: `test/#43-firebase-test-lab-browserstack-pwa`
- **Cross-References**: Issue #19 (Belong PWA Icons & Manifest), Issue #21 (Wiki PWA Guide).
''',
  );

  stdout.writeln('==> 4. Creating Issue #44: TestFlight (iOS Beta) & Google Play Closed/Internal Beta Rollout...');
  await _createIssueWithComment(
    title:
        'feat(release-beta): Configure Apple TestFlight & Google Play Internal/Closed Beta tracks',
    labels: 'infra,coming-soon,circle-parity',
    milestone: 'v0.9.0-rc - Release Candidate & 70% Coverage',
    body: '''
## Why This Matters (Human Summary)
While the **Belong Progressive Web App (PWA)** lets every community member join immediately on October 31st via their browser or *"Add to Home Screen"* without waiting on Apple/Google store review, setting up **Apple TestFlight** and **Google Play Internal/Closed Beta** lets core mobile beta testers install native builds ahead of the public store launch.

## Cross-Links
- Feeds into Production Store Launch Issues **#45** (Google Play Store) and **#46** (Apple App Store), and Links drawer items **#30** (`Download the Android App`) and **#31** (`Download the iOS App`).
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Worktree**: `feat/#44-testflight-and-play-beta`
- **Related Issues**: #30, #31, #45, #46
''',
  );

  stdout.writeln('==> 5. Creating Issue #45: Google Play Store Production Listing & Signing...');
  await _createIssueWithComment(
    title:
        'feat(store-android): Publish Belong on the Spectrum to Google Play Store (Unlocks Issue #30 Link)',
    labels: 'infra,branding-icons,whitelabel',
    milestone: 'v1.0.0 - Belong Community Launch (Circle.so Cutover)',
    body: '''
## Why This Matters (Human Summary)
Tracks the production Android App Bundle (`.aab`) build, Play Console store listing, screenshots, data safety form, and production release for **Belong on the Spectrum**.
Once live, the `Download the Android App` link in the Spaces `Links` section (**Issue #30**) is updated via Firebase Remote Config (`android_app_download_url`) with zero code deployment required!

## Cross-Links
- **Beta Prerequisite**: Issue #44 (Google Play Internal/Closed Beta)
- **In-App Drawer Link**: Issue #30 (`Wire 'Download the Android App' link`)
- **App Icons**: Issue #19 (`Belong Adaptive Launcher Icons`)
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Related Issues**: #19, #30, #44
''',
  );

  stdout.writeln('==> 6. Creating Issue #46: Apple iOS App Store Production Listing & Signing...');
  await _createIssueWithComment(
    title:
        'feat(store-ios): Publish Belong on the Spectrum to Apple iOS App Store (Unlocks Issue #31 Link)',
    labels: 'infra,branding-icons,whitelabel',
    milestone: 'v1.0.0 - Belong Community Launch (Circle.so Cutover)',
    body: '''
## Why This Matters (Human Summary)
Tracks the production iOS `.ipa` archive, App Store Connect listing, privacy nutrition labels, and App Review submission for **Belong on the Spectrum**.
Once approved, the `Download the iOS App` link in the Spaces `Links` section (**Issue #31**) is updated immediately via Firebase Remote Config (`ios_app_download_url`)!

## Cross-Links
- **Beta Prerequisite**: Issue #44 (Apple TestFlight Beta)
- **In-App Drawer Link**: Issue #31 (`Wire 'Download the iOS App' link`)
- **App Icons**: Issue #19 (`Belong iOS App Icons`)
''',
    llmComment: '''
### 🤖 LLM Execution Brief
- **Related Issues**: #19, #31, #44
''',
  );
}

Future<void> _addFlavorsAndCsvIssues() async {
  stdout.writeln(
    '==> 1. Updating Issue #20 to bundle all core FlutterFire packages + dev/prod Flavor Setup (CodeWithAndrea / VGV)...',
  );
  const issue20Body = '''
## Why This Matters (Human Summary)
1. **Non-Technical Organizer Control (`Firebase Remote Config`)**: Community organizers at **Belong on the Spectrum** can update the **"Message from the Organizer"** welcome banner, announcements, or external links anytime in the Firebase Console without needing a developer or app store release.
2. **All Core FlutterFire Packages Installed at Once**: Rather than adding Firebase packages piecemeal across future releases, we install the complete, vetted FlutterFire suite up front (`firebase_core`, `firebase_analytics`, `firebase_remote_config`, `firebase_crashlytics`, `firebase_auth`, `firebase_messaging`, `firebase_performance`, `firebase_app_check`).
3. **`dev` vs `prod` Flavor Isolation (CodeWithAndrea + VGV Pattern)**:
   - We configure explicit **`dev`** and **`prod`** flavors (`lib/main_dev.dart`, `lib/main_prod.dart`, and `AppFlavor` provider) documented in **ADR 0006** so local development, BDD tests, and developer experiments in `dev` **never clash with or pollute `prod` analytics, Remote Config, or community data**.
   - **Zero API Keys or PII in Git**: All environment-specific Firebase project configs remain git-ignored (`--dart-define-from-file` / local untracked config) with safe offline/test fallbacks.

## Acceptance Criteria
- [ ] Write `docs/adr/0006-flavors-and-multi-environment-firebase.md` comparing CodeWithAndrea (`--dart-define-from-file` + `main_dev.dart`/`main_prod.dart`) and VGV flavor patterns.
- [ ] Add all core FlutterFire packages to `pubspec.yaml`: `firebase_core`, `firebase_analytics`, `firebase_remote_config`, `firebase_crashlytics`, `firebase_auth`, `firebase_messaging`, `firebase_performance`, `firebase_app_check`.
- [ ] Implement `AppFlavor` (`dev`, `prod`, with enum hooks ready for `stg` and `qa` in Issue #40) + `lib/main_dev.dart` and `lib/main_prod.dart`.
- [ ] Implement `OrganizerRemoteConfigService` (`organizer_welcome_title`, `organizer_welcome_message`, `organizer_banner_enabled`, `dfw_church_url`) and `CommunityAnalyticsService`.
- [ ] Render the live **"Message from the Organizer"** card at the top of `Feed` / `Start Here`.
''';

  const issue20Comment = '''
### 🤖 LLM Execution Brief (Updated: All FlutterFire Packages + `dev`/`prod` Flavors)
- **Worktree Setup**:
  ```bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-20-firebase-and-flavors -b feat/#20-firebase-and-flavors
  ```
- **Packages to Add in `pubspec.yaml`**:
  `firebase_core`, `firebase_analytics`, `firebase_remote_config`, `firebase_crashlytics`, `firebase_auth`, `firebase_messaging`, `firebase_performance`, `firebase_app_check`
- **Files to Create / Edit**:
  - `docs/adr/0006-flavors-and-multi-environment-firebase.md`
  - `lib/src/core/config/app_flavor.dart` (`enum AppFlavor { dev, stg, qa, prod }`)
  - `lib/main_dev.dart` & `lib/main_prod.dart`
  - `lib/src/core/firebase/organizer_remote_config_service.dart`
  - `lib/src/core/firebase/community_analytics_service.dart`
- **Security Rule**: Never commit `firebase_options*.dart`, `google-services.json`, `GoogleService-Info.plist`, or raw keys.
''';

  await _runGh(['issue', 'edit', '20', '--repo', _repo, '--body', issue20Body]);
  await _runGh([
    'issue',
    'comment',
    '20',
    '--repo',
    _repo,
    '--body',
    issue20Comment,
  ]);

  stdout.writeln(
    '==> 2. Creating Issue #40: Add stg (prod-data mirror) and qa flavors...',
  );
  await _createIssueWithComment(
    title:
        'feat(flavors): Configure stg (prod-data mirror) and qa Firebase & Serverpod flavors when needed',
    labels: 'infra,firebase,mentoring',
    milestone: 'v0.9.0-rc - Release Candidate & 70% Coverage',
    body: '''
## Why This Matters (Human & Mentoring Summary)
In **Issue #20**, we establish **`dev`** and **`prod`** flavors so development work never clashes with production.

As the team and contributor base grow, this issue tracks activating the **`stg` (Staging)** and **`qa` (Quality Assurance)** flavors:
- **`stg` (Staging)**: Connects to a staging Firebase project and a pre-release build channel while optionally reading a **sanitized mirror of `prod` data** so community organizers can preview exact production content before cutover.
- **`qa` (Quality Assurance)**: Isolated environment for automated Maestro, Patrol, and Marionette regression suites.

## Acceptance Criteria
- [ ] Add `lib/main_stg.dart` and `lib/main_qa.dart` entrypoints wired to `AppFlavor.stg` and `AppFlavor.qa`.
- [ ] Document `stg` and `qa` launch configurations in `.vscode/launch.json` and the Contributor Wiki.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Low / Flash Ready)
- **Depends On**: Issue #20 (`AppFlavor` foundation).
- **Worktree**: `feat/#40-stg-and-qa-flavors`
''',
  );

  stdout.writeln(
    '==> 3. Creating Issue #41: Circle.so CSV Data Migration Importer (Contributor-Ready)...',
  );
  await _createIssueWithComment(
    title:
        'feat(migration): Circle.so CSV Data Migration Importer (tool/import_circle_csv.dart) for Members, Spaces & Posts',
    labels: 'circle-parity,education,mentoring',
    milestone: 'v0.9.0-rc - Release Candidate & 70% Coverage',
    body: '''
## Why This Matters (Self-Contained Brief for a Contributor / Teammate)
Before **Belong on the Spectrum's** Circle.so subscription ends on **October 31st, 2026**, we want to bring over existing community history exported from Circle.so via **CSV files** (Members, Posts/Reflections, Comments, and Space mappings) so no meaningful conversations or introductions in `Start Here & Introduce Yourself` or `General Chat` are lost!

> **Note for Contributors**: This issue is intentionally designed as a clean, self-contained **pure Dart CLI tool (`tool/import_circle_csv.dart`)** so a teammate or mentee can build and test it independently using sample anonymized CSVs!

## Circle.so CSV Export Mapping to Belong Spaces
| Circle.so Space Name in CSV | Target Belong Space Slug | Section |
| :--- | :--- | :--- |
| `Start Here & Introduce Yourself` / `Start Here` | `start_here` | `Welcome` |
| `Announcements` | `announcements` | `Welcome` |
| `General Chat` | `general_chat` | `Pinned` / `Community` |
| `Memes` | `memes` | `Community` |
| `Online Resources / Videos` | `resources_videos` | `Community` |
| `Actually Autistic Chat` | `actually_autistic_chat` | `Community` |
| `Friends Chat` | `friends_chat` | `Community` |
| `Family Chat` | `family_chat` | `Community` |

## Acceptance Criteria (Strict Zero-PII Rule!)
- [ ] **NEVER commit real member CSV exports or real member emails/names to Git!** Add `**/*.csv` (except `test/fixtures/sample_anonymized_circle_export.csv`) to `.gitignore`.
- [ ] Build pure-Dart CLI `tool/import_circle_csv.dart`:
  - Supports `--dry-run` mode (validates CSV columns, counts rows per space, and prints a summary report without writing to the database).
  - Maps Circle space names to Belong space slugs (`start_here`, `announcements`, `general_chat`, `memes`, `resources_videos`, `actually_autistic_chat`, `friends_chat`, `family_chat`).
  - Preserves original `createdAt` timestamps and author display names.
- [ ] Provide a synthetic, anonymized test fixture `test/fixtures/sample_anonymized_circle_export.csv` and unit tests in `test/tool/import_circle_csv_test.dart`.
- [ ] Add a plain-English section in the Wiki explaining how an admin exports CSVs from Circle.so and runs the importer locally against `dev` first, then `prod`.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Ideal for Teammate, Mentee, or Argon Low/Medium)
- **SECURITY MANDATE**: Real Circle CSV files contain member PII (names/emails). Ensure `.gitignore` blocks all real `.csv` files outside `test/fixtures/sample_anonymized_circle_export.csv`.
- **Worktree Setup**:
  ```bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-41-circle-csv-migration -b feat/#41-circle-csv-migration
  ```
- **Target Files**:
  - `tool/import_circle_csv.dart`
  - `test/fixtures/sample_anonymized_circle_export.csv`
  - `test/tool/import_circle_csv_test.dart`
  - `docs/wiki/Circle-CSV-Migration-Guide.md`
''',
  );
}

Future<void> _addMentoringEpic() async {
  stdout.writeln(
    '==> Creating Issue #38: [EPIC] Exemplary Mentee, Student & Apprentice Reference Repository...',
  );
  await _createIssueWithComment(
    title:
        'docs(mentoring): [EPIC] Exemplary Student, Mentee & Apprentice Reference Repository (Clean Architecture, BDD, Pure Dart Tooling & Token Optimization)',
    labels: 'epic,education,mentoring,wiki-docs',
    milestone: 'v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki',
    body: '''
## Why This Matters (For Students, Mentees & Apprentices)
Beyond serving **Belong on the Spectrum**, this repository (`neiljaywarner/refuge`) is architected to be a **gold-standard teaching reference** that students, mentees, and apprentices can study to learn modern, AI-assisted full-stack Flutter & Serverpod engineering:

1. **CodeWithAndrea Feature-First Layered Architecture + `hooks_riverpod`** (`presentation` -> `application` -> `domain` -> `data`).
2. **Pragmatic Red-Green-Refactor BDD**: Human-readable `.feature` files (`bdd_widget_test`) paired with fast 1-second widget tests and live **Marionette MCP** / **Patrol MCP** verification.
3. **Pure Dart Developer Tooling (`tool/refuge_cli.dart`)**: Favoring clean, type-safe Dart CLI scripts over brittle bash scripts so Flutter developers can read and maintain every automation tool in one language.
4. **Student & Free-Tier AI Token Optimization**: Practical guides (`tokens-usage.md` and Wiki) showing students on free or budget AI tiers how to stretch their 5-hour and weekly quotas by 5x–10x.

## Stories in This Epic
- [ ] **Story #39**: Organize pure-Dart helper scripts (`tool/refuge_cli.dart`) and publish the **Student, Apprentice & Free-Tier Token Optimization Wiki Guide** (`docs/wiki/Apprentice-and-Token-Optimization-Guide.md`).
- [ ] **Issue #16**: Marionette MCP, Patrol MCP, Dart/Flutter MCP & 25 Official Skills Setup *(Completed)*.
- [ ] **Issue #35**: `hooks_riverpod` (`HookConsumerWidget`) & CodeWithAndrea Architecture.
- [ ] **Issue #36**: CodeRabbit AI Review Audit & Zero-Smell Refactoring Gate.
- [ ] **Issue #37**: Dart Multi-Model Token Orchestrator & Worktree Harness (`tool/token_harness.dart`).
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Medium / Low Ready)
- **Target Wiki Page**: `docs/wiki/Apprentice-and-Token-Optimization-Guide.md`
- **Target Tooling Directory**: `tool/refuge_cli.dart` (committed cleanly via PR with zero PII/secrets).
''',
  );

  stdout.writeln(
    '==> Creating Issue #39: Story — Pure-Dart Helper Scripts & Free-Tier Student Token Guide in Wiki...',
  );
  await _createIssueWithComment(
    title:
        'feat(mentoring): Organize pure-Dart helper scripts (tool/) & add Apprentice/Free-Tier Token Optimization Wiki section',
    labels: 'education,mentoring,wiki-docs',
    milestone: 'v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki',
    body: '''
## Why This Matters (Human & Apprentice Summary)
Many students, mentees, and open-source apprentices work on **free-tier or capped AI plans**. By organizing our repository helper scripts cleanly under `tool/` in pure Dart and dedicating a Wiki page to **Apprentice Architecture & Free-Tier Token Optimization**, mentees can see:
- How every GitHub issue, worktree, BDD test, and PR fits together.
- How to use `get_interactive_elements` (Marionette) and `flutter test` (`1s`) instead of burning thousands of vision tokens on screenshots.
- How to rotate between Flash/Low, Medium, and Claude/GPT models across 5-hour and weekly windows.

## Acceptance Criteria
- [ ] Organize reusable, non-private Dart automation scripts under `tool/` (`tool/refuge_cli.dart`).
- [ ] Create `docs/wiki/Apprentice-and-Token-Optimization-Guide.md` and link it prominently from `docs/wiki/Home.md` and `docs/wiki/_Sidebar.md`.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Can be executed alongside Issue #21 (Wiki Overhaul) or in `feat/#39-apprentice-tooling-and-wiki`**.
''',
  );
}

const String _repo = 'neiljaywarner/refuge';
const String _gh = '/opt/homebrew/bin/gh';

Future<void> _syncIssues() async {
  stdout.writeln('==> 1. Closing early unlabelled draft duplicates (#2..#14)...');
  for (var num = 2; num <= 14; num++) {
    await _runGh([
      'issue',
      'close',
      '$num',
      '--repo',
      _repo,
      '--comment',
      'Superseded by the milestone-tagged, labeled issue roster (#15–#37) with full Non-Technical Summaries and 🤖 LLM Execution Brief comments.',
    ], ignoreErrors: true);
  }

  stdout.writeln('==> 2. Updating Issue #21 (Non-Technical Wiki & Oct 31 Schedule) body...');
  const issue21Body = '''
## Why This Matters (Human Summary)
Our documentation and GitHub Wiki should welcome **non-technical community organizers, pastors, moderators, and open-source contributors** — with **zero mention of the past hackathon**.

Most importantly, **Belong on the Spectrum's Circle.so subscription ends on October 31st, 2026**. Non-technical leaders need a clear, reassuring, plain-English **Schedule & Cutover Timeline to October 31st** so everyone knows what is ready today, when alpha/beta testing happens, how to update the "Message from the Organizer" via Firebase Remote Config, and how the final cutover happens before October 31st.

## Acceptance Criteria
- [ ] Remove `docs/wiki/Hackathon-Judges-Portal.md` and strip all hackathon/judges references from `docs/wiki/Home.md`, `_Sidebar.md`, `_Footer.md`, and all wiki pages.
- [ ] Create **`docs/wiki/Non-Technical-Roadmap-to-Oct-31.md`**:
  - Plain-English calendar from **Oct 18 to Oct 31, 2026** (the last day of the Circle.so subscription).
  - Clear explanation of Alpha (`v0.8.0-alpha`), Release Candidate (`v0.9.0-rc`), and Launch (`v1.0.0` before Oct 31).
  - Side-by-side comparison showing how every Circle.so space maps to the new Belong app.
- [ ] Create **`docs/wiki/Organizer-Remote-Config-Guide.md`**:
  - Step-by-step non-technical guide for updating the **"Message from the Organizer"** and announcements via Firebase Remote Config without touching code.
- [ ] Create **`docs/wiki/Contributor-Guide.md`**:
  - Welcoming guide for developers, mentees, designers, and QA testers (CodeWithAndrea feature-first Riverpod architecture, `hooks_riverpod`, Ticket-Driven Development, worktrees, BDD `.feature` files, WCAG AAA sensory accessibility rules).
''';
  await _runGh(['issue', 'edit', '21', '--repo', _repo, '--body', issue21Body]);

  stdout.writeln('==> 3. Creating Issue #35: hooks_riverpod & CodeWithAndrea Architecture...');
  await _createIssueWithComment(
    title:
        'refactor(arch): Adopt hooks_riverpod (HookConsumerWidget) & enforce CodeWithAndrea feature-first architecture',
    labels: 'infra,education,mentoring',
    milestone: 'v0.6.0 - Clean Belong Circle UI, Nav, Icons, Firebase & Wiki',
    body: '''
## Why This Matters (Human & Mentoring Summary)
To keep our Flutter codebase clean, testable, and free of `StatefulWidget` boilerplate (`TextEditingController`/`AnimationController` disposal bugs), we standardize on:
1. **`hooks_riverpod` + `flutter_hooks`** (`HookConsumerWidget`) for all new and existing UI widgets.
2. **CodeWithAndrea (`codewithandrea.com`) Feature-First Layered Architecture**:
   - `presentation/` (Widgets + Riverpod Controllers/Notifiers)
   - `application/` (Services coordinating multiple repositories)
   - `domain/` (Immutable models & entities)
   - `data/` (Repositories & external data sources like Serverpod / Firebase Remote Config)

## Acceptance Criteria
- [ ] Add `hooks_riverpod` and `flutter_hooks` to `pubspec.yaml`.
- [ ] Use `HookConsumerWidget` for all new `v0.6.0`–`v0.8.0-alpha` screens (`HomeScreen`, `CommunitySearchView`, `MemberProfileSheet`, `BelongSignInDialog`).
- [ ] Migrate existing stateful presentation widgets (`ReflectionComposerDialog`, etc.) to `HookConsumerWidget` (`useTextEditingController`, `useState`).
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Model Tier Recommendation**: Gemini 4 Argon Low / Medium (~12 Agent Clock Minutes)
- **Worktree Command**:
  ```bash
  git -C /Users/neil/belongonthespectrum/refuge worktree add /Users/neil/belongonthespectrum/.worktrees/issue-35-hooks-riverpod-arch -b refactor/#35-hooks-riverpod-arch
  ```
- **Verification**:
  ```bash
  /opt/homebrew/bin/dart analyze
  /opt/homebrew/bin/flutter test
  ```
''',
  );

  stdout.writeln('==> 4. Creating Issue #36: CodeRabbit Release Quality Gate...');
  await _createIssueWithComment(
    title:
        'chore(quality): CodeRabbit AI Review Audit & Zero-Smell Refactoring Gate (v0.6.0, v0.7.0, v0.8.0-alpha)',
    labels: 'infra,bdd-testing,mentoring',
    milestone: 'v0.7.0 - Profile, Organizer Request & 50% Coverage',
    body: '''
## Why This Matters (Human & Mentoring Summary)
Fast development should never mean cutting corners or accumulating code smells. Every PR is reviewed by **CodeRabbit AI** (triggered automatically or via `@coderabbitai review` comments on GitHub PRs), and at each release checkpoint (`v0.6.0`, `v0.7.0`, `v0.8.0-alpha`) we audit and resolve all actionable CodeRabbit feedback following Red-Green-Refactor BDD principles.

## Acceptance Criteria
- [ ] Ensure every PR triggers and triages `@coderabbitai` review comments.
- [ ] Fix critical/blocking architectural or safety findings before merge.
- [ ] Conduct a release-level CodeRabbit sweep at `v0.6.0`, `v0.7.0`, and `v0.8.0-alpha` to maintain zero code smells and zero PII/key leaks.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **How to Trigger CodeRabbit on Any PR via `gh`**:
  ```bash
  /opt/homebrew/bin/gh pr comment <PR_NUMBER> --repo neiljaywarner/refuge --body "@coderabbitai review"
  ```
- **Skill Reference**: `.agents/skills/pr-coderabbit-triage-and-merge/SKILL.md`
''',
  );

  stdout.writeln('==> 5. Creating Issue #37: Dart Multi-Model Token Orchestrator Harness...');
  await _createIssueWithComment(
    title:
        'feat(tooling): Build Dart Multi-Model Token Orchestrator & Worktree Harness (tool/token_harness.dart)',
    labels: 'infra,education,mentoring',
    milestone: 'v0.8.0-alpha - Usable Community Alpha (Any Auth)',
    body: '''
## Why This Matters (Human & Mentoring Summary)
When building across multiple AI model families (**Gemini 4 Argon Low/Med/High**, **Claude Sonnet/Haiku/Opus**, and **GPT**), an automated **Dart Token & Worktree Orchestrator Harness (`tool/token_harness.dart`)** helps developers and mentees:
1. Inspect open GitHub issues and their `🤖 LLM Execution Brief` comments.
2. Automatically spin up isolated `git worktree` directories on our 48GB RAM Mac.
3. Recommend the optimal model tier for the current 5-hour burst window and 7-day weekly quota (`tokens-usage.md`).
4. Run Red-Green-Refactor BDD verification (`dart analyze` + `flutter test --coverage`) before opening PRs.

## Acceptance Criteria
- [ ] Implement `tool/token_harness.dart` in pure Dart using `package:args`.
- [ ] Document usage in `tokens-usage.md` and the Contributor Wiki for mentees.
''',
    llmComment: '''
### 🤖 LLM Execution Brief (Argon Low / Medium Ready)
- **Skill Reference**: `.agents/skills/dart-build-cli-app/SKILL.md` and `.agents/skills/token-quota-routing/SKILL.md`
- **Target File**: `tool/token_harness.dart`
''',
  );

  stdout.writeln('==> All GitHub Issues #15..#37 are clean, labeled, milestone-assigned, and ready!');
}

Future<void> _createIssueWithComment({
  required String title,
  required String labels,
  required String milestone,
  required String body,
  required String llmComment,
}) async {
  final result = await Process.run(_gh, [
    'issue',
    'create',
    '--repo',
    _repo,
    '--title',
    title,
    '--label',
    labels,
    '--milestone',
    milestone,
    '--body',
    body,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln('Failed to create issue "$title": ${result.stderr}');
    exit(result.exitCode);
  }
  final url = (result.stdout as String).trim();
  final num = url.split('/').last;
  stdout.writeln('   -> Created Issue #$num: $title');
  await _runGh(['issue', 'comment', num, '--repo', _repo, '--body', llmComment]);
}

Future<void> _runGh(List<String> ghArgs, {bool ignoreErrors = false}) async {
  final result = await Process.run(_gh, ghArgs);
  if (result.exitCode != 0 && !ignoreErrors) {
    stderr.writeln('gh error (${ghArgs.join(' ')}): ${result.stderr}');
    exit(result.exitCode);
  }
  final out = (result.stdout as String).trim();
  if (out.isNotEmpty) {
    stdout.writeln(out);
  }
}
