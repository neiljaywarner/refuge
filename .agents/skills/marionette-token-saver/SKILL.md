---
name: marionette-token-saver
description: Token-optimized workflow for driving Flutter apps on Chrome and physical devices via Marionette MCP (marionette_mcp) without wasting quota on repeated full-screen screenshots or DOM dumps.
---

# Marionette MCP Token-Saver Skill (`marionette_mcp`)

When verifying Flutter UI changes via `marionette` MCP (`connect`, `get_interactive_elements`, `tap`, `enter_text`, `scroll_to`, `hot_reload`, `take_screenshots`), follow these strict token-saving rules:

## 1. Prefer `get_interactive_elements` Over `take_screenshots` (Saves ~90% of Tokens)
- A single screenshot (`take_screenshots`) consumes **1,200–2,000+ vision tokens** in the conversation history on every subsequent turn.
- Calling `get_interactive_elements` returns a compact, structured text list of visible buttons, tabs, text fields, and labels for **~100–250 tokens**.
- **Rule**: Use `get_interactive_elements` for all intermediate navigation, tab switching, and assertion checks. Only call `take_screenshots` **once at the very end of a milestone** if visual proof is specifically needed.

## 2. Fast Red-Green-Refactor Verification Loop
1. Run unit/BDD widget tests first via `/opt/homebrew/bin/flutter test <path_to_test.dart>` (~1 second, ~100 tokens).
2. Once tests pass, call `hot_reload` via `marionette` MCP (~500ms) instead of restarting `flutter run`.
3. Call `get_interactive_elements` to confirm the new widgets (`Key` or `text`) are mounted and interactive.
4. Perform targeted `tap` / `enter_text` calls by `Key` or `text` matcher.
