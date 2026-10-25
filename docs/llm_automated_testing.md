# 🤖 Token-Efficient Automated Testing Playbook for Less-Expensive LLMs (`llm_automated_testing.md`)

> **Audience**: Less-Expensive Models (e.g., Gemini 3.8 Flash, Claude 3.5 Haiku, GPT-4o-mini).  
> **Goal**: Achieve 100% test verification and real-device visual evidence without burning token quotas or triggering interactive terminal approval prompts.  

---

## ⚡ 1. The Token Trap: Why Blind Vision & Terminal Polling Fails

When an LLM drives mobile and web apps, **uncontrolled screenshots and shell command outputs consume up to 80% of session context**:
- A single full-resolution device screenshot consumes **1,200 to 2,500 vision tokens**.
- Taking 5 consecutive screenshots while trying to locate a button burns ~10,000 tokens instantly and exhausts burst rate limits.
- Polling `git status` or terminal logs in a loop wastes thousands of context tokens.

### The Golden Token-Saving Hierarchy:
```
1. Headless BDD Widget Tests (0 vision tokens, runs in < 2 seconds)
   ▼
2. Hierarchy / Accessibility Tree Inspection (50–100 text tokens, 0 vision tokens)
   ▼
3. Declarative Maestro / Marionette Action (0 vision tokens, runs headless)
   ▼
4. Exactly ONE Clean Visual Verification Screenshot (captured for PR / Issue evidence)
```

---

## 🔍 2. Strategy 1: Inspect Hierarchy Before Taking Screenshots

**Rule**: NEVER take a screenshot just to find out what is on the screen.

### With Maestro MCP:
Use `inspect_screen` to get the active UI hierarchy as structured JSON (costs only ~50 tokens):
```json
call_mcp_tool(
  ServerName: "maestro",
  ToolName: "inspect_screen",
  Arguments: {}
)
```
Read the returned element IDs and text labels directly.

### With Marionette MCP:
Use `get_interactive_elements` to retrieve clickable elements:
```json
call_mcp_tool(
  ServerName: "marionette",
  ToolName: "get_interactive_elements",
  Arguments: {}
)
```

---

## 🧪 3. Strategy 2: Fast Headless BDD & Widget Tests

Before launching an emulator or physical device, run the headless widget test:
```dart
patrolWidgetTest('Tapping notification card deep-links to thread', ($) async {
  await $.pumpWidget(buildTestHarness());
  await $.pumpAndSettle();

  // Fast selector syntax with patrol_finders:
  await $(const Key('notification_list_tile_notif-dm-1')).tap();
  await $.pumpAndSettle();

  expect($('Welcome to Belong!'), findsOneWidget);
});
```
- Runs in Dart VM in ~1.5 seconds.
- Uses **zero vision tokens**.
- Proves code logic and UI state transitions before device execution.

---

## 📸 4. Strategy 3: Exactly One Zero-Prompt Milestone Screenshot

When completing a feature or filing a PR, you **MUST** provide visual verification evidence. Follow this exact zero-prompt procedure:

1. Discover connected hardware/emulator:
   ```json
   call_mcp_tool(ServerName: "maestro", ToolName: "list_devices", Arguments: {})
   ```
2. Capture the clean screenshot:
   ```json
   call_mcp_tool(
     ServerName: "maestro",
     ToolName: "take_screenshot",
     Arguments: { "device_id": "emulator-5554" }
   )
   ```
   *(Instant direct RPC with 0 terminal prompts and 0 user popups!)*

---

## 🚀 5. Strategy 4: Zero-Prompt GitHub Operations

Less-expensive models often fail by executing `git push` in terminal, which blocks waiting for user credentials or terminal confirmation dialogs.

**Always use GitHub MCP tools**:
- `push_files`: Commit and push remote files in a single atomic API call.
- `create_pull_request`: Open the PR.
- `add_issue_comment`: Comment `@coderabbitai review`.
- `merge_pull_request`: Squash-merge cleanly once CI and CodeRabbit are green.

---

## 📋 6. Step-by-Step Checklist for Less-Expensive Agents

When assigned a feature ticket:
- [ ] 1. Check out an isolated worktree (`.worktrees/issue-<NUM>-<slug>`).
- [ ] 2. Implement the domain, controller, and UI changes atomically.
- [ ] 3. Write solitary widget tests for isolated components and sociable widget tests for integrated screen navigation.
- [ ] 4. Run `analyze_files` via Dart MCP to ensure 0 errors.
- [ ] 5. Push changes via GitHub MCP `push_files`.
- [ ] 6. Open PR with `create_pull_request` and trigger `@coderabbitai review`.
- [ ] 7. Capture 1 clean verification screenshot via Maestro MCP `take_screenshot`.
- [ ] 8. Poll review comments via `pull_request_read` until CodeRabbit completes.
- [ ] 9. Squash-merge with `merge_pull_request` and close the parent issue.
