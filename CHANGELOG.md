# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes, accomplishments, and planned release milestones leading up to the **October 24–31, 2026 Circle.so Cutover & Overlap Window** are documented in this file.

---

## [Current Release — `v0.9.5-rc` / Release Readiness Gate & Cutover Sync (Oct 21–22, 2026)]

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
