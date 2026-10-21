# 🤖 Antigravity Autonomous Automated Testing & Overnight QA Strategy (2026)

> [!TIP]
> **Antigravity Use-Case Evaluation**: Official evaluation of Google Antigravity's [Automated Testing & QA Verification](https://antigravity.google/use-cases/automated-testing) capabilities for Belong on the Spectrum. Tracks our shift from brittle manual clicking to **autonomous, self-healing quality verification**.

---

## 🧭 Executive Summary: Is it "Worth It" in 2026?

**Yes — Exceptionally High ROI**.
As an unhurried Christian fellowship app tailored specifically for autistic and neurodivergent adults, interface serenity and reliability are paramount. Sudden crashes, erratic state updates, and color contrast failures can trigger acute sensory discomfort and quiet community abandonment.

Because Belong operates with lean developer resources, traditional manual QA is insufficient. Adopting Antigravity's autonomous testing paradigms provides:
1. **Zero-Overhead Nightly Protection**: Regressions are identified, diagnosed, and repaired in git branches while developers sleep.
2. **Deep Race Condition Immunity**: Automated multi-cycle stress runs detect subtle async state teardown races in Riverpod and Serverpod WebSocket streams before members experience them.
3. **Continuous Cross-Platform Parity**: Headless Chrome browser agents inspect live Web PWA deployments (`https://belongonthespectrum.web.app`) for WCAG AAA compliance alongside physical Pixel 9a testing.

---

## 🏗️ The 3 High-Leverage Capabilities for Belong in 2026

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Google Antigravity Autonomous QA Loop                    │
├─────────────────────────┬─────────────────────────┬─────────────────────────┤
│ 1. Scheduled Overnight  │ 2. Stress Flake Hunter  │ 3. Browser-in-the-Loop  │
│    Regression Agent     │    & Race Detector      │    PWA & WCAG Audits    │
│  • Runs at 2:00 AM      │  • 50-cycle Riverpod    │  • Headless Chrome PWA  │
│  • 170+ Test Suite      │    stress tests         │  • Multi-breakpoint QA  │
│  • Auto-opens fix PRs   │  • WebSocket race hunt  │  • WCAG AAA contrast    │
└─────────────────────────┴─────────────────────────┴─────────────────────────┘
```

---

### 1. Scheduled Overnight Regression & Morning Triage Agent

- **Trigger**: Native Antigravity cron via `/schedule` or GitHub Actions schedule.
- **Workflow**:
  1. At 2:00 AM CST, the agent spins up an isolated worktree on latest `main`.
  2. Runs static analysis via Dart MCP (`analyze_files`) and the full 170+ test suite (`run_tests`).
  3. If all tests pass green, records a clean audit receipt in `status.md`.
  4. If any test fails, the agent isolates the failing file, performs root-cause analysis using `git blame`, prepares a candidate fix, verifies it green, and opens a GitHub PR with full before/after diffs and test logs ready for morning review.

---

### 2. Autonomous Flakiness & State-Teardown Race Hunter

- **Problem**: Riverpod providers combined with Serverpod WebSocket feeds and Firebase Auth listeners can occasionally flake if stream subscriptions aren't synchronously cancelled during test widget disposal.
- **Solution (`tool/stress_test.dart`)**:
  - The agent executes high-concurrency loops (50–100 consecutive runs with varying thread seeds) to surface timing-dependent leaks.
  - Automatically converts brittle `sleep(...)` calls into deterministic reactive wait predicates (`await tester.pumpAndSettle()`, `await expectLater()`).

---

### 3. Browser-in-the-Loop Web PWA Visual & Accessibility Audits

- **Target**: Production PWA at [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app).
- **Scope**:
  - **Sensory Themes**: Renders each of the 4 sensory modes (Sage Botanical, Monastic Dark, Clean Slate, High Contrast) and verifies background/foreground contrast ratios $\ge 7:1$ (WCAG AAA).
  - **Screen Size Breakpoints**: Validates responsive drawer behavior across 390px (mobile), 768px (tablet), and 1280px (desktop).
  - **Network Failure Simulation**: Simulates offline drops to verify that cached reflections and local drafts persist without jarring error modals.

---

## 📅 Roadmap & Milestones (2026)

| Milestone | Target Window | Deliverables | Tracked Ticket |
| :--- | :--- | :--- | :--- |
| **Phase 1** | October 2026 | Document strategy, add `antigravity-overnight-qa` skill, update Wiki. | [#201](https://github.com/neiljaywarner/refuge/issues/201) |
| **Phase 2** | November 2026 | Implement `tool/stress_test.dart` for 50-cycle race detection; integrate with Dart MCP. | [#201](https://github.com/neiljaywarner/refuge/issues/201) |
| **Phase 3** | December 2026 | Wire scheduled cron automation (`/schedule`) for 2:00 AM overnight health reports. | [#201](https://github.com/neiljaywarner/refuge/issues/201) |
