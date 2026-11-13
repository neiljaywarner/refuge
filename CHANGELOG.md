# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

Notable changes are documented in this file. As of **November 1, 2026**, the October 24–31 overlap window is past. The short list still open for a solid 1.0 is [issue #765](https://github.com/neiljaywarner/refuge/issues/765) and [`docs/solid_1.0_checklist.md`](docs/solid_1.0_checklist.md). Entries below v0.9.9 are history.

A public read of production `version.json` on **11 November 2026** reports **v0.9.9** (`dc99aaa56e3c9bcec4368e161f1149490bed7376`, flavor `prod`, built `2026-11-04T05:53:43.552Z`). The dev site the same day reports `3af3d5a2e108bba7aa55dc157df67054ce90b865` (current `main`, flavor `dev`). Member-facing notes: [`docs/release_highlights/unreleased-since-v0.9.9.md`](docs/release_highlights/unreleased-since-v0.9.9.md). Release checklist: [#937](https://github.com/neiljaywarner/refuge/issues/937).

---

## [Unreleased — on main since v0.9.9 (11 November 2026)]

Not in production. Ten commits after tag `v0.9.9` (`dc99aaa`). Last GitHub Release is still the pre-release `v0.9.3` (2026-10-29). Tags `v0.9.4`–`v0.9.9` exist and are not GitHub Releases. No Play Store or App Store "what's new" file exists in this repo.

### Added

- **Giphy animated text** on Web, Android WebAPK, and iOS PWA (`HttpGiphySearch.animateText` → Giphy `/v1/text/animate`, `m`/`s` params, PG ceiling, 12-item limit, 50-character cap). `GiphyPickerMode` chips on `GiphySearchPanel`. Attached subtitle `GIPHY animated text · rated PG`. Unit tests, widget tests, and `.maestro/web/attach_media_animated_text_web.yaml`. (#861 / PR #862)

### Fixed

- **System text scale is multiplied with the sensory preset, with no clamp.** Sign-in, home, reflections, messages, sensory settings, and feedback stay on a 390×844 surface at scales 1.0, 1.3, 2.0, and 3.0. `pumpWithTextScale` fails on overflow. Gherkin: `test/features/accessibility/large_text.feature`. Device leftovers (crushed feed viewport, row clipping, mid-word nav labels, truncated app bar) are [#932](https://github.com/neiljaywarner/refuge/issues/932). Call-UI coverage at scale 2.0 is [#935](https://github.com/neiljaywarner/refuge/issues/935), after video calling merges. (#927 / PR #934)
- **Who-reacted keeps names the device already has when the Relate count is 1.** `retainKnownReactors` copies those names onto a later count-only row while the count is still positive. When `known` is empty it returns the incoming map unchanged, so a fresh device with only a count still has no name to show. The Firestore reader no longer invents an Encouraged count of 1 with an empty member list when the reactions map already says Relate (`encouragedCount` is the shared column). Comment merge keeps the relating member the same way. (#931 / PR #933)
- **DM recipient picker uses `isMemberEligibleForDirectory`.** Hidden when `listedInDirectory` is false, the uid is banned or soft-deleted, or the uid is in the excluded set. The signed-in member is omitted. (#813)
- **CodeRabbit follow-up hardening** (#857):
  - `uploadDiagnosticLogs` is guarded in `FirebaseStorageRepository`.
  - Notifications: `clearFcmToken`, an honest web fallback, and an `isWebPushUnavailable` banner. Sheet layout restored.
  - `dm-mirror` and `dm-push` cert cache: in-flight loads coalesce, `no-store` is respected, unknown `kid` has a cooldown.
  - Feedback retry dedupes Firestore writes on `submissionId`.
  - CI: Java 21 for the Firebase emulator, format check scoped to changed Dart files, and `post_creation_menu_test`, `feed_sort_controls_test`, and `member_profile_activity_counters_test` excluded from the widget manifest.

### Tests

- Giphy REST client coverage for the iOS PWA and web GIF picker (`test/features/memes/giphy_search_test.dart` only). (#836)

### Docs

- Partner infographic (`docs/wiki/images/business-partner-infographic.svg`), `docs/wiki/Business-Partner-Overview.md`, and `docs/wiki/Circle-Competitor-Scorecard-and-90-Day-Partner-Playbook.md`. (#922 / PR #923)
- Leave-alone free backends: prefer Supabase Free because dashboard visits and API or database requests count. A quiet Free project can still pause. Appwrite Free pauses after 7 days without Console development activity, and runtime traffic does not count. The live member store stays Firestore. New page `docs/wiki/Leave-Alone-Free-Backends.md`. (#906 / PR #907)
- Sanitized November 2026 working-chat archive in `docs/chat-transcripts/` (`README.md`, session notes, token-analysis markdown and the allow-listed CSV). Not product documentation. No `raw/` folder. `.gitignore` still blocks other CSVs. (#880 / PR #881)

### CI

- `actions/setup-java` bumped from 4 to 6 in the github-actions group. (PR #921)

### Not in this cut

Open on purpose: preview GetStream calls and guest join ([#905](https://github.com/neiljaywarner/refuge/pull/905), dev-gated, guest join off in a production build), session-audit admission ([#873](https://github.com/neiljaywarner/refuge/pull/873) for [#863](https://github.com/neiljaywarner/refuge/issues/863)), and screen sharing stacked on #905 ([#930](https://github.com/neiljaywarner/refuge/pull/930)).

---

## [v0.9.9 — 1.0 Release Candidate: Auth Help & About + Bruce Usability Parity (Nov 3, 2026)]

Production: https://belongonthespectrum.web.app · Dev Preview: https://dev-belongonthespectrum.web.app · Release: `0.9.9+9990`

### Added
- **Auth Screen Help & About Action**: Accessible, neurodivergent-affirming Help & About button and modal sheet available across `BelongAuthSheet`, `BelongFirebaseSignInScreen`, and `SimpleAuthScreen` (#855 / PR #856).
- **Environment & Build Transparency**: Live dialog displays active environment badge (Pre-Prod/Dev vs Production), semantic build code (`v0.9.9+9990`), and direct cross-environment navigation button to toggle between dev preview and production web apps (#855).
- **Sensory & Diagnostics Shortcut**: 1-tap route to complete sensory settings and `Talker` diagnostic logs from pre-login screens.
- **Bruce Playtester Usability Refinements**:
  - **1-Tap Prayer Sanctuary Re-Entry**: Prominent, persistent Prayer Sanctuary tile pinned at the top of Spaces directory and persistent navigation breadcrumb (#846 / PR #847).
  - **Expanded Intent Tags**: Added `[General Chat]`, `[Fellowship]`, and `[Other]` intent tags across post composer, chips, and feed filter menus (#848 / PR #849).
  - **"Saved for Later" Explainer**: Onboarding banner, explainer guide, and `[View Saved]` SnackBar confirmation (#850 / PR #851).
  - **Local Feedback Receipts ("What I Entered")**: Honest, persistent history cards for submitted feedback receipts in `belong_feedback_and_voting_sheet.dart` (#852 / PR #854).

### Verified
- 253/253 core unit, widget, and feature tests green.
- Deployed and live verified on `belongonthespectrum.web.app` and `dev-belongonthespectrum.web.app`.
- Live Android APK verified on `emulator-5554` with visual audit screenshots.

---

## [v0.9.3 — Clean Notification Bell (Oct 29, 2026)]

Highlights: [`docs/release_highlights/v0.9.3.md`](docs/release_highlights/v0.9.3.md)

### Fixed
- Production no longer seeds five sample notifications. New accounts start with an empty bell and no badge. Dev and tests keep the samples (#685).

### Docs
- `docs/wiki/deployment.md` has a copy-paste production release runbook (preview, smoke test, promote, verify, rollback).

---

## [v0.9.2 — Members-Only Alpha for Real Testers (Oct 28, 2026)]

Production: https://belongonthespectrum.web.app · Highlights: [`docs/release_highlights/v0.9.2.md`](docs/release_highlights/v0.9.2.md)

### Added
- Cross-member Firestore comments (read/watch + `comments_dev` split) and care reactions for any member, with reaction-only security rules (#662 / PR #677).
- Save for Later persistence (SharedPreferences + `users/{uid}/saved_posts`), Undo SnackBar, origin space badge (#669 / PR #670).
- Verify-email wall status messages and busy guard (#661 / PR #678).
- Compact home header: welcome banner on top, Space/Filter/Sort pop-ups (#671 / PR #675).
- Clean Member Profile with first/last name, avatar, and full account delete (#672 / PR #676).
- Direct messages with real recipients, closed-app push via Appwrite `dm-push` (#441, #625, #624 / PR #630).
- Member self-delete and return, Circle-style admin ban (#550, #592, #585).
- Photo crop/zoom, password show/hide, sticky space room title and breadcrumb (#587, #593, #618).

### Changed
- Sign-in is required. Firestore has no guest or anonymous access. Production requires email verification (#575, #605, #668).
- Serverpod Cloud is off. Firebase Auth and Firestore are the backend (#546).
- Main deploys the dev site only. Production deploys only on a release (#586).
- Feedback Firestore write is bounded by a 6 s timeout. Appwrite MCP config added (#655 / PR #658).

### Fixed
- Monastic Dark contrast, narrow-web Vote & Feedback hit target, browser Back navigation, composer overflow (#617, #619, #499, #557, #568).

### Known follow-ups
- #681 order-dependent flakes in the CI manifest. #679 commit `pubspec.lock`. #659 Appwrite bridge from feedback to GitHub issues. #664 starter posts for empty spaces.

---

## [Earlier milestone — `v0.9.5-rc` / Release Readiness Gate & Cutover Sync (Oct 21–22, 2026)]

### 🚀 Major Accomplishments & Cutover Enhancements (Oct 21–22, 2026)

#### 1. Circle App Store Review Sentiment Audit & Benchmark CLI (PR #256 / #255)
- **Competitive Synthesis (`docs/benchmarks/circle_app_store_review_learnings.md`)**:
  - Audited Google Play Store (`so.circle.circle`, 1M+ downloads) and Apple App Store (`id=1506475653`) user reviews.
  - Documented top mistakes made by Circle to avoid: aggressive notification barrage, sluggish webview scroll jitter, deep back-stack disorientation, renewal/paywall dead-ends, and video freezes.
  - Formulated calm-tech counter-measures: opt-in digests, 100% native Flutter Impeller 60/120fps engine, persistent bottom navigation tabs, and sensory theme controls.
- **Pure-Dart Review Ingestion CLI (`tool/analyze_app_reviews.dart`)**:
  - Implemented zero-dependency CLI tool parsing public Apple Customer Reviews RSS JSON feeds.
  - Automatically classifies feedback into 6 taxonomy buckets and enforces Zero-PII author masking (`C****************8`).
  - Added unit test suite in `test/tool/analyze_app_reviews_test.dart` (4/4 passed).

#### 2. Non-Destructive Pixel 9a Maestro Discovery Flow (PR #256 / #255)
- **Defensive Declarative Flow (`.maestro/circle_app_discovery_careful.yaml`)**:
  - Designed read-only discovery flow targeting `appId: so.circle.circle` on connected Google Pixel 9a hardware.
  - Strictly enforces `clearState: false` to preserve the maintainer's live community login.
  - Zero state mutations: never taps post, publish, leave, or sign-out touchpoints.
  - Established clean-framing protocol (`sips` 1080x2160 crop) to strip status bars and navigation pills.
  - Created operational runbook in `docs/benchmarks/circle_maestro_driving_guide.md`.

#### 3. Circle Migration Welcome Announcement & Documentation Repair (PR #258 / #257)
- **Community Invitation Post (`docs/circle_migration_invitation_post.md`)**:
  - Authored official ready-to-copy community welcome post for Circle.so to initiate the Oct 24–31 overlap week ([Issue #249](https://github.com/neiljaywarner/refuge/issues/249)).
  - Resolved 404 dead link across `docs/wiki/Circle-CSV-Migration-Guide.md`, `docs/wiki/How-You-Can-Help-Volunteer-Guide.md`, and maintainer dashboards.
  - Verified all internal and external markdown links resolve without error.

#### 4. Member Profile & Auth Suite Hardening (PR #260 / #259)
- **Compilation Typo & Test Suite Repair**:
  - Fixed `mainAxisSize: minAxisSize` syntax bug in `lib/src/features/profile/presentation/member_profile_sheet.dart`.
  - Restored `'Member Profile & Sign-In'` title and required widget keys (`profile_sheet_close_button`, `profile_affiliation_error_text`).
  - 100% green: **32/32 tests passing** across profile and auth suites (`member_profile_test`, `member_profile_widget_test`, `belong_auth_sheet_widget_test`, `firebase_auth_repository_test`, `stage_1_auth_test`, `simple_auth_test`).

#### 5. CodeRabbit Completion Wait Protocol Enforced (PR #248 / #247)
- Codified minimum 90–180s review wait protocol in `AGENTS.md`, `GEMINI.md`, and `QA-and-Beta-Testing-Guide.md` to guarantee zero premature squash-merges while CodeRabbit analyzes AST diffs in the cloud.

---

## [Release — `v0.9.1-rc` / Pre-1.0 Telemetry, Maestro & DM Epic (Oct 21, 2026)]

### 🚀 Major Accomplishments (Oct 21, 2026)

#### 1. Multi-Vendor Telemetry Pipeline (Firebase, Aptabase, PostHog) (PR #221, #222)
- **3-Tiered Telemetry Engine (`CommunityAnalyticsService`)**:
  - Implemented parallel fanout to Firebase Analytics (GA4/DebugView), Aptabase (privacy-first REST), and PostHog (event funnels).
  - All dispatches use fire-and-forget `unawaited(...)` from `dart:async` ensuring zero UI latency or frame blocking.
  - Zero hardcoded secrets in repository: runtime ingestion via `--dart-define` (`APTABASE_KEY`, `POSTHOG_KEY`, `POSTHOG_HOST`) from `~/.zshrc`.
  - Added `.vscode/launch.json` debug profiles dynamically forwarding user environment variables.
  - Configured `firebase` and `posthog` MCP servers in `.agents/mcp_config.json`.
  - Created `README_ANALYTICS.md` technical runbook.

#### 2. Maestro MCP Server Tooling & Zero-Prompt Visual Verification (PR #219, #220)
- **Maestro MCP 10-Tool Integration**:
  - Discovered and audited all 10 tools: `list_devices`, `take_screenshot`, `inspect_screen`, `run`, `open_maestro_viewer`, `cheat_sheet`, `list_cloud_devices`, `run_on_cloud`, `get_cloud_run_status`, `describe_cloud_run`.
  - Live verified `take_screenshot`, `inspect_screen`, and `run` flows on real Google Pixels (`56091JEBF14039` and `58221JEBF20835`).
  - Elevated `maestro:take_screenshot` to Option 1 (Highest Priority) in `ticket_driven_development.md` and `prefer_mcp_servers.md`.
  - Created `.agents/skills/maestro-device-automation/SKILL.md`.

#### 3. Dot-Shorthand & `Gap` Spacing Modernization (PR #217, #218)
- **Dart 3 Constructor Dot-Shorthands**:
  - Replaced `EdgeInsets` with constructor dot-shorthands (`const .symmetric(...)`, `const .all(...)`, `const .only(...)`, `const .fromLTRB(...)`).
  - Integrated `gap: ^3.0.1` and replaced spacer `SizedBox` widgets with `const Gap(...)` across navigation, banners, tone filters, and search dialogs.

#### 4. Direct Messages & Calm Private Fellowship Epic (PR #223)
- **End-to-End Direct Messaging Verification on Google Pixel Hardware**:
  - Validated conversation discovery, calm batched digest toggle, thread view, text entry, and reply bubble rendering on Pixel 9a (`56091JEBF14039`) via Maestro MCP (`.maestro/direct_messages_flow.yaml`).
  - BDD specifications: `test/features/direct_messages_and_notifications_feature.txt` and `test/features/direct_messages_and_events_test.dart`.
  - Created comprehensive test case catalog in `docs/wiki/Test-Cases.md`.

---

## [Release — `v0.9.0-rc` / Soft Launch Candidate (Oct 20, 2026)]

### 🚀 Major Accomplishments in the Last 30 Hours (Oct 19–20, 2026)

#### 1. Resilient Authentication & Cloud Credentials Fallback (PR #203 / #199)
- **`FirebaseAuthRepository` Resilient Seam**:
  - Implemented `_hasRealCredentials` guard to seamlessly detect placeholder vs production Firebase keys.
  - When running in offline or test mode, automatically delegates to in-memory accounts without hard-crashing or throwing raw API key exceptions.
  - Verified user creation and sign-in with test account (`neilwarner+2026Oct20+954pm@gmail.com`) with automated unit test (#199).
  - 171/171 tests green across the complete suite.

#### 2. Comprehensive Maestro User Journey & Auth Driving (PR #204 / #198)
- **Maestro End-to-End Flows (`.maestro/`)**:
  - Added `.maestro/belong_full_journey.yaml` driving Welcome Anchor $\rightarrow$ Sensory Theme Switcher $\rightarrow$ Spaces Directory $\rightarrow$ Scripture Anchor dialog $\rightarrow$ Auth Modal.
  - Added `.maestro/belong_auth_journey.yaml` validating account registration, ICOC church affiliation selection (`DFW Church`), and sign-in.
  - Built `tool/run_maestro_verification.sh` for 1-command driving across physical Pixels and emulators.

#### 3. Dynamic Dual Pixel Cloud Demo & Zero-PII Auto-Cropping (PR #196 / #195)
- **Dynamic Hardware Auto-Discovery**:
  - Scripts dynamically detect connected physical Pixels and emulators with zero hardcoded serial numbers.
  - Automated 1080x2160 status-bar auto-cropping via `sips` to strip clock, battery, and notifications.
  - Formalized 5 zero-prompt screenshot allowlist rules in `AGENTS.md` and `GEMINI.md` to guarantee unattended execution without terminal permission popups.

#### 4. Antigravity Autonomous Automated Testing Strategy (PR #202 / #201)
- Automated regression runbooks and triage strategy.
