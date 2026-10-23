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

| Flavor | Environment | Database Collection | Serverpod URL | Target Audience |
| :--- | :--- | :--- | :--- | :--- |
| **`dev`** | Development & CI | `reflections_dev` | `https://refuge4serverpod.api.serverpod.space/` (or local `http://10.0.2.2:8080/`) | Automated BDD tests, local emulators, continuous integration |
| **`stg`** | Staging | `reflections_stg` | Staging cluster | Pre-release rehearsal |
| **`prod`** | Production | `reflections` | `https://refuge4serverpod.api.serverpod.space/` | Real community members & churches |

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

---

## ⚙️ 4. CLI Flags & Options Reference

| Flag | Default | Description |
| :--- | :--- | :--- |
| `--version` | **Required** | Release tag / version string (e.g. `v0.8.0-alpha`) |
| `--channel` | `version` (dots→dashes) | Firebase Hosting preview channel name (e.g. `v0-8-0-alpha`) |
| `--prod` | `false` | Deploys directly to live production (`https://belongonthespectrum.web.app`) |
| `--github-release` | `false` | Automatically creates/updates the official GitHub Release with changelog |
| `--distribute-android` | `false` | Builds release APK and uploads to Firebase App Distribution |
| `--android-app-id` | Auto-detected | Firebase Android App ID (`$FIREBASE_ANDROID_APP_ID`) |
| `--groups` | `pre-alpha-testers` | Tester group aliases in Firebase Console |
| `--highlights-file` | `none` | Path to custom markdown highlights prepended to release notes |
| `--attach` | `none` | Repeatable file path(s) to attach to GitHub Release (e.g. screenshots/videos) |
| `--skip-build` | `false` | Skips build step, deploying existing artifacts in `build/web` or `build/app` |
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
