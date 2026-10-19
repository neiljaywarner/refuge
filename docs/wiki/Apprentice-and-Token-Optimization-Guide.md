# 🎓 Student, Mentee & Apprentice Guide — Clean Flutter Architecture, BDD & Free-Tier AI Token Optimization

> **Audience**: Students, Junior Developers, Mentees, and Open-Source Apprentices learning modern full-stack Flutter & Dart engineering  
> **Tracked In**: GitHub Epic **#38** & Story **#39**

---

## 1. Welcome! Why This Repository Is Built as a Teaching Reference

This repository (`neiljaywarner/refuge`, powering **[Belong on the Spectrum](https://www.belongonthespectrum.com/)**) is intentionally structured so that students and apprentices can look back at the commit history, GitHub Issues (`#15`–`#46`), Pull Requests, and ADRs (`docs/adr/`) to see **how production software is built step-by-step using AI-assisted Ticket-Driven Development**.

Every architectural choice follows five core principles:
1. **CodeWithAndrea (`codewithandrea.com`) Feature-First Layered Architecture**:
   - Every feature under `lib/src/features/<feature>/` is cleanly separated into `presentation/`, `application/`, `domain/`, and `data/`.
2. **`hooks_riverpod` (`HookConsumerWidget`)**:
   - Combines `flutter_hooks` (eliminating `StatefulWidget` controller disposal bugs) with `flutter_riverpod` (compile-safe dependency injection and state management).
3. **Pragmatic Red-Green-Refactor BDD (`bdd_widget_test`)**:
   - Features begin with human-readable Gherkin `.feature` files in `test/features/` that non-technical organizers and developers can read together.
4. **Pure Dart Developer Tooling (`tool/refuge_cli.dart`)**:
   - Instead of fragile bash scripts, repository automation and data migration tools (`tool/refuge_cli.dart`, `tool/import_circle_csv.dart`) are written in **pure Dart** so Flutter developers can read, debug, and test every script in one language.
5. **Strict Zero-PII & Zero-Secret Hygiene**:
   - Public repositories must **never** contain API keys, passwords, or real user CSVs. Check `.gitignore` and `ADR 0006` (`dev` vs `prod` flavors) to see how secrets stay out of Git.

---

## 2. How Students on Free or Budget AI Tiers Can Save 80–90% of Their Tokens

Whether you are using a **free tier** or managing **5-hour burst limits and 7-day weekly quotas** across **Gemini (Flash / Argon Low / Medium / High)**, **Claude (Haiku / Sonnet / Opus)**, and **GPT**, these habits will stretch your quota 5x–10x further:

### Habit 1: Write the Spec into the GitHub Issue First (`🤖 LLM Execution Brief`)
- Notice how every issue in [GitHub Issues](https://github.com/neiljaywarner/refuge/issues) has a comment titled **`🤖 LLM Execution Brief`**.
- When an issue already lists the exact files to edit, the branch name, and the BDD `.feature` scenario, a **fast, low-cost model (`Gemini Flash` or `Argon Low` or `Claude Haiku`)** can execute the ticket with the same quality as an expensive frontier model at **1/10th the token cost**!

### Habit 2: Use the Native Dart MCP Server (`analyze_files` & `run_tests`) Instead of Long Terminal Loops
- Running `flutter test` on a single BDD widget test takes **~1 second** and ~100 tokens.
- Avoid launching full headless browsers (CDP / Playwright) that dump 10,000+ DOM tokens into your chat window on every step.

### Habit 3: Use `get_interactive_elements` (Marionette MCP) Instead of Repeated Screenshots
- When driving a live Flutter app via **Marionette MCP** (`marionette_mcp`), calling `take_screenshots` adds **1,500+ vision tokens** that get re-billed on every subsequent turn of your conversation!
- Instead, call `get_interactive_elements` (see [`.agents/skills/marionette-token-saver/SKILL.md`](file:///Users/neil/belongonthespectrum/refuge/.agents/skills/marionette-token-saver/SKILL.md)), which returns a crisp text list of buttons, tabs, and inputs for **~150 tokens** (a **90% token savings**!).

### Habit 4: Keep Context Short with Markdown Checkpoints & `/compact`
- Long 80-turn chat sessions cost exponentially more tokens because the LLM re-reads the entire conversation history on every turn.
- By keeping a live status file (`18Oct2026_session_plan_and_status.md`) and using **1 GitHub Issue = 1 Worktree Branch = 1 PR**, you can run `/compact` or start a fresh chat after every 2–3 PRs without losing context.

### Habit 5: Rotate Model Families Before Your 5-Hour Window Resets
- Check your quota meter (`tokens-usage.md`):
  - Use **Flash / Argon Low** for boilerplate, icons, and unit/BDD tests.
  - Use **Claude Sonnet / Argon Medium** for UI layout, `hooks_riverpod` refactoring, and documentation.
  - Save **Argon High / Pro / Opus** strictly for complex multi-layer architecture or tricky debugging.

---

## 3. Studying Our Pure-Dart Tooling (`tool/`)

Explore the [`tool/`](file:///Users/neil/belongonthespectrum/refuge/tool/) directory to see how we write developer CLIs in Dart:
- **`tool/refuge_cli.dart`**: Synchronizes GitHub milestones, labels, and issues, and triggers CodeRabbit AI reviews using `dart:io` `Process.run`.
- **`tool/import_circle_csv.dart`** *(Issue #41)*: Parses exported Circle.so CSVs with `--dry-run` validation and zero PII leakage.
- **`tool/token_harness.dart`** *(Issue #37)*: Multi-model worktree orchestrator harness.
