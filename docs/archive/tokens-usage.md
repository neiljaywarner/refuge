# Multi-Model Token & Quota Optimization Guide (Based on Your Live Quota Screenshot)

> **Last Snapshot (`2026-10-18 19:23 CDT`)**:
> 1. **Gemini 4 Argon Dedicated Pool**: **`54%` Weekly Limit Remaining** *(Resets in 6d 20h — Tightest Pool!)*
> 2. **General Gemini Models Pool (`Gemini 3.8 Flash Medium`)**: **`79%` Weekly Limit Remaining** *(Resets in 5d)* | **`94%` Five-Hour Limit Remaining** *(Resets in 1h 24m!)*
> 3. **Claude & GPT Models Pool (`Claude Sonnet 5.5 Medium`, `Claude Opus 5.5 Medium`, `GPT-OSS 120B Medium`)**: **`93%` Weekly Limit Remaining** *(Resets in 6d 20h)* | **`86%` Five-Hour Limit Remaining** *(Resets in 1h 20m!)*

---

## 1. Critical Insight from Your Screenshot — Is `Gemini 4 Argon Medium` Good Right Now?

- **Yes, `Gemini 4 Argon Medium` is great for orchestrating right now (much cheaper than `Argon High`), BUT notice the bottom meter in your screenshot:**
  - **`Gemini 4 Argon` has its own separate Weekly Limit (`54%` remaining with 6d 20h to go)**!
  - Meanwhile, your **5-Hour Limits reset in just `1h 20m`**, and you have **`94%` 5-Hr / `79%` Weekly** on **`Gemini 3.8 Flash Medium`** AND **`86%` 5-Hr / `93%` Weekly** on **`Claude Sonnet 5.5 Medium` / `GPT-OSS 120B Medium`**!
- **Smartest Strategy for Tonight (Next 1 Hour 20 Minutes Before the 5-Hour Reset)**:
  1. **Use `Claude Sonnet 5.5 Medium` (`93%` weekly!) or `Gemini 3.8 Flash Medium` (`94%` 5-hr!) for the next 60–80 minutes** to burn the "free" 5-hour quota that is about to reset in `1h 20m` anyway — while **saving your `54%` `Gemini 4 Argon` weekly pool** for the rest of the week!
  2. **Whenever we spawn parallel worktree subagents (`invoke_subagent`)**, we can explicitly pass `Model: 'flash'` so subagents draw from the **`94%` 5-hr / `79%` weekly Flash pool** instead of draining your `54%` Argon weekly pool!
  3. **Only switch to `Gemini 4 Argon High`** if you hit a tricky multi-layer architectural question (like the Community Organizer's custom request in **Issue #24**).

---

## 2. Live Issue Roster (`#15`–`#37`) & Exact Model Recommendations

| Issue | Milestone | Title | Best Model Tonight (Before 1h 20m Reset) | Subagent Tier (`invoke_subagent`) | Parallel Wall-Clock Mins (48GB RAM) |
| :---: | :---: | :--- | :--- | :---: | :---: |
| **#15** | `v0.5.0` | Apple Silicon 48GB Mac Setup in 24 Minutes *(CLOSED)* | Done | — | Done |
| **#16** | `v0.5.0` | Mentoring: Marionette MCP, Patrol MCP, Dart/Flutter MCP & 25 Official Skills *(CLOSED)* | Done | — | Done |
| **#17** | `v0.6.0` | White-Label `CommunityBrandConfig` (`Belong` first tenant) | **`Gemini 3.8 Flash Medium`** or **`Argon Medium`** | `flash` | **12m** *(Wave 1)* |
| **#19** | `v0.6.0` | Belong Logo, Adaptive Launcher Icons & Multi-Platform App Icons | **`Gemini 3.8 Flash Medium`** | `flash` | *(in Wave 1)* |
| **#21** | `v0.6.0` | Non-Technical Organizer & Contributor Wiki + Oct 31 Circle Cutover Schedule | **`Claude Sonnet 5.5 Medium`** *(uses your 93% Claude pool!)* | `inherit` / `flash` | *(in Wave 1)* |
| **#35** | `v0.6.0` | Adopt `hooks_riverpod` (`HookConsumerWidget`) & CodeWithAndrea Architecture | **`Gemini 3.8 Flash Medium`** or **`Claude Sonnet 5.5 Medium`** | `flash` | **22m** *(Wave 2)* |
| **#18** | `v0.6.0` | Home Screen Scaffolding & Circle-Style Navigation Update (`Feed`/`Spaces`, ADR Bottom Nav, Remove Judges API Explorer) | **`Claude Sonnet 5.5 Medium`** or **`Argon Medium`** | `inherit` | *(in Wave 2)* |
| **#20** | `v0.6.0` | Firebase Analytics & Firebase Remote Config (*"Message from the Organizer"*) | **`Gemini 3.8 Flash Medium`** or **`Argon Medium`** | `flash` | *(in Wave 2)* |
| **#22** | `v0.6.0` | Search Tab & Media/Meme Post Cards (`Memes`, `Online Resources / Videos`) | **`Gemini 3.8 Flash Medium`** | `flash` | *(in Wave 2)* |
| **#23** | `v0.7.0` | Upper-Right Member Profile & Avatar View | **`Gemini 3.8 Flash Medium`** or **`Claude Sonnet 5.5 Medium`** | `flash` | **20m** *(Wave 3)* |
| **#24** | `v0.7.0` | Belong Community Organizer's Priority Request | **`Gemini 4 Argon High`** or **`Claude Sonnet 5.5 Medium`** | `inherit` | *(in Wave 3)* |
| **#25** | `v0.7.0` | **[EPIC] 50% Automated & Holistic Test Coverage (`v0.7.0`)** | **`Gemini 3.8 Flash Medium`** | `flash` | *(in Wave 3)* |
| **#36** | `v0.7.0` | CodeRabbit AI Review Audit & Zero-Smell Refactoring Gate | **`Gemini 3.8 Flash Medium`** | `flash` | *(in Wave 3)* |
| **#26** | `v0.8.0-alpha` | Stage 1 Authentication ("Any Auth") for Community Alpha | **`Claude Sonnet 5.5 Medium`** or **`Argon Medium`** | `inherit` | **15m** *(Wave 4)* |
| **#37** | `v0.8.0-alpha` | Build Dart Multi-Model Token Orchestrator & Worktree Harness (`tool/token_harness.dart`) | **`Gemini 3.8 Flash Medium`** | `flash` | *(in Wave 4)* |

---

## 3. Token-Saving Skills Active in `.agents/skills/`

1. **[`token-quota-routing`](file:///Users/neil/belongonthespectrum/.agents/skills/token-quota-routing/SKILL.md)**: Automatically reminds you when to switch between `Gemini 3.8 Flash Medium`, `Claude Sonnet 5.5 Medium`, and `Gemini 4 Argon Medium/High`.
2. **[`marionette-token-saver`](file:///Users/neil/belongonthespectrum/.agents/skills/marionette-token-saver/SKILL.md)**: Uses `get_interactive_elements` (~150 tokens) instead of repeated `take_screenshots` (~1,500+ tokens).
3. **[`patrol-token-saver`](file:///Users/neil/belongonthespectrum/.agents/skills/patrol-token-saver/SKILL.md)**: Uses `native-tree` (~150 tokens) and fast 1-second `flutter test` (`bdd_widget_test`) loops before physical device runs.
