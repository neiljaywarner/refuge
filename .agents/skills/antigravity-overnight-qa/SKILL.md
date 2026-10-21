---
name: antigravity-overnight-qa
description: Autonomous overnight regression testing, flakiness stress detection, and morning triage report generator for Belong on the Spectrum.
---

# Antigravity Overnight QA & Autonomous Triage Skill

## Purpose
Enables an Antigravity agent running via scheduled cron (`/schedule`) or background unattended session to execute complete end-to-end regression audits, stress-test asynchronous Riverpod streams, and prepare actionable pull requests or triage logs for the maintainer.

## Workflow

1. **Workspace Health Verification**:
   - Check out latest `main`.
   - Run `analyze_files` via Dart MCP to ensure 0 lint errors or warnings.
   - Run `run_tests` via Dart MCP to verify 170+ tests pass green.

2. **Flakiness & Race Audit**:
   - Run candidate test files in a 20-cycle repeat loop.
   - Detect any async leaks or uncancelled timer warnings.

3. **Autonomous Remediation**:
   - If any test breaks, analyze the stack trace and recent commits.
   - Create branch `fix/#<issue>-overnight-triage`.
   - Apply candidate fix and verify with `run_tests`.
   - Open draft PR with GitHub MCP `create_pull_request` referencing the failure details.

4. **Morning Report Generation**:
   - Post summary comment to active tracking ticket or `status.md`.
