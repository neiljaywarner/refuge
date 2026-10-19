---
name: token-quota-routing
description: Multi-model token and quota optimization skill for balancing 5-hour burst limits and 7-day weekly caps across Gemini (4 Argon Low, Medium, High, Pro, Flash), Claude (Sonnet, Haiku, Opus), and GPT models while leveraging 48GB Apple Silicon RAM with parallel git worktrees and fast BDD/Marionette verification loops.
---

# Token & Multi-Model Quota Routing Skill

Use this skill at the end of every milestone or PR merge to proactively advise the user on:
1. Whether to stay on **Gemini 4 Argon Low / Medium**, switch up to **Gemini 4 Argon High**, or rotate for 15–20 minutes to **Claude (Sonnet/Haiku)** or **GPT** to let the Gemini 5-hour rolling window replenish.
2. Which tickets can be executed in **parallel `git worktree` directories** (`.worktrees/issue-<N>-<slug>`) on this 48GB RAM Apple Silicon Mac without stepping on each other's files.

## Core Routing Rules

1. **Default to `Gemini 4 Argon Low` or `Gemini 4 Argon Medium` (80% of Work)**:
   - Use for any GitHub Issue that already has a `🤖 LLM Execution Brief` comment specifying exact files, branch names, and BDD `.feature` scenarios (e.g., `CommunityBrandConfig`, launcher icons, `ComingSoonView`, BDD widget tests, link wiring).
2. **Rotate to `Claude Sonnet` or `GPT` for Prose/Wiki/ADR Tasks (15% of Work)**:
   - When writing or updating multi-page documentation (`docs/wiki/`, `Non-Technical-Roadmap-to-Oct-31.md`, `Organizer-Remote-Config-Guide.md`, ADRs) or when you've been running Gemini continuously for 45+ minutes, recommend switching to **Claude Sonnet** or **GPT** for 1–2 tickets so the Gemini 5-hour rolling window cools down.
3. **Reserve `Gemini 4 Argon High` / `Pro` Strictly for Complex Architecture (5% of Work)**:
   - Recommend switching up to **Argon High** ONLY when:
     - Designing the Community Organizer's custom feature from scratch (`Issue #10`)
     - Debugging multi-layer Serverpod protocol codegen + OAuth (`Issue #12` / `Issue #19`).
   - Immediately after the architectural ticket merges, remind the user to **switch back down to Argon Low or Medium**!
4. **Recommend `/compact` Every 2–3 Merged PRs**:
   - Because all state is persisted in `18-oct-diving-in-since-machine-setup-in25-minutes-successfully.md`, `18Oct2026_session_plan_and_status.md`, and GitHub Issue comments, remind the user to run `/compact` after every 2–3 PRs to avoid paying quadratic input token costs on long conversation history.
