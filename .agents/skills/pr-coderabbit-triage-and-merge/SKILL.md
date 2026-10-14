---
name: pr-coderabbit-triage-and-merge
description: >-
  Audits, triages, and closes/merges GitHub Pull Requests by verifying reviewer
  feedback (such as CodeRabbit comments). It classifies comments into addressed,
  critical blockers (fixed immediately), and non-critical items (deferred into
  tracked GitHub issues), runs pre-merge verification, and executes the PR merge.
---

# PR CodeRabbit Triage and Merge Workflow

Use this skill when closing or merging a pull request that has automated or manual review comments (such as from CodeRabbit). It provides an automated, transparent mechanism to address critical blockers, defer non-critical items to GitHub issues, report results, and safely merge the PR into `main`.

---

## Workflow Steps

### 0. Mandatory Wait for Automated Review Bots (CodeRabbit / CI)
Before running triage:
1. **Allow Review Bot Execution**: CodeRabbit typically takes 2–4 minutes after a PR is opened or new commits are pushed to analyze code diffs, run LLM heuristics, and post review comments.
2. **Verification Condition**: Triage MUST always wait at least 180 seconds after PR creation or the latest commit. Review completion (such as summary comments `<!-- This is an auto-generated comment by CodeRabbit -->` or review status) should only serve as a reason to wait longer if still in progress, NEVER as a substitute for bypassing the minimum 180-second delay. NEVER run triage immediately within 30 seconds of PR creation!
3. **Timer / Reactive Wait**: Use `schedule(DurationSeconds=180, ...)` if needed to wait for CodeRabbit before executing triage scripts.

### 1. Inventory & Triage Comments
Run the triage helper script to fetch and classify all open review comments on the PR:

```bash
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py --pr 116  # replace 116 with the target PR number
```

*For JSON output to programmatically parse items:*
```bash
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/triage_pr_comments.py --json
```

Refer to the [Triage Rubric](references/triage_rubric.md) for classification rules:
- **✅ Addressed**: Already resolved in previous or recent commits.
- **🚨 Critical / Fix Now**: Security vulnerabilities, exposed secrets, infinite loops, broken builds, or app crashes.
- **📋 Defer to Issue**: Improvements, documentation refinements, secondary edge cases, or future architectural tasks.

---

### 2. Address Critical Issues or Quick Wins
If any critical blockers or easy quick wins remain unaddressed:
1. Make targeted fixes in the source files.
2. Ensure no hardcoded keys or secrets are embedded per project rules (`GEMINI.md`).
3. Verify changes with unit/widget tests:
   ```bash
   flutter test
   ```

---

### 3. Defer Non-Critical Items to GitHub Issues
For every non-critical comment that will not be resolved in the current PR, file a tracked issue on the repository:

```bash
python3 .agents/skills/pr-coderabbit-triage-and-merge/scripts/defer_comments_to_issues.py
```

*Or manually create focused issues:*
```bash
gh issue create --title "<Category>: <Summary>" --body "<Context & Description>"
```

---

### 4. Quality & Pre-Commit Verification
Before merging:
1. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   *Must report 0 issues.*
2. **Automated Tests**:
   ```bash
   flutter test
   ```
   *Must be 100% green.*
3. **Secret Audit**:
   ```bash
   git diff --staged | grep -i -E "api[_-]?key|secret|token"
   ```
   *Must verify zero credentials or plaintext fallback keys are introduced.*
4. **Session Status Log**:
   Update the ongoing session tracking file (`<date>_selah_session.md`) with the milestone completion and proof artifacts.

---

### 5. Commit, Push, and Merge
1. Stage and commit fixes:
   ```bash
   git add -A
   git commit -m "fix/feat: address review feedback and defer non-critical tasks"
   git push origin <branch_name>
   ```
2. Merge the Pull Request:
   ```bash
   gh pr merge <pr_number> --merge
   ```
3. Sync local `main`:
   ```bash
   git checkout main && git pull origin main
   ```

---

### 6. Report to User
Provide the user with a concise summary table:
- **Addressed:** Which comments were fixed and verified in the PR.
- **Deferred:** Which comments were converted to GitHub issues (with clickable issue links).
- **Merge Status:** Confirmation of successful merge into `main` and test suite state.
