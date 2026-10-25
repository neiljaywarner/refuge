# 🚀 Belong on the Spectrum — Release & Deployment Guide (`DEPLOYMENT.md`)

*File: `DEPLOYMENT.md` (and `docs/wiki/deployment.md`)*  
*Maintained by: Belong on the Spectrum Engineering Team*  
*Target Platforms: Web PWA, Android Native (Google Play / App Distribution), Serverpod Backend*

---

## Soft-launch status (22 October 2026)

Checked against `origin/main` for the overlap week. This section does not record a new production deploy. The existing site remains [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app).

- **Posts.** Serverpod is still the default post backend. Cloud Firestore is still the second copy. Appwrite has not replaced either. Appwrite is on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed.
- **Android debug compile.** `android/app/build.gradle.kts` on `main` sets `jvmTarget` to `org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17`. That change is on `main` via [PR #413](https://github.com/neiljaywarner/refuge/pull/413). This note does not record a new debug build from the docs pass.
- **PostHog.** A smoke event was ingested. The app does not send product events unless `POSTHOG_KEY` or `POSTHOG_BELONG_PROJECT_TOKEN` is passed at build time. [Issue #410](https://github.com/neiljaywarner/refuge/issues/410) tracks that. Product conversion analytics are not live.
- **Feedback drawings.** Notes are saved in Firestore member_feedback with a clipboard handoff for organizers. The sheet does not say a note was filed on belong_feedback. The app does not embed an API token and does not create a GitHub issue by itself. Drawings stay with the note and are not presented as https://storage.belongonthespectrum.com uploads. [Issue #407](https://github.com/neiljaywarner/refuge/issues/407) is open.
- **Notifications.** The in-app bell exists. The launcher-dot MethodChannel (`com.belongonthespectrum.sanctuary/badge`) has no native handler. FCM permission requests set `badge: false`. [Issue #411](https://github.com/neiljaywarner/refuge/issues/411) is the test matrix and is not closed. Launcher badges and calm FCM are not fully verified on device.
- **Package name.** The Flutter package is still `refuge4serverpod`. Rename [Issue #233](https://github.com/neiljaywarner/refuge/issues/233) is not done.

---

## 📌 1. Deployment Architecture Overview

Belong on the Spectrum employs an unhurried, multi-environment continuous release pipeline designed to ship with confidence and zero downtime:

```mermaid
flowchart TD
    Git[Git Main Branch] --> Pipeline[dart run tool/deploy_release.dart]
    Pipeline --> WebBuild[Flutter Web Release Build]
    Pipeline --> AndroidBuild[Flutter Android APK Build]
    
    WebBuild --> PreviewHosting[Firebase Hosting Preview Channel<br/>version-specific-url]
    WebBuild --> ProdHosting[Firebase Hosting Production<br/>belongonthespectrum.web.app]
    
    AndroidBuild --> AppDist[Firebase App Distribution<br/>pre-alpha-testers group]
    
    Pipeline --> GitHubRelease[GitHub Release Tag & Release Notes]
    
    subgraph Multi-Environment Flavors
        DevEnv[Dev Flavor: reflections_dev collection & Dev Serverpod]
        ProdEnv[Prod Flavor: reflections collection & Prod Serverpod]
    end
```

---

## 🏷️ 2. Multi-Environment Flavor Architecture

To ensure development, automated test suites, and CI/CD runs **never pollute production community reflections or notification streams**, the codebase strictly enforces flavor separation via `--dart-define=FLAVOR=...`:

| Flavor | Environment | Web app (Firebase Hosting) | Database Collection | Serverpod URL | Target Audience |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`dev`** | Development & CI | `https://dev-belongonthespectrum.web.app/` | `reflections_dev` | `https://refuge4serverpod.api.serverpod.space/` (or local `http://10.0.2.2:8080/`) | Automated BDD tests, local emulators, continuous integration |
| **`prod`** | Production | `https://belongonthespectrum.web.app/` | `reflections` | `https://refuge4serverpod.api.serverpod.space/` | Real community members & churches |

`stg` / `qa` remain enum hooks only ([#40](https://github.com/neiljaywarner/refuge/issues/40)); they are not deployed yet. The marketing site `https://www.belongonthespectrum.com/` is separate from the Flutter web app origin.

### Where `dev` fits (and where it does not)

One Firebase project (`belongonthespectrum`) hosts two sites. Auth and Firestore are shared. The app sends dev posts to `reflections_dev` and prod posts to `reflections`. A second Firebase project is the later step if dev must not share Auth users with prod.

| Destination | Command | Build | URL |
| :--- | :--- | :--- | :--- |
| Stable **dev** site | `dart run tool/deploy_dev_web.dart` | `lib/main_dev.dart`, `FLAVOR=dev` | `https://dev-belongonthespectrum.web.app/` |
| Release **preview channel** | `dart run tool/deploy_release.dart --version vX.Y.Z` | `lib/main_prod.dart`, `FLAVOR=prod` | `https://belongonthespectrum--<channel>.web.app` (expires) |
| **Production** | same command with `--prod` | same prod build | `https://belongonthespectrum.web.app/` |

Preview channels are short-lived release candidates on the prod site. They are not the dev site. `--prod` deploys `firebase.json` only, so a release cannot overwrite the dev site. `tool/deploy_dev_web.dart` deploys `firebase.dev.json` and refuses `--prod`. The configs stay split so a missing dev site cannot break `firebase deploy --only hosting`.

The dev site id does not exist until someone who is logged into Firebase runs `dart run tool/deploy_dev_web.dart --create-site` once. Until then the URL is Firebase's "Site Not Found" page.

A plain `flutter build web` uses `lib/main.dart`, which stays on `dev` unless `FLAVOR` is set. Release builds pass `-t lib/main_prod.dart` so they do not publish the dev flavor to production.

### Running with Explicit Flavors
```bash
# Run in development mode (isolated dev collection)
flutter run -t lib/main_dev.dart --dart-define=FLAVOR=dev

# Run in production mode
flutter run -t lib/main_prod.dart --dart-define=FLAVOR=prod
```

---

## 🛠️ 3. One-Command Automated Release Pipeline

All release operations are consolidated into **`tool/deploy_release.dart`**. One command handles compilation, preview hosting generation, release note extraction, production deployment, and tester distribution:

```bash
# 1. Dry run: Verify release notes and command sequence without modifying anything
dart run tool/deploy_release.dart --version v0.8.0-alpha --dry-run

# 2. Preview deployment: Deploys a Firebase preview channel for internal audit
dart run tool/deploy_release.dart --version v0.8.0-alpha

# 3. Full production release: Ships Web PWA, Android APK, GitHub Release & App Distribution
dart run tool/deploy_release.dart --version v0.8.0-alpha \
  --prod \
  --github-release \
  --distribute-android \
  --highlights-file docs/release_highlights/v0.8.0-alpha.md
```

### Build identity

Every web and APK build this script compiles is stamped with three compile-time defines. The About Belong dialog reads them with `String.fromEnvironment` and shows the same values that were written into `build/web/version.json`.

| Define | Value | About dialog |
| :--- | :--- | :--- |
| `GIT_COMMIT_SHA` | Full 40-character hex from `git rev-parse HEAD` | Git commit, plus `https://github.com/neiljaywarner/refuge/commit/<sha>` |
| `BUILD_TIME_MS` | UTC Unix epoch milliseconds, captured once before `flutter build` | Build time, as ISO-8601 UTC and the same millisecond count |
| `RELEASE_TAG` | The `--version` flag (for example `v0.9.1`) | Release, when the define is non-empty |

`build/web/version.json` keeps its existing `version`, `build_number`, and `release_tag` fields and adds:

| Field | Example |
| :--- | :--- |
| `git_sha` | `0123456789abcdef0123456789abcdef01234567` |
| `build_time_ms` | `1792881722123` |
| `build_time_utc` | `2026-10-24T22:42:02.123Z` |

`--github-release` publishes those notes, so the GitHub tag's release body includes the SHA and the commit URL. The tag name stays the `--version` value.

`--skip-build` reuses artifacts already in `build/web` or `build/app`. It does not bake new defines into that binary and does not rewrite `version.json`.

A local `flutter run` that does not pass the defines shows Git commit `unknown`, build time `unknown`, and source `dev`. The app does not invent a SHA.

CI can pass the same three defines. This repository does not add a GitHub Actions deploy workflow here.

```bash
flutter build web --release \
  --dart-define=GIT_COMMIT_SHA="$GIT_COMMIT_SHA" \
  --dart-define=BUILD_TIME_MS="$BUILD_TIME_MS" \
  --dart-define=RELEASE_TAG="$RELEASE_TAG"
```

---

## ⚙️ 4. CLI Flags & Options Reference

| Flag | Default | Description |
| :--- | :--- | :--- |
| `--version` | **Required** | Release tag / version string (e.g. `v0.8.0-alpha`) |
| `--channel` | `version` (dots→dashes) | Firebase Hosting preview channel name (e.g. `v0-8-0-alpha`) |
| `--prod` | `false` | Deploys `firebase.json` to live production (`https://belongonthespectrum.web.app`). Does not read `firebase.dev.json`. |
| `--github-release` | `false` | Automatically creates/updates the official GitHub Release with changelog |
| `--distribute-android` | `false` | Builds release APK and uploads to Firebase App Distribution |
| `--android-app-id` | Auto-detected | Firebase Android App ID (`$FIREBASE_ANDROID_APP_ID`) |
| `--groups` | `pre-alpha-testers` | Tester group aliases in Firebase Console |
| `--highlights-file` | `none` | Path to custom markdown highlights prepended to release notes |
| `--attach` | `none` | Repeatable file path(s) to attach to GitHub Release (e.g. screenshots/videos) |
| `--skip-build` | `false` | Skips the Flutter build and does not re-stamp dart-defines. Deploys existing artifacts in `build/web` or `build/app` |
| `--dry-run` | `false` | Previews release notes and actions without executing builds or deploys |

---

## 🧪 5. Pre-Deployment Verification Checklist

Before running a production deployment:

1. **Verify Static Analysis**:
   ```bash
   dart analyze .
   ```
2. **Run Full Test Suite**:
   ```bash
   flutter test
   ```
3. **Verify Serverpod Backend Status**:
   ```bash
   curl -I https://refuge4serverpod.api.serverpod.space/
   ```
4. **Inspect Firebase Hosting Preview Channel**:
   Navigate to the temporary preview channel URL output by `deploy_release.dart` (e.g. `https://belongonthespectrum--v0-8-0-alpha-xyz.web.app`) and verify navigation, sensory themes, and offline caching.

---

## ⏪ 6. Rollback & Incident Recovery

If an issue arises in production:

### Instant Web Rollback (Firebase Hosting)
```bash
# View recent deployment history
firebase hosting:channel:list

# Instant rollback via Firebase Console or rollback deploy
firebase hosting:clone belongonthespectrum:<PREVIOUS_VERSION_CHANNEL> belongonthespectrum:live
```

### Serverpod Reconnect Fallback
The client code is built with resilient dual-cloud fallback: if Serverpod is unreachable, the app automatically fails over to Cloud Firestore (`reflections` collection) and local in-memory storage, ensuring zero blackouts for active community members.
