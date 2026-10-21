# Global Agent Instructions for Belong on the Spectrum (`AGENTS.md`)

## 1. Strictly Prioritize GitHub MCP Server — Zero Terminal Push Prompts
- **GitHub MCP Server Tools**: ALWAYS use GitHub MCP tools (`call_mcp_tool(ServerName: 'github', ...)`):
  - `create_branch` (Create remote branch from base)
  - `push_files` (Push atomic commits directly without terminal permissions)
  - `create_pull_request` & `merge_pull_request` (Open and squash-merge PRs)
  - `pull_request_read` (Inspect diffs, reviews, and CodeRabbit comments)
  - `issue_write`, `issue_read`, and `add_issue_comment` (Full ticket management)
- **Zero Approval Prompts**: ALWAYS use GitHub MCP tools (`push_files`, `create_pull_request`, `merge_pull_request`) for pushing branches and managing PRs. Never prompt the user with interactive terminal push dialogs.
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

## 4. Zero-Prompt Device Screenshots & 5 Non-Blocking Options
To ensure uninterrupted unattended operation without triggering terminal permission dialogs, agents MUST use one of the following 5 zero-prompt options in priority order:
1. **Option 1 (Patrol MCP)**: `call_mcp_tool(ServerName: 'patrol', ToolName: 'screenshot')` — direct MCP RPC with 0 terminal prompts.
2. **Option 2 (Marionette MCP / CLI)**: `call_mcp_tool(ServerName: 'marionette', ToolName: 'take_screenshot')` or `dart tool/marionette_drive.dart screenshot` — 0 terminal prompts.
3. **Option 3 (Pre-Approved Fixed Script)**: `/Users/neil/belongonthespectrum/refuge/tool/capture_device.sh screenshot /tmp/tempfile.png` — fixed allowlisted path auto-approved via prefix matching. NEVER use dynamic worktree paths (`.worktrees/issue-*`), `bash -c '...'`, command substitutions `$()`, or pipelines that break prefix matching!
4. **Option 4 (Pre-Approved ADB Screencap)**: `adb exec-out screencap -p > /tmp/tempfile.png` or `adb shell screencap -p /sdcard/tempfile.png && adb pull /sdcard/tempfile.png /tmp/tempfile.png`.
5. **Option 5 (Maestro CLI)**: `maestro screenshot /tmp/tempfile.png`.
- **Auto Clean-Frame & Zero-PII**: `tool/capture_device.sh` automatically strips status bars and navigation pills (1080x2160 via `sips`) to eliminate battery levels, carrier clocks, notifications, and personal home screen apps.
