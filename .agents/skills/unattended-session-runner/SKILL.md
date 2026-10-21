---
name: unattended-session-runner
description: Operational playbook for autonomous, token-optimized, multi-hour unattended development sessions. Use when operating unattended for 2-4 hours to deliver verified milestones, PRs, and visual evidence without getting stuck.
---

# 🌙 Unattended Session Runner Skill

This skill governs multi-hour autonomous development sessions (e.g. overnight or 2–4 hour unattended blocks) on the Belong on the Spectrum / Refuge codebase.

---

## 🧭 Core Principles

1. **Zero-Stall Rule**:
   - Never wait indefinitely for manual input when safe, verified fallbacks exist.
   - If an external reviewer or tool is rate-limited (e.g., CodeRabbit free tier), verify locally with Dart MCP (`analyze_files`, `run_tests`), on-device tests, and privacy scan, then proceed with the squash-merge.
2. **Strict Prefix-Matched Command Shapes**:
   - Never use command chains (`&&`, `;`, `||`) for operations requiring permissions.
   - Always invoke commands as single unchained invocations to allow user-granted prefix matching (`tool/capture_device.sh ...`, `gh pr merge ...`).
3. **Token Quota Conservation**:
   - Favor compact outputs and targeted file reads.
   - Prefer Dart MCP tools (`run_tests`, `analyze_files`) over terminal commands.
   - Avoid dumping entire widget trees or full DOMs when inspecting elements.
4. **Maestro MCP Real Hardware Verification**:
   - Validate UI changes across connected Pixels (`56091JEBF14039`, `58221JEBF20835`) or Android emulator (`emulator-5554`) using Maestro MCP (`run` and `take_screenshot`).
   - Capture Before & After screenshots with zero terminal prompts using Maestro MCP `take_screenshot`.
5. **Continuous Dashboard Sync**:
   - Keep `status.md`, `unattended_session_*.md`, and `neil_to_review_sunday_night.md` up to date with fresh timestamps and verified metrics.

---

## 📋 Session Checklist

- [ ] Verify background power lock: `caffeinate -dimsu -t <seconds>`
- [ ] Discover connected hardware via Maestro MCP: `call_mcp_tool(ServerName: 'maestro', ToolName: 'list_devices', Arguments: {})`
- [ ] Verify test suite baseline before beginning branch work: `175/175` passing green
- [ ] Create isolated worktree under `.worktrees/issue-<NUM>-<slug>`
- [ ] Implement Red-Green-Refactor tests and domain logic
- [ ] Verify static analysis: `0 errors`
- [ ] Verify on physical hardware with Maestro flow and capture screenshot via Maestro MCP `take_screenshot`
- [ ] Run privacy scan: `dart run tool/refuge_cli.dart privacy-scan` (Zero PII)
- [ ] Push branch, open PR referencing `Closes #<NUM>`, trigger review
- [ ] Verify, squash-merge, prune worktree, and pull `main`
- [ ] Update status dashboard and checkpoint timestamps
