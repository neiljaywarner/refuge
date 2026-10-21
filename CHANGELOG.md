# Changelog & Release Roadmap (`Belong on the Spectrum` / `refuge`)

All notable changes, accomplishments, and planned release milestones leading up to the **October 24–31, 2026 Circle.so Cutover & Overlap Window** are documented in this file.

---

## [Current Release — `v0.9.1-rc` / Pre-1.0 Telemetry, Maestro & DM Epic (Oct 21, 2026)]

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
