# 🧪 QA, Automated Testing (`patrol_finders` BDD + TDD) & Firebase App Distribution Guide

*Last Updated: October 18, 2026 (`2026-10-18T20:03:00-05:00`)*
*Canonical Repo Guides: [`docs/automated_testing_guide.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/automated_testing_guide.md) & [`docs/ticket_driven_development.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/ticket_driven_development.md)*

---

## 🧭 1. Our Testing Pyramid: `patrol_finders` BDD + Pragmatic TDD + Integration Tests

| Test Layer | Share of Suite | Tooling | When We Use It |
| :--- | :---: | :--- | :--- |
| **1. BDD Widget Tests + `patrol_finders` (`$`)** | **~80%** | `flutter_test`, `patrol_finders` (`patrolWidgetTest`), `bdd_widget_test` (`.feature` files) | **Default for all UI screens & community user journeys.** Runs headlessly in <2 seconds with readable `$('Geek Out!').tap()` syntax and zero emulator startup wait! |
| **2. Pragmatic Unit TDD** | **~15%** | `flutter_test` (`test()`) | **Strictly for real business logic:** `CommunityBrandConfig`, `OrganizerRemoteConfigService` fallbacks, `FeatureVotingNotifier` vote math, and Circle.so `.csv` import parsing. Never used for trivial UI boilerplate. |
| **3. End-to-End Integration & Live Device QA** | **~5%** | `integration_test`, `patrol` CLI/MCP, `marionette_mcp` | **Critical multi-platform smoke flows** (FCM Push permissions, Google/Apple Sign-In sheets, and PR screenshot/video capture) on Chrome Web, Pixel 9a Android, and iOS Simulator. |

---

## 📦 2. Pre-Release Distribution: Firebase Hosting Preview Channels & Firebase App Distribution (Android + iOS)

Before publishing to the public Google Play Store (`#45`) or Apple App Store (`#46`), we distribute early `v0.5.5`, `v0.6.0-alpha`, and `v0.8.0-alpha` builds to organizers and early welcomers using **three complementary channels**:

### A. Web & PWA: Firebase Hosting Preview Channels (Instant — Zero Install Friction)
- Every PR and alpha milestone (`v0.5.5`, `v0.6.0-alpha`, `v0.8.0-alpha`) deploys to an isolated **Firebase Hosting Preview Channel**:
  ```bash
  flutter build web --release -t lib/main_dev.dart
  firebase hosting:channel:deploy v0-5-5-alpha
  ```
- Works immediately on **Desktop Chrome/Safari, iOS Safari ("Add to Home Screen"), and Android Chrome** with a shareable URL.

### B. Android Beta Testers: Firebase App Distribution (APK / AAB)
- Organizers and Android beta testers receive instant over-the-air APK builds via **Firebase App Distribution** without waiting for Google Play Store review:
  ```bash
  flutter build apk --release -t lib/main_dev.dart
  firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
    --app <ANDROID_FIREBASE_APP_ID> --groups "belong-organizers,early-welcomers"
  ```

### C. iOS Beta Testers: Firebase App Distribution for iOS vs. Apple TestFlight (`#44`)
How does **Firebase App Distribution for iOS** work, and when should organizers use it alongside **TestFlight**?

| Feature | Firebase App Distribution for iOS (Ad-Hoc `.ipa`) | Apple TestFlight (`Issue #44`) |
| :--- | :--- | :--- |
| **Apple Developer Account Required?** | **Yes** ($99/yr Apple Developer Program to sign Ad-Hoc provisioning profiles). | **Yes** ($99/yr Apple Developer Program). |
| **Device UDID Registration** | **Required** (Up to 100 iPhones/iPads per year; When a tester accepts the Firebase email invite on their iPhone, Firebase automatically captures their device UDID so you can add it to your Ad-Hoc profile). | **Not Required** (Up to 10,000 external testers via a simple public TestFlight link). |
| **Apple Beta App Review Wait Time** | **0 minutes (Instant!)** — As soon as `flutter build ipa --export-method ad-hoc` uploads to Firebase, testers can install it immediately. | **24–48 hours** for the first build of a new version. |
| **Best Use Case for Belong** | **Inner-circle organizer & developer testing (`v0.5.5` – `v0.8.0-alpha`)** when you want unified release notes, crashlytics symbols, and instant installs across Android + iOS in one Firebase console. | **Broader community iPhone testing (`v0.9.0-beta`+)** where members just tap a public TestFlight link without registering UDIDs. |
| **Zero-$99 Alternative Today** | **iOS Safari PWA ("Add to Home Screen")** — Costs **$0**, requires **zero UDIDs**, and works tonight for 100% of iPhone members! | — |

---

## 📸 3. Visual Evidence on Every GitHub Issue & PR (Screenshots & Video Walkthroughs)

To make this repository a joy for non-technical organizers and student mentees to follow, we attach **screenshots and short video walkthroughs** directly to our GitHub Issues and Pull Requests (`v0.5.5`, `v0.6.0`, `v0.8.0-alpha`):
- **Chrome Web**: Automated screenshots & recordings via Marionette / Playwright / Flutter Web renderer.
- **Android (Pixel 9a / Emulator)**: `patrol` MCP `screenshot` tool + `adb shell screenrecord`.
- **iOS Simulator**: `xcrun simctl io booted screenshot` + `xcrun simctl io booted recordVideo`.

---

## 🤖 4. CodeRabbit Automated AI Review & PR Wait Protocol

Every PR merged to `main` undergoes automated AI code review via `@coderabbitai`. To prevent race conditions and ensure all potential defects are surfaced before merging, all agents and contributors follow this protocol:

### A. The Review Trigger & Cloud Processing Window
1. **Trigger**: When a PR is created, post `@coderabbitai review` via GitHub issue comment.
2. **Cloud Processing Wait**: CodeRabbit takes between 60 to 180 seconds to build the AST diff, perform security checks, and post line-by-line review comments.
3. **Never Squash-Merge While Processing**:
   - Check `pull_request_read(method: 'get_comments')`.
   - If CodeRabbit's latest comment is `"Review in progress by coderabbit.ai"` or `"Currently processing new changes in this PR"`, **wait** for the final summary comment.
   - Premature merging immediately aborts CodeRabbit with `"Action not completed: Pull request is closed"`.

### B. Triage Matrix
- **Critical / Blocking**: Regressions, unhandled nulls, security vulnerabilities, or broken builds must be fixed immediately in the PR branch.
- **Polish / Architectural Debt**: Non-critical suggestions are deferred into dedicated GitHub issues or referenced in Issue `#36` (CodeRabbit Release Audit Gate).

### C. Full Codebase Review
To request a comprehensive architectural and quality review across the full codebase:
- Use `@coderabbitai full review` or prompt CodeRabbit with specific audit questions directly on a PR comment.
- Review its findings, triage recommendations, and file dedicated GitHub issues for high-value items.
