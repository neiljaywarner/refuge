# Global Agent Instructions for Belong on the Spectrum (`AGENTS.md`)

## 1. Strictly Prioritize GitHub & Maestro MCP Servers — Zero Terminal Push Prompts
- **GitHub MCP Server Tools**: ALWAYS use GitHub MCP tools (`call_mcp_tool(ServerName: 'github', ...)`):
  - `create_branch` (Create remote branch from base)
  - `push_files` (Push atomic commits directly without terminal permissions)
  - `create_pull_request` & `merge_pull_request` (Open and squash-merge PRs)
  - `pull_request_read` (Inspect diffs, reviews, and CodeRabbit comments)
  - `issue_write`, `issue_read`, and `add_issue_comment` (Full ticket management)
- **Zero Approval Prompts**: ALWAYS use GitHub MCP tools (`push_files`, `create_pull_request`, `merge_pull_request`) for pushing branches and managing PRs. Never prompt the user with interactive terminal push dialogs.
- **Maestro MCP Server**: ALWAYS use Maestro MCP tools (`call_mcp_tool(ServerName: 'maestro', ...)`):
  - `list_devices`: discover connected hardware (Pixel `56091JEBF14039`, Pixel `58221JEBF20835`, `emulator-5554`, `chromium`)
  - `take_screenshot`: capture instant high-res device screenshots with **0 terminal prompts** (Priority #1)
  - `inspect_screen`: inspect active screen view hierarchy JSON to avoid hallucinated UI selectors
  - `run`: execute declarative YAML flows across physical Pixels and emulators
  - `open_maestro_viewer`: surface live Maestro Viewer at `http://127.0.0.1:9999/`
  - `cheat_sheet`: look up full flow syntax, conditionals, and commands
- **Dart MCP Server**: ALWAYS use `analyze_files` and `run_tests` via Dart MCP instead of raw shell commands.
- **Patrol MCP Server & Device Driving**: Use Patrol MCP or `tool/capture_device.sh` targeting connected Pixels or falling back to `emulator-5554` or Chrome.

## 2. Strict Ticket-Driven Development for EVERY Prompt
- 1 Issue = 1 Worktree = 1 PR for EVERY single prompt without exception.
- No direct commits to `main`.
- Worktrees live in `/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>`.
- Open atomic PRs referencing `Closes #<NUM>`.
- **Mandatory Verification Step / Comment on EVERY Issue & PR (UI & Non-UI)**: Every ticket and PR must include exact confirmation steps, commands executed, and verified results (plus Before/After screenshots for UI changes).
- **Mandatory CodeRabbit Completion Wait Protocol**: When opening a PR, trigger `@coderabbitai review` and ALWAYS wait/poll (minimum 90–180 seconds) until CodeRabbit finishes analyzing and posts its review comments before merging. NEVER squash-merge while review is in progress (`"Currently processing new changes"`). Triage all findings into focused GitHub issues.

## 3. Real Device Driving & *Mandatory Before/After Visual Evidence*
- Always drive the connected Google Pixels (`56091JEBF14039`, `58221JEBF20835`) or physical Android device using Maestro, Marionette, and Patrol (falling back to `emulator-5554` or Chrome when unplugged). Never declare UI features complete based on headless tests alone.
- ***Mandatory Visual Verification Step\***: Every UI, branding, icon, or styling PR MUST include side-by-side **Before and After** screenshots/videos attached to BOTH the GitHub Issue and the Pull Request before declaring complete.

## 4. Zero-Prompt Device Screenshots & 5 Non-Blocking Options
To ensure uninterrupted unattended operation without triggering terminal permission dialogs, agents MUST use one of the following 5 zero-prompt options in priority order:
1. **Option 1 (Maestro MCP - Highest Priority)**: `call_mcp_tool(ServerName: 'maestro', ToolName: 'take_screenshot', Arguments: {device_id: '56091JEBF14039'})` — instant direct MCP RPC with 0 terminal prompts across Pixels 1 & 2 and emulator.
2. **Option 2 (Patrol MCP)**: `call_mcp_tool(ServerName: 'patrol', ToolName: 'screenshot')` — direct MCP RPC with 0 terminal prompts.
3. **Option 3 (Marionette MCP / CLI)**: `call_mcp_tool(ServerName: 'marionette', ToolName: 'take_screenshot')` or `dart tool/marionette_drive.dart screenshot` — 0 terminal prompts.
4. **Option 4 (Pre-Approved Fixed Script)**: `/Users/neil/belongonthespectrum/refuge/tool/capture_device.sh screenshot /tmp/tempfile.png` — fixed allowlisted path auto-approved via prefix matching. NEVER use dynamic worktree paths (`.worktrees/issue-*`), `bash -c '...'`, command substitutions `$()`, or pipelines that break prefix matching!
5. **Option 5 (Pre-Approved ADB Screencap / Maestro CLI)**: `adb exec-out screencap -p > /tmp/tempfile.png` or `maestro screenshot /tmp/tempfile.png`.
- **Auto Clean-Frame & Zero-PII**: `tool/capture_device.sh` automatically strips status bars and navigation pills (1080x2160 via `sips`) to eliminate battery levels, carrier clocks, notifications, and personal home screen apps.
