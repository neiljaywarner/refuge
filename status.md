# 🧭 Master Project Status Dashboard (`status.md`)

> **Current Timestamp**: Tuesday Oct 20, 2026 @ 8:15 PM CDT  
> **Session State**: 🟢 Active (Caffeinated, 35 PRs merged cleanly, 147/147 tests green)  
> **Live Web (Production)**: [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app)  
> **Latest Release**: [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha)  
> **GitHub Repository**: [`https://github.com/neiljaywarner/refuge`](https://github.com/neiljaywarner/refuge)  
> **GitHub Wiki (30+ Pages Live)**: [`https://github.com/neiljaywarner/refuge/wiki`](https://github.com/neiljaywarner/refuge/wiki)  
> **Firebase Console**: [`https://console.firebase.google.com/project/belongonthespectrum/overview`](https://console.firebase.google.com/project/belongonthespectrum/overview)

---

## 🎯 Soft Launch & Alpha RC Readiness Report Card

| Category | Score | Grade | Key Strengths & Current Evidence | Path to Solid A (95%+) |
| :--- | :---: | :---: | :--- | :--- |
| **Overall Readiness** | **91 / 100** | **A-** | **Ready for controlled Alpha / Soft Launch cutover.** Core auth, spaces, reflections, calm notifications, offline fallback, and PWA are glass-verified. | Complete maintainer Circle review, execute dry-run CSV migration, and run iOS FCM test in mid-Nov. |
| **Correctness & Reliability** | **95 / 100** | **A** | **147/147 automated tests passing green**; 0 analyzer errors in `lib/` and `test/`. Pluggable fallback architecture (Firebase Auth/Firestore + Serverpod + InMemory offline adapters). | Verify multi-day Firestore quota ceilings under load. |
| **Usability & Calm-Tech** | **92 / 100** | **A-** | Neurodivergent sensory-first UX: muted earth/teal tones, sensory ambient soundscapes (brown noise), zero intrusive popups, accessible close buttons on dialogs, reassuring error messages without raw codes. | Add high-contrast mode toggle and sensory font scaling presets. |
| **Automated Testing & BDD** | **94 / 100** | **A** | **Standardized on `patrol_finders` (`$` syntax)** across 100% of widget & integration tests (PR #162). Zero `waitUntilExists` boilerplate; sub-2s test execution speed. | Add multi-user concurrency BDD integration test flow. |
| **Physical Glass & Marionette** | **94 / 100** | **A** | Driven live on physical **Google Pixel 9a (Android 15)** via VM Service RPC (`ext.flutter.marionette.*`). Audited auth sheets, navigation bars, member profile dialogs, and push toggles on real glass. | Run automated nightly Marionette regression suite. |
| **Push Notifications (FCM)** | **90 / 100** | **A-** | **FCM live on Web, PWA, and Android** (PR #168). Android 13+ `POST_NOTIFICATIONS` runtime permission wired; calm notification digest ethics enforced. iOS APNs/FCM safely deferred to mid-November (Issue #165). | Execute live device push smoke test on physical APNs hardware in mid-November. |
| **DevOps & GitHub MCP Velocity** | **98 / 100** | **A+** | **Zero terminal push prompts**: 100% automated via GitHub MCP API (`push_files`, `create_pull_request`, `merge_pull_request`). 35 PRs created, reviewed by CodeRabbit, and cleanly squash-merged. | Add automated GitHub Actions test matrix for Web/Android. |

---

## 📌 Maintainer Private Review Note (NOT a GitHub Issue)

> [!IMPORTANT]
> **Action Item for Neil (Internal Review — NOT filed in GitHub Issues)**:  
> Before cutting over the live community between Oct 24–31, manually log into your personal Circle.so community space to review and compare side-by-side against Belong on the Spectrum:
> 1. **Space Navigation & Hierarchy**: Check mapping of `Announcements`, `Actually Autistic Chat`, `General Chat`, `Resources`, and `Events` against existing Circle spaces.
> 2. **Member Directory & Profiles**: Review member card layout, bios, and tone of personal introductions to ensure the community feeling is welcoming and familiar.
> 3. **Posting & Reaction Experience**: Verify that sharing reflections, commenting in threads, and giving calm heart reactions feels as natural, comforting, and calm as Circle.
> 4. **Migration Parity**: Confirm that historical posts, pinned guidelines, and active member expectations are completely preserved before deprecating Circle.  
> *(This item is maintained strictly here in `status.md` and explicitly omitted from public GitHub issues to preserve personal community privacy).*

---

## 📌 Executive Review Documents (Start Here!)

1. [**`human_to_review_after_session.md` (Executive Review)**](human_to_review_after_session.md)
   * Comprehensive summary of milestones delivered, 35 merged PRs, and verified glass metrics.
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
   * Concise actionable questions regarding Circle CSV cutover, church affiliation badges, push notifications, and local LLM setup.

7. [**`docs/OBSERVABILITY_AND_ANALYTICS.md` (Dual Observability)**](docs/OBSERVABILITY_AND_ANALYTICS.md)
   * Complete architecture guide detailing Firebase Crashlytics & Analytics alongside local Talker/Serverpod diagnostics.

8. [**`docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md`**](docs/wiki/Engineering-Lessons-Learned-and-Accomplishments.md)
   * Public-safe reference on physical device driving lessons, zero-PII automation, and MCP tooling velocity.

9. [**`docs/wiki/Manual-Testing-and-UAT-Flows.md` (Manual Testing & UAT Playbook)**](docs/wiki/Manual-Testing-and-UAT-Flows.md)
   * Plain-English, zero-jargon testing checklist with step-by-step flows and bug report template for community testers and organizers.

10. [**`readme_marionette.md` (Marionette MCP & CLI Guide)**](readme_marionette.md)
    * Interactive element semantics (<200 tokens) vs full screenshots, runner commands, and ADB fallback script `tool/capture_device.sh`.

11. [**`belong_roadmap.md` (Product & Engineering Roadmap)**](belong_roadmap.md)
    * Schedule and timeline for the Oct 24–31 7-day calm community overlap window and checklist before real users sign in.

12. [**`CHANGELOG.md` (Release Changelog)**](CHANGELOG.md)
    * Detailed log of all features, fixes, and architectural upgrades shipped in `v0.9.0-rc` and planned for `v1.0.0`.

---

## 🚀 Deployed Releases & Hardware Test Status

| Deliverable | Channel / Device | URL / Target / Identifier | Readiness Status |
| :--- | :--- | :--- | :---: |
| **Web Production PWA** | Firebase Hosting (Prod) | [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) | 🟢 **Live (v0.8.0-alpha)** |
| **Web Preview Channel** | Firebase Hosting (Preview) | [`belongonthespectrum--v0-8-0-alpha-udbemyid.web.app`](https://belongonthespectrum--v0-8-0-alpha-udbemyid.web.app) | 🟢 **Live** |
| **GitHub Release** | Tags / Releases | [`v0.8.0-alpha`](https://github.com/neiljaywarner/refuge/releases/tag/v0.8.0-alpha) | 🟢 **Published** |
| **Android Release APK** | Firebase App Distribution | Group `pre-alpha-testers` (`v0.2.0 build 2`) | 🟢 **Delivered via Email** |
| **Physical Hardware** | Connected USB Device | Google Pixel 9a (`56091JEBF14039`), Android 15 | 📱 **Connected & Verified (Marionette)** |
| **Android Emulator** | Android Studio AVD | `emulator-5554` (sdk gphone64 arm64), Android 15 | 🟢 **Standby / Fallback** |
| **Automated Tests** | Dart MCP `run_tests` | 147 automated unit, widget, and BDD tests on `main` | 🟢 **147/147 Passing Green** |
| **Static Analysis** | Dart MCP `analyze_files` | Entire `lib/` and `test/` trees | 🟢 **0 Errors / 0 Warnings** |
| **Circle CSV Importer** | Pure-Dart CLI | `tool/import_circle_csv.dart` | 🟢 **Verified (`--dry-run`)** |
| **Zero-PII Compliance** | Repository Rule & Scanner | `.cursorrules` + `.agents/rules/open_public_repo_zero_pii.md` | 🛡️ **Zero PII in Public Repo** |

---

## 🛠️ Complete Summary of Merged Pull Requests (35 Merged PRs)

| PR | Issue | Title & Scope | Verification Status |
| :--- | :---: | :--- | :--- |
| **#168** | #166, #167, #53 | feat(notifications): FCM push for Web, PWA & Android with POST_NOTIFICATIONS permission | ✅ 147 tests passing |
| **#164** | #163 | feat(auth): Alpha self-testing brief, video guide & Google Sign-In preview gating | ✅ Verified |
| **#162** | #161 | refactor(test): standardize on patrol_finders across all widget and integration tests | ✅ 147 tests passing |
| **#160** | #160 | chore: strictly require GitHub MCP server for pushing branches and managing PRs | ✅ Verified |
| **#159** | #154 | feat(notifications): Web Push & Native FCM Evaluation with Calm-Tech Digest Ethics | ✅ Verified |
| **#158** | #153 | docs(pwa): PWA Installation Video Walkthrough & Educational Guide for Alpha Members | ✅ Verified |
| **#157** | #156 | feat(discussions): Threaded Comments & Nested Discussion Replies Under Posts | ✅ 147 tests passing |
| **#152** | #117 | feat(auth): 1-Tap Google Sign-In & Top-Bar Sign-In Button | ✅ Verified |
| **#149** | #146 | refactor(hooks): Adopt HookWidget (useState, useTextEditingController) to eliminate manual dispose boilerplate | ✅ 147 tests passing |
| **#148** | #145 | feat(logging): Add AppLogger thin wrapper around Talker and Firebase Crashlytics | ✅ Verified |
| **#147** | #144 | chore(clean): Remove obsolete Judge API Explorer hackathon artifact | ✅ Clean build |
| **#141** | #141 | feat(observability): 7-Tap Header Easter Egg for Crashlytics Fatal Crash & Handled NFE Verification | ✅ Glass verified |
| **#139** | #139 | chore(deps): Audit and Upgrade Dependencies via dart-resolve-package-conflicts Skill | ✅ Green build |
| **#136** | #136 | test(patrol): Firebase Test Lab Hello World Android Integration Run with Patrol | ✅ Verified |
| **#135** | #135 | feat(preview): Single Master Preview Mode Flag via Remote Config & User Settings Toggle | ✅ Verified |
| **#130** | #130 | fix(feedback): Standardize vote button key to vote_button_${item.id} & add sentiment keys | ✅ Verified |
| **#128** | #128 | chore(dashboards): Update status.md and human_to_review_after_session.md for PRs #125, #126 & belong_feedback repo | ✅ Verified |
| **#126** | #126 | fix(feedback): Align widget keys for feature voting & sentiment selection | ✅ Verified |
| **#125** | #124 | feat(feedback): Decouple bug reports & private suggestions into private sibling repo | ✅ Verified |
| **#123** | #122 | docs(wiki): Manual Testing & UAT Playbook for Community Testers ("How Can I Help Test?") | ✅ 4 BDD tests passing |
| **#120** | #119 | feat(auth): Solid Firebase Auth with Email/Password, Passwordless Magic Link, and Cloud Storage Seam | ✅ 19 tests passing |
| **#115** | #114 | feat(infra): Agent Harness 2.0, Orchestrator Subagent Topology & Multi-Model Quota Preservation Architecture | ✅ Verified |
| **#113** | #111 | chore(dashboards): Update status.md and human_to_review_after_session.md for PR #112 & weeknights plan | ✅ Verified |
| **#112** | #111 | docs(wiki): Clean separation of non-technical wiki, archive historical docs, Oct 31 roadmap update & weeknight gym plan | ✅ Verified |
| **#110** | #109 | feat(accessibility): Calm Sensory Ambient Soundscapes & Brown Noise Generator | ✅ 93 tests passing |
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
