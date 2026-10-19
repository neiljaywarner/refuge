---
name: patrol-token-saver
description: Token-optimized workflow for running Patrol MCP (patrol_mcp) and Patrol CLI (patrol) on physical devices (Pixel 9a) without burning vision or log tokens.
---

# Patrol MCP & CLI Token-Saver Skill (`patrol_mcp` / `patrol_cli`)

When running native mobile integration tests or inspecting native UI on the physical **Pixel 9a** via `patrol` MCP (`devices`, `native-tree`, `run`, `screenshot`, `status`, `quit`), follow these strict token-saving rules:

## 1. Use `native-tree` Instead of `screenshot`
- Calling `patrol` `screenshot` injects a high-resolution mobile screenshot (**1,500+ tokens**) into the transcript that persists across every subsequent turn.
- Calling `native-tree` returns a compact XML/JSON summary of native system dialogs (permissions, OAuth sheets, notifications) for **~150 tokens**.

## 2. Prefer `flutter test` (`bdd_widget_test`) First, `patrol` Second
- Run 95% of Red-Green-Refactor cycles using `/opt/homebrew/bin/flutter test` (~1 second, zero device build overhead).
- Only invoke `patrol` `run` at release checkpoints (`v0.7.0`, `v0.9.0-rc`, `v1.0.0`) when verifying native Android/iOS interactions on the physical **Pixel 9a**.
