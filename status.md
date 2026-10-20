# 🧭 Master Project Status Dashboard (`status.md`)

> **Current Timestamp**: Monday Oct 19, 2026 @ 7:05 PM CDT  
> **Session State**: 🟢 Active (System caffeinated, 17 PRs merged cleanly)  
> **Live Web (Production)**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Latest Release**: [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha)  
> **GitHub Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **GitHub Wiki (26+ Pages Live)**: [`https://github.com/neiljaywarner/refuge/wiki`](https://github.com/neiljaywarner/refuge/wiki)  
> **Firebase Console**: [`https://console.firebase.google.com/project/belongonthespectrum/overview`](https://console.firebase.google.com/project/belongonthespectrum/overview)

---

## 📌 Executive Review Documents (Start Here!)

1. [**`human_to_review_after_session.md` (Executive Review)**](human_to_review_after_session.md)
   * Comprehensive summary of milestones delivered, 17 merged PRs, and verified glass metrics.
   * Links directly to maintainer questions in [`questions_19_oct_evening.md`](questions_19_oct_evening.md).

2. [**`questions_19_oct_evening.md` (Decision Items)**](questions_19_oct_evening.md)
   * 5 concise, actionable questions for Neil regarding Circle CSV migration cutover, church affiliation badges, push notifications, and local LLM setup.

3. [**`docs/OBSERVABILITY_AND_ANALYTICS.md` (Dual Observability)**](docs/OBSERVABILITY_AND_ANALYTICS.md)
   * Complete architecture guide detailing Firebase Crashlytics & Analytics alongside local Talker/Serverpod diagnostics.

4. [**`docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md`**](docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md)
   * Public-safe reference on physical device driving lessons, zero-PII automation, and MCP tooling velocity.

---

## 🚀 Deployed Releases & Hardware Test Status

| Deliverable | Channel / Device | URL / Target / Identifier | Readiness Status |
| :--- | :--- | :--- | :---: |
| **Web Production PWA** | Firebase Hosting (Prod) | [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) | 🟢 **Live (v0.8.0-alpha)** |
| **Web Preview Channel** | Firebase Hosting (Preview) | [`belongonthespectrum--v0-8-0-alpha-udbemyid.web.app`](https://belongonthespectrum--v0-8-0-alpha-udbemyid.web.app) | 🟢 **Live** |
| **GitHub Release** | Tags / Releases | [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha) | 🟢 **Published** |
| **Android Release APK** | Firebase App Distribution | Group `pre-alpha-testers` (`v0.2.0 build 2`) | 🟢 **Delivered via Email** |
| **Physical Hardware** | Connected USB Device | Google Pixel 9a (`56091JEBF14039`), Android 15 | 📱 **Connected & Verified** |
| **Automated Tests** | Dart MCP `run_tests` | 82 automated unit, widget, and BDD tests | 🟢 **82/82 Passing Green** |
| **Circle CSV Importer** | Pure-Dart CLI | `tool/import_circle_csv.dart` | 🟢 **Verified (`--dry-run`)** |
| **Zero-PII Compliance** | Repository Rule & Scanner | `.cursorrules` + `.agents/rules/open_public_repo_zero_pii.md` | 🛡️ **Zero PII in Public Repo** |

---

## 🛠️ Complete Summary of Merged Pull Requests (17 Merged PRs)

| PR | Issue | Title & Scope | Verification Status |
| :--- | :---: | :--- | :--- |
| **#98** | #41 | feat(migration): Circle.so CSV Data Migration Importer CLI & Parser | ✅ 82 tests passing |
| **#97** | #96 | fix(main): Provide bootstrapBelongApp backward compatibility and resolve unused imports | ✅ 71 tests passing |
| **#95** | #95 | fix(main): Restore reflection presentation re-exports and SanctuaryApp overrides | ✅ Verified |
| **#94** | #93 | feat(profile): Add required ICOC church affiliation field and Members Section | ✅ 71 tests passing |
| **#91** | #90 | refactor(logging): Standardize on Talker over developer.log in ErrorReporterService | ✅ Verified |
| **#89** | #88 | refactor(ui): Remove 'Email Organizer Directly' button from feedback sheet | ✅ Verified |
| **#87** | #84, #85 | feat(observability): Triple error reporting & v0.8.1 analytics | ✅ Verified |
| **#82** | #81 | fix(ui): Apply SafeArea and dynamic bottom padding to modal sheets | ✅ Verified |
| **#78** | #63 | feat(release): Add --attach support to deploy pipeline and clean lint warnings | ✅ Verified |
| **#77** | #52, #26 | feat(backend): Wire live Cloud Firestore & Firebase Auth adapters for shared alpha persistence | ✅ Verified |
| **#76** | #27, #28 | feat(messages,events): Direct Messages (Msgs), Calm Notifications, and Actually Autistic Events | ✅ 56 tests passing |
| **#74** | #73 | test(e2e): Marionette binding, on-device Pixel 9a test, Riverpod crash fix, chip squeeze fix | ✅ Physical device glass verified |
| **#71** | #69 | fix(android): remove unused firebase_in_app_messaging so release APK builds | ✅ Release APK verified |
| **#68** | #65 | chore(release): truthful release notes from merged PRs, Android App Distribution to pre-alpha-testers | ✅ Build 2 delivered |
| **#62** | #26 | feat(auth): Stage 1 Any Auth session, pluggable AuthRepository adapters | ✅ 48 tests passing |
| **#61** | #52 | feat(voting): Feature Voting clean repository seam (InMemory, Serverpod, Appwrite, Firebase) | ✅ 37 tests passing |
| **#60** | #56 | feat(deploy): Minimum pure-Dart deployment pipeline (`tool/deploy_release.dart`), DEPLOYMENT.md | ✅ Live Web PWA deployed |
