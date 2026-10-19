# Multi-Model Token & Quota Optimization Guide (5-Hour Burst & 7-Day Weekly Limits)

> **Hardware**: 48GB Unified RAM Apple Silicon (`arm64`) Mac  
> **Available Model Families**: Gemini (Pro, 4 Argon High, 4 Argon Medium, 4 Argon Low, Flash), Claude (Sonnet, Haiku, Opus), GPT  
> **Project**: `neiljaywarner/refuge` — **Belong on the Spectrum** (`belongonthespectrum.com`, Circle.so Cutover by Oct 31, 2026)

---

## 1. TL;DR — What Model Should You Switch To Right Now?

- **Switch to `Gemini 4 Argon Low` or `Gemini 4 Argon Medium` IMMEDIATELY after this message!**
  - Why: Every single GitHub issue (`#3` through `#20`) now has a pre-written **`🤖 LLM Execution Brief` comment** with exact file paths, worktree commands, and BDD `.feature` specifications.
  - Lower/medium models execute mechanical scaffolding, icons, wiki writing, and BDD tests at **1/5th to 1/10th the quota cost** of Pro/Opus with near-identical quality when anchored by our markdown plans and issue briefs.
- **When to Switch to `Gemini 4 Argon High` (or `Claude Sonnet` / `GPT`)**:
  - **Only** for **Issue #10 (Community Organizer's Custom Request)** if the requirements are ambiguous, or **Issue #12 (Stage 1/2 Auth + Serverpod Backend Wiring)** if multi-file protocol codegen debugging is needed.
- **How to Avoid Both the 5-Hour Window Limit & the 7-Day Weekly Limit**:
  - **Rule 1 (80/20 Split)**: Run **80% of tickets** on **Gemini 4 Argon Low / Medium**; rotate **15% of tickets** (especially long markdown/wiki writing or UI polish) to **Claude Sonnet** or **GPT** so your Gemini 5-hour rolling window cools down mid-session!
  - **Rule 2 (Never Poll in Loops)**: Use reactive wakeups (`WaitMsBeforeAsync`) and local `flutter test` (`~1 second`) instead of multi-turn browser scraping.
  - **Rule 3 (Short Contexts via `/compact` or Fresh Ticket Sessions)**: Since `18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md`, `18Oct2026_session_plan_and_status.md`, and each GitHub Issue's `🤖 LLM Execution Brief` hold the entire state on disk, you can run `/compact` or start a fresh chat per milestone so you don't pay quadratic input-token re-reads on a 100-turn transcript!

---

## 2. How 48GB RAM + Parallel Worktrees + BDD/Marionette Cuts Wall-Clock Minutes by ~60%

Because this Apple Silicon Mac has **48GB of unified RAM**:
1. **Zero Swap Contention**: You can keep Google Chrome (`flutter run -d chrome`), the physical **Pixel 9a** (`adb`), the Dart Analysis Server (`dart mcp-server`), `marionette_mcp`, and **3 concurrent `git worktree` directories** open in RAM simultaneously using `< 18 GB` total (~30 GB free headroom!).
2. **Fast BDD Verification Loops (`1s` vs `45s`)**:
   - Driving a full browser via CDP/Playwright takes ~30–60 seconds and thousands of DOM tokens per turn.
   - Running `flutter test` on a `bdd_widget_test` `.feature` file takes **1.0 second** and ~150 tokens of output, followed by a single **Marionette MCP** hot-reload (`hot_reload` + `get_interactive_elements`) taking **< 2 seconds**!
3. **Sequential vs. 48GB Parallel Wall-Clock Comparison (Road to Alpha Tonight)**:

