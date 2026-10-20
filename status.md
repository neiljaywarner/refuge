# 🧭 Master Project Status Dashboard (`status.md`)

> **Current Timestamp**: Monday Oct 19, 2026 @ 8:28 PM CDT  
> **Session State**: 🟢 Active (Caffeinated, 24 PRs merged cleanly, Issue #122 Manual Testing & UAT Playbook in progress)  
> **Live Web (Production)**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Latest Release**: [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha)  
> **GitHub Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **GitHub Wiki (29+ Pages Live)**: [`https://github.com/neiljaywarner/refuge/wiki`](https://github.com/neiljaywarner/refuge/wiki)  
> **Firebase Console**: [`https://console.firebase.google.com/project/belongonthespectrum/overview`](https://console.firebase.google.com/project/belongonthespectrum/overview)

---

## 📌 Executive Review Documents (Start Here!)

1. [**`human_to_review_after_session.md` (Executive Review)**](human_to_review_after_session.md)
   * Comprehensive summary of milestones delivered, 23 merged PRs, and verified glass metrics.
   * Links directly to maintainer questions in [`questions_19_oct_evening.md`](questions_19_oct_evening.md).

2. [**`docs/AGENT_HARNESS_AND_ORCHESTRATION.md` (Agent Harness 2.0 Spec)**](docs/AGENT_HARNESS_AND_ORCHESTRATION.md)
   * Multi-model quota routing, subagent orchestrator topology, 📿 "Beads" execution DAG, and local 48GB Mac fallback.

3. [**`docs/wiki/Agent-Harness-and-Token-Orchestration.md` (Token Optimization Wiki)**](docs/wiki/Agent-Harness-and-Token-Orchestration.md)
   * Visual Knowledge Graph & multi-model quota defense guide for students, mentees, and engineers.

4. [**`weeknights_week_of_oct19th.md` (Weeknights Gym & Low-Touch Protocol)**](weeknights_week_of_oct19th.md)
   * Daily 5–10 minute human check-in protocol allowing autonomous agents to deliver milestones while Neil attends the gym.

5. [**`docs/wiki/Circle-CSV-Migration-Guide.md` (Spreadsheet Migration Guide)**](docs/wiki/Circle-CSV-Migration-Guide.md)
   * Plain-English explanation of past posts/introductions import for non-technical community organizers.

6. [**`questions_19_oct_evening.md` (Decision Items)**](questions_19_oct_evening.md)
   * 5 concise, actionable questions for Neil regarding Circle CSV migration cutover, church affiliation badges, push notifications, and local LLM setup. Tracked in [Issue #101](https://github.com/neiljaywarner/refuge/issues/101).

7. [**`docs/OBSERVABILITY_AND_ANALYTICS.md` (Dual Observability)**](docs/OBSERVABILITY_AND_ANALYTICS.md)
   * Complete architecture guide detailing Firebase Crashlytics & Analytics alongside local Talker/Serverpod diagnostics.

8. [**`docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md`**](docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md)
   * Public-safe reference on physical device driving lessons, zero-PII automation, and MCP tooling velocity. Tracked in [Issue #102](https://github.com/neiljaywarner/refuge/issues/102).

9. [**`docs/wiki/Manual-Testing-and-UAT-Flows.md` (Manual Testing & UAT Playbook)**](docs/wiki/Manual-Testing-and-UAT-Flows.md)
   * Plain-English, zero-jargon testing checklist with step-by-step flows and bug report template for community testers and organizers. Tracked in [Issue #122](https://github.com/neiljaywarner/refuge/issues/122).

10. [**`readme_marionette.md` (Marionette MCP & CLI Guide)**](readme_marionette.md)
   * Interactive element semantics (<200 tokens) vs full screenshots, runner commands, and ADB fallback script `tool/capture_device.sh`.

---

## 🚀 Deployed Releases & Hardware Test Status

| Deliverable | Channel / Device | URL / Target / Identifier | Readiness Status |
| :--- | :--- | :--- | :---: |
| **Web Production PWA** | Firebase Hosting (Prod) | [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) | 🟢 **Live (v0.8.0-alpha)** |
| **Web Preview Channel** | Firebase Hosting (Preview) | [`belongonthespectrum--v0-8-0-alpha-udbemyid.web.app`](https://belongonthespectrum--v0-8-0-alpha-udbemyid.web.app) | 🟢 **Live** |
| **GitHub Release** | Tags / Releases | [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha) | 🟢 **Published** |
| **Android Release APK** | Firebase App Distribution | Group `pre-alpha-testers` (`v0.2.0 build 2`) | 🟢 **Delivered via Email** |
| **Physical Hardware** | Connected USB Device | Google Pixel 9a (`56091JEBF14039`), Android 15 | 📱 **Connected & Verified** |
| **Android Emulator** | Android Studio AVD | `emulator-5554` (sdk gphone64 arm64), Android 15 | 🟢 **Active (PID 35776, DTD connected)** |
| **Automated Tests** | Dart MCP `run_tests` | 82 automated unit, widget, and BDD tests on `main` (93 in soundscape branch) | 🟢 **82/82 Passing Green** |
| **Circle CSV Importer** | Pure-Dart CLI | `tool/import_circle_csv.dart` | 🟢 **Verified (`--dry-run`)** |
| **Zero-PII Compliance** | Repository Rule & Scanner | `.cursorrules` + `.agents/rules/open_public_repo_zero_pii.md` | 🛡️ **Zero PII in Public Repo** |

---

## 🛠️ Complete Summary of Merged Pull Requests (24 Merged PRs)

| PR | Issue | Title & Scope | Verification Status |
| :--- | :---: | :--- | :--- |
| **#120** | #119 | feat(auth): Solid Firebase Auth with Email/Password, Passwordless Magic Link, and Cloud Storage Seam | ✅ 19 tests passing |
| **#115** | #114 | feat(infra): Agent Harness 2.0, Orchestrator Subagent Topology & Multi-Model Quota Preservation Architecture | ✅ Verified |
| **#113** | #111 | chore(dashboards): Update status.md and human_to_review_after_session.md for PR #112 & weeknights plan | ✅ Verified |
| **#112** | #111 | docs(wiki): Clean separation of non-technical wiki, archive historical docs, Oct 31 roadmap update & weeknight gym plan | ✅ Verified |
| **#108** | #107 | chore(rules): Add AGENTS.md, GEMINI.md, and .cursorrules for zero-PII and MCP server prioritization | ✅ Verified |
| **#106** | #105 | docs(architecture): Add ADR-0010 Calm Notifications Architecture & Multi-Tier Test Coverage Plan | ✅ Verified |
| **#104** | #103 | docs: Add Marionette MCP server & CLI driving guide and capture script | ✅ Verified |
| **#100** | #99 | docs(wiki): Document Firebase & Serverpod dual observability and track engineering lessons learned | ✅ Verified |
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

---

## 💡 Active Idea Proposals for Maintainer Review

| PR | Issue | Title & Concept | Status |
| :--- | :---: | :--- | :--- |
| **#110** | #109 | `[Idea] feat(accessibility): Calm Sensory Ambient Soundscapes & Brown Noise Generator` | 💡 Open for Review (93 tests passing) |
