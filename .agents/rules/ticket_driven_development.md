---
trigger: always_on
description: Enforces strict Ticket-Driven Development (1 Issue = 1 Worktree = 1 PR), Maestro MCP / Marionette / Patrol device driving, mandatory Before/After visual evidence, and continuous CodeRabbit PR triage, squash-merge, and branch deletion.
---

# Ticket-Driven Development, Maestro/Marionette/Patrol BDD, Visual Evidence & CodeRabbit PR Merge Rule

Every agent (across all model tiers) working in `/Users/neil/belongonthespectrum` and `/Users/neil/belongonthespectrum/refuge` MUST follow this integrated workflow:

## 1. Strict Ticket-Driven Development (`1 Issue = 1 Worktree = 1 PR for EVERY Single Prompt`)
- **Mandatory for EVERY User Prompt**: Every prompt, task, feature, bug fix, refactor, styling tweak, test addition, or documentation update MUST begin with an Issue, run in an isolated Worktree, and conclude with a verified PR. Never commit directly to `main`.
- **Mandatory Verification Step / Comment on EVERY Issue & PR (UI & Non-UI)**:
  - Every single GitHub Issue and PR MUST contain an explicit **Verification Step / Audit Comment** documenting:
    1. **Confirmation of Functionality**: Clear sentence or bullet points explaining how you proved the change worked as intended.
    2. **Exact Steps Taken**: The exact commands executed, MCP tools invoked, device actions taken, or test suites run.
    3. **Exact Results Obtained**: Raw verifiable metrics (e.g., `175/175 tests passing green`, analyzer output `No errors`, exit code 0, Maestro flow output `Flow executed successfully`).
    4. **Visual Evidence for UI Changes**: For any UI, branding, icon, layout, or styling change, side-by-side **Before and After** screenshots/videos are mandatory.
- **No Direct Commits to `main`**: Never commit or push directly to `main`. Always protect `main`.
- **MANDATORY: Zero Terminal Prompts for GitHub Operations**:
  - NEVER run interactive shell `git push` if it triggers terminal approval prompts.
  - ALWAYS use the **GitHub MCP Server** (`call_mcp_tool(ServerName: 'github', ...)`) for atomic, zero-approval pushes and PR management (`create_branch`, `push_files`, `create_pull_request`, `pull_request_read`, `merge_pull_request`, `issue_write`, `add_issue_comment`).
- **Isolated Worktree per Ticket**:
  Create worktrees under `/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>` with branch naming `feat/#<NUM>-<slug>`, `fix/#<NUM>-<slug>`, `docs/#<NUM>-<slug>`, or `chore/#<NUM>-<slug>`.

## 2. Continuous CodeRabbit Triage, Squash-Merge & Branch Deletion
1. When a PR is opened, trigger `@coderabbitai review` using `call_mcp_tool(ServerName: 'github', ToolName: 'add_issue_comment', Arguments: {issue_number: <PR>, body: '@coderabbitai review', ...})`.
2. Inspect PR review comments:
   - Fix critical/blocking bugs or security issues immediately in the worktree.
   - Defer non-blocking polish items to Issue `#36` (CodeRabbit Release Audit Gate) with a reference comment.
3. **Do Not Leave Verified PRs Hanging Open**: Once `analyze_files` and `run_tests` pass via the Dart MCP server, **squash-merge the PR via GitHub MCP (`merge_pull_request`)**, pull `origin/main`, and prune the completed worktree so PRs continuously open, get verified/triaged, and close cleanly!

## 3. Real Device Driving & Zero-Prompt Visual Evidence with Maestro MCP
- ***Mandatory Visual Verification Step (Before & After Evidence on ALL UI PRs & Issues)\***:
  - Every UI feature, styling, branding, icon, layout, or accessibility change MUST include explicit side-by-side visual verification evidence attached directly to BOTH the GitHub Issue and the Pull Request before declaring complete:
    - **Before Evidence**: Screenshot showing the original defect, faint stroke, padding bug, or unstyled state.
    - **After Evidence**: Screenshot showing the resolved, verified, high-contrast, beautiful UI on real hardware (Google Pixels `56091JEBF14039` and `58221JEBF20835`, or Android emulator `emulator-5554`).
  - Never declare a UI ticket or PR complete without presenting side-by-side Before/After verification!
- **Maestro MCP Flow Validation (`ServerName: 'maestro'`)**:
  - Use `inspect_screen` to verify exact on-screen hierarchy without guessing or hallucinating strings.
  - Use `run` to execute declarative UI flows across connected Pixels or emulators (`appId: com.belongonthespectrum.sanctuary`).
  - View real-time device screen mirroring and command execution at **`http://127.0.0.1:9999/`** (`open_maestro_viewer`).
- **Zero-Prompt Screenshot Hierarchy**:
  1. **Option 1 (Maestro MCP - Highest Priority)**: `call_mcp_tool(ServerName: 'maestro', ToolName: 'take_screenshot', Arguments: {device_id: '56091JEBF14039'})` — instant direct MCP RPC with 0 terminal prompts.
  2. **Option 2 (Patrol MCP)**: `call_mcp_tool(ServerName: 'patrol', ToolName: 'screenshot')`.
  3. **Option 3 (Marionette MCP / CLI)**: `call_mcp_tool(ServerName: 'marionette', ToolName: 'take_screenshot')`.
  4. **Option 4 (Pre-Approved Fixed Script)**: `/Users/neil/belongonthespectrum/refuge/tool/capture_device.sh screenshot /tmp/tempfile.png`.
  5. **Option 5 (Pre-Approved ADB Screencap / Maestro CLI)**.

## 4. Marionette `*_feature.txt` Driving + `patrol_finders` BDD + Pragmatic TDD
- **Marionette `test/features/*_feature.txt` Specs**: Write human-readable Gherkin `*_feature.txt` files driven interactively via Marionette MCP/CLI and converted into fast `patrol_finders` widget tests (`patrolWidgetTest` / `$`) or Patrol native integration tests (`patrolTest`).
- **Pragmatic Unit TDD**: Use Red-Green-Refactor unit tests strictly for genuine domain/business logic.
- **Visual Screenshots & Videos on Wiki, PRs & Issues**: Follow `plan_to_make_videos_and_screenshots_for_wiki_and_prs_andgithub_issues.md` to capture and embed screenshots/videos across the Wiki (`refuge.wiki.git`), Pull Requests, and GitHub Issues.