| Wave | Tickets Run in Parallel Worktrees (`.worktrees/issue-N-...`) | Sequential Agent Mins | **48GB Parallel Wall-Clock Mins** | Recommended Model Mix (Saves 5-Hr Quota!) |
| :--- | :--- | :---: | :---: | :--- |
| **Wave 1 (`v0.6.0` Core)** | • **Issue #3**: `CommunityBrandConfig` (`Belong`)<br>• **Issue #5**: Belong Logo & Multi-Platform App Icons<br>• **Issue #7**: Non-Technical Wiki & Oct 31 Cutover Timeline | 34 min | **~12 min** | • Issue #3 & #5: **Gemini 4 Argon Low**<br>• Issue #7 (Wiki): **Claude Sonnet** or **GPT** *(offloads Gemini 5-hr quota!)* |
| **Wave 2 (`v0.6.0` UI & Firebase)** | • **Issue #4**: Circle Home Scaffolding + Bottom Nav ADR<br>• **Issue #6**: Firebase Analytics & Remote Config (*"Message from the Organizer"*)\<br>• **Issue #8**: Search Tab & Memes/Video Cards | 52 min | **~22 min** | • Issue #4: **Gemini 4 Argon Medium** (or **Claude Sonnet**)<br>• Issue #6 & #8: **Gemini 4 Argon Low** |
| **Wave 3 (`v0.7.0` Profile & 50% BDD)** | • **Issue #9**: Upper-Right Member Profile & Avatar<br>• **Issue #10**: Organizer's Priority Request<br>• **Issue #11**: 50% BDD & Holistic Coverage Epic | 50 min | **~20 min** | • Issue #9 & #11: **Gemini 4 Argon Low**<br>• Issue #10: **Gemini 4 Argon High** |
| **Wave 4 (`v0.8.0-alpha` Auth)** | • **Issue #12**: Stage 1 "Any Auth" for Alpha | 20 min | **~15 min** | • **Gemini 4 Argon Medium / High** (or **GPT / Claude**) |
| **TOTAL TO ALPHA** | **10 Issues / PRs Merged** | **156 min (2.6h)** | **~69 min (~1.15 Hours!)** | **Zero 5-Hr or Weekly Quota Exhaustion** |

---

## 3. Ticket-by-Ticket Model Routing Cheat Sheet (Gemini vs. Claude vs. GPT)

Use this table whenever you start a ticket or spawn subagents so you balance your **5-hour rolling window** and **7-day weekly cap**:

| Task Archetype | Best Primary Model (Lowest Quota Burn) | Best Alternate Model (When Resting Gemini 5-Hr Window) | Why |
| :--- | :--- | :--- | :--- |
| **Repo / Worktree / Boilerplate / Icons (`#3`, `#5`, `#15`–`#17`)** | **Gemini 4 Argon Low** | **GPT-4o-mini / Claude Haiku** | Deterministic file paths & CLI commands already written in the Issue Brief. |
| **UI Scaffolding & Circle Nav (`#4`, `#8`, `#9`)** | **Gemini 4 Argon Medium** | **Claude Sonnet** | Great widget layout & Material 3 sense at moderate token cost. |
| **Firebase Analytics & Remote Config (`#6`)** | **Gemini 4 Argon Low / Medium** | **GPT** | Clean Riverpod service + fallback pattern is fully specified in the Issue Brief. |
| **Wiki, ADRs & Non-Technical Docs (`#7`, ADR 0005)** | **Claude Sonnet** or **Gemini 4 Argon Low** | **GPT** | Prose-heavy markdown generation is a great time to rotate to Claude/GPT for 15 minutes so your Gemini 5-hour window replenishes. |
| **BDD `.feature` Tests & Coverage Epics (`#11`, `#18`, `#20`)** | **Gemini 4 Argon Low** | **Claude Haiku / Sonnet** | Gherkin scenarios + `build_runner` + `flutter test --coverage` are fast, mechanical loops. |
| **Ambiguous Organizer Feature / Serverpod Auth (`#10`, `#12`, `#19`)** | **Gemini 4 Argon High** | **Claude Sonnet / Opus** | Reserve High/Pro strictly for multi-layer architecture or custom product design. |

---

## 4. Five Habits That Save 70%+ of Weekly Tokens

1. **Always Read Specific Line Ranges (`view_file` with `StartLine`/`EndLine`)**: Never dump entire generated `.g.dart` or `serverpod` protocol files into context.
2. **Use `dart mcp-server` & `marionette_mcp` Instead of Screenshots Loops**: Text-based `get_interactive_elements` costs ~200 tokens vs ~1,500+ tokens per full-res screenshot. Only take screenshots at final milestone verification.
3. **Run `build_runner` Once per Schema Change, Not Every Turn**.
4. **Compact Context Between Milestones (`/compact`)**: Because our 3 markdown status trackers + GitHub Issue comments store all progress on disk, compacting after every 2–3 merged PRs cuts input token burn by **60–80%**.
5. **Rotate Providers Across the Evening**:
   - **Minutes 0–45**: **Gemini 4 Argon Low / Medium** (Waves 1 & 2)
   - **Minutes 45–65**: **Claude Sonnet / GPT** (Wiki overhaul Issue #7 + ADR 0005 + UI review — lets Gemini 5-hr window cool down)
   - **Minutes 65–90**: **Gemini 4 Argon High / Low** (Wave 3 Organizer Request + 50% BDD Coverage + Wave 4 Alpha Auth).
