# Global Agent Instructions for Belong on the Spectrum (`AGENTS.md`)

## 1. Prioritize MCP Servers Over CLI
- **GitHub MCP Server**: Whenever active, ALWAYS prioritize GitHub MCP server tools (`create_pull_request`, `create_issue`, `push_files`, `add_comment`) over `gh` CLI. Only fall back to `gh` CLI when MCP is not available.
- **Dart MCP Server**: ALWAYS use `analyze_files` and `run_tests` via Dart MCP instead of raw shell commands.
- **Patrol MCP Server**: ALWAYS use `patrol` MCP tools (`run`, `screenshot`, `native-tree`) for native Android/PWA device tests.

## 2. Strict Ticket-Driven Development
- 1 Issue = 1 Worktree = 1 PR.
- No direct commits to `main`.
- Worktrees live in `/Users/neil/belongonthespectrum/.worktrees/issue-<NUM>-<slug>`.
- Open atomic PRs referencing `Closes #<NUM>`.

## 3. Real Device Driving
- Always drive the connected Google Pixel 9a (`56091JEBF14039`) using Marionette and Patrol. Never declare UI features complete based on headless tests alone.
