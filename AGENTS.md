# Global Agent Instructions for Belong on the Spectrum (`AGENTS.md`)

## 1. Strictly Prioritize GitHub MCP Server — Zero Terminal Push Prompts
- **GitHub MCP Server Tools**: ALWAYS use GitHub MCP tools (`call_mcp_tool(ServerName: 'github', ...)`):
  - `create_branch` (Create remote branch from base)
  - `push_files` (Push atomic commits directly via GitHub API with zero terminal permissions)
  - `create_pull_request` & `merge_pull_request` (Open and squash-merge PRs)
  - `pull_request_read` (Inspect diffs, reviews, and CodeRabbit comments)
  - `issue_write`, `issue_read`, and `add_issue_comment` (Full ticket management)
- **Zero Approval Prompts**: ALWAYS use GitHub MCP tools (`push_files`, `create_pull_request`, `merge_pull_request`) for pushing branches, creating PRs, and merging. Never prompt the user with terminal git push dialogs.
- **Dart MCP Server**: ALWAYS use `analyze_files` and `run_tests` via Dart MCP instead of raw shell commands.
- **Patrol MCP Server & Device Driving**: Use Patrol MCP or `tool/capture_device.sh` targeting the connected Pixel or automatically falling back to the "Medium Phone" emulator (`emulator-5554`) or Chrome when the physical device is unplugged.

## 2. Strict Ticket-Driven Development for EVERY Prompt
- 1 Issue = 1 Worktree = 1 PR for EVERY single prompt without exception.
- No direct commits to `main`.
- Worktrees live in `/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>`.
- Open atomic PRs referencing `Closes #<NUM>`.
- **Mandatory Verification Step / Comment on EVERY Issue & PR (UI & Non-UI)**: Every ticket and PR must include exact confirmation steps, commands executed, and verified results (plus Before/After screenshots for UI changes).

## 3. Real Device Driving & *Mandatory Before/After Visual Evidence*
- Always drive the connected Google Pixel or physical Android device using Marionette and Patrol (falling back to the Android emulator or Chrome when unplugged). Never declare UI features complete based on headless tests alone.
- ***Mandatory Visual Verification Step\***: Every UI, branding, icon, or styling PR MUST include side-by-side **Before and After** screenshots/videos attached to BOTH the GitHub Issue and the Pull Request before declaring complete.
