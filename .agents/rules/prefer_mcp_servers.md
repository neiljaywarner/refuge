---
trigger: always_on
description: Mandatory rule requiring all agents to strictly prioritize MCP server tools (GitHub MCP, Maestro MCP, Dart MCP, Patrol MCP, Marionette MCP) over raw shell CLI commands.
---

# Mandatory MCP Server Prioritization Rule

Every agent (across all model tiers) working in `/Users/neil/belongonthespectrum` and `/Users/neil/belongonthespectrum/refuge` MUST adhere to the following MCP prioritization hierarchy:

## 1. GitHub Operations (Zero Terminal Prompts)
- **Strictly Prioritize GitHub MCP Server (`call_mcp_tool(ServerName: 'github', ...)` / `github_github`)**:
  - **Branch Creation**: `create_branch` (`owner`, `repo`, `branch`, `from_branch`)
  - **Pushing Code**: `push_files` (`owner`, `repo`, `branch`, `files: [{path, content}]`, `message`)
  - **Pull Requests**:
    - `create_pull_request` (`owner`, `repo`, `title`, `head`, `base`, `body`)
    - `pull_request_read` (`method`: `get`, `get_diff`, `get_status`, `get_files`, `get_commits`, `get_review_comments`, `get_reviews`, `get_comments`, `get_check_runs`)
    - `merge_pull_request` (`owner`, `repo`, `pullNumber`, `merge_method`: `squash`|`merge`|`rebase`, `commit_title`)
    - `update_pull_request` / `update_pull_request_branch`
    - `pull_request_review_write` / `add_reply_to_pull_request_comment`
  - **Issues**:
    - `issue_write` (`method`: `create`, `update`, `close`)
    - `issue_read` (`method`: `get`, `list_comments`)
    - `add_issue_comment` (`owner`, `repo`, `issueNumber`, `body`)
    - `list_issues` / `search_issues`
  - **Releases & Actions**:
    - `list_releases` / `get_latest_release` / `get_release_by_tag`
    - `actions_list` / `actions_get` / `actions_run_trigger`
- **Zero Approval Prompts**: GitHub MCP tools execute as direct API calls and NEVER prompt the user with terminal permission popups. NEVER use interactive `git push` if it triggers terminal approval.

## 2. Maestro MCP Server — Device Driving, Screen Inspection & Instant Screenshots
- **Strictly Prioritize Maestro MCP Server (`call_mcp_tool(ServerName: 'maestro', ...)` / `maestro`)**:
  - `list_devices`: discover connected hardware (Pixel `56091JEBF14039`, Pixel `58221JEBF20835`, `emulator-5554`, `chromium`)
  - `take_screenshot`: capture instant high-res device screenshots with **0 terminal prompts** (Priority #1)
  - `inspect_screen`: dump exact UI hierarchy to prevent hallucinated strings
  - `run`: execute declarative YAML flows across physical Pixels and emulators
  - `open_maestro_viewer`: surface live Maestro Viewer at `http://127.0.0.1:9999/`
  - `cheat_sheet`: look up full flow syntax, conditionals, and commands

## 3. Dart & Flutter Operations
- **Strictly Prioritize Dart MCP Server**:
  - Use `call_mcp_tool(ServerName: 'dart', ToolName: 'analyze_files')` instead of running `dart analyze` or `flutter analyze` via shell.
  - Use `call_mcp_tool(ServerName: 'dart', ToolName: 'run_tests')` instead of running `dart test` or `flutter test` via shell.
  - Use `hot_reload` and `hot_restart` via Dart MCP for running apps instead of restarting terminal processes.

## 4. Patrol & Marionette Device Driving
- **Strictly Prioritize Patrol & Marionette MCP**:
  - Use `call_mcp_tool(ServerName: 'patrol', ...)` (`devices`, `native-tree`, `run`, `screenshot`) for native UI automation and device verification.
  - Use Marionette MCP / stdio runner (`scratch/marionette_drive.dart`) for Flutter interactive element driving instead of blind `adb tap`.

## 5. Zero-Prompt Device Screenshots & 5 Non-Blocking Options
To ensure uninterrupted unattended operation without triggering terminal permission dialogs, agents MUST use one of the following 5 zero-prompt options in priority order:
1. **Option 1 (Maestro MCP - Highest Priority)**: `call_mcp_tool(ServerName: 'maestro', ToolName: 'take_screenshot', Arguments: {device_id: '56091JEBF14039'})` — instant direct MCP RPC with 0 terminal prompts across Pixels 1 & 2 and emulator.
2. **Option 2 (Patrol MCP)**: `call_mcp_tool(ServerName: 'patrol', ToolName: 'screenshot')` — direct MCP RPC with 0 terminal prompts.
3. **Option 3 (Marionette MCP / CLI)**: `call_mcp_tool(ServerName: 'marionette', ToolName: 'take_screenshot')` or `dart tool/marionette_drive.dart screenshot` — 0 terminal prompts.
4. **Option 4 (Pre-Approved Fixed Script)**: `/Users/neil/belongonthespectrum/refuge/tool/capture_device.sh screenshot /tmp/tempfile.png` — fixed allowlisted path auto-approved via prefix matching. NEVER use dynamic worktree paths (`.worktrees/issue-*`), `bash -c '...'`, command substitutions `$()`, or pipelines that break prefix matching!
5. **Option 5 (Pre-Approved ADB Screencap / Maestro CLI)**: `adb exec-out screencap -p > /tmp/tempfile.png` or `maestro screenshot /tmp/tempfile.png`.
- **Auto Clean-Frame & Zero-PII**: `tool/capture_device.sh` automatically strips status bars and navigation pills (1080x2160 via `sips`) to eliminate battery levels, carrier clocks, notifications, and personal home screen apps.
