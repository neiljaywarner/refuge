# 🎭 LeanCode Marionette MCP Server & CLI Guide

This guide explains how developers and AI agents drive **Belong on the Spectrum** interactively on real devices (Google Pixel 9a), Android emulators (`emulator-5554`), and Chrome using **LeanCode Marionette** ([github.com/leancodepl/marionette](https://github.com/leancodepl/marionette)).

---

## 1. Why Marionette?
- **Token Efficiency**: Instead of burning ~1,500 vision tokens per full-screen screenshot, Marionette's `get_interactive_elements` dumps the widget tree semantics in **under 200 tokens**.
- **Deterministic Selectors**: Target widgets by `key`, text, or tooltip (e.g. `key('tab_feature_voting')`) rather than guessing pixel coordinates with brittle `adb tap`.
- **Live Dev Driving**: Connects over the Dart VM Service WebSocket; works seamlessly with `hot_reload` and `hot_restart`.

---

## 2. Architecture & Prerequisites

### App Setup (`lib/main_dev.dart`)
Marionette requires the `marionette_flutter` binding at startup:
```dart
// lib/main_dev.dart (Dev & Beta builds only)
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  MarionetteBinding.ensureInitialized();
  bootstrapBelongApp(flavor: AppFlavor.dev);
}
```

### Server Setup (`~/.gemini/config/mcp_config.json`)
The Marionette MCP server runs via `stdio` transport using the activated pub package:
```json
{
  "mcpServers": {
    "marionette": {
      "command": "/Users/neil/.pub-cache/bin/marionette_mcp",
      "args": []
    }
  }
}
```

---

## 3. Launching the App with Marionette

Run the dev entrypoint on your target device and copy the VM Service / DTD URI:

```bash
# Physical Pixel 9a
flutter run -t lib/main_dev.dart -d 56091JEBF14039

# Android Emulator (Medium Phone)
flutter run -t lib/main_dev.dart -d emulator-5554

# Chrome Web (Desktop / Mobile viewports)
flutter run -t lib/main_dev.dart -d chrome
```

Upon launch, Flutter prints the VM Service connection URI:
```
The Flutter DevTools debugger and profiler is available at: http://127.0.0.1:9100
An Observatory debugger and profiler on Google Pixel is available at: ws://127.0.0.1:56283/abc123xyz=/ws
```

---

## 4. Driving with Marionette MCP Server Tools

Once the MCP server connects to the app's VM Service URI, the following tools become available to AI agents:

| MCP Tool | Purpose | Typical Token Cost |
| :--- | :--- | :---: |
| `initialize` | Connects Marionette to the active VM Service WebSocket URI | ~50 tokens |
| `get_interactive_elements` | Returns all tappable, enterable, and scrollable widgets with Keys | **~150 tokens** |
| `tap` | Taps a widget by its key, label, or selector (e.g. `#submit_feedback_button`) | ~40 tokens |
| `enter_text` | Enters text into a focused or selected `TextField` | ~40 tokens |
| `scroll` | Scrolls a `ListView` or `SingleChildScrollView` by offset or delta | ~40 tokens |
| `take_screenshot` | Captures a PNG image for visual inspection | ~1,200 tokens |

### Pro-Tip: Token-Saving Workflow
1. Call `get_interactive_elements` first to find the widget's key.
2. Call `tap` with the key (e.g., `key: 'tab_private_feedback'`).
3. Only take a screenshot at the end of the milestone for PR visual proof.

---

## 5. Driving via Command Line (CLI Runner Script)

For automated BDD scripts or headless validation without full MCP chat interaction, use our standalone runner script:

```bash
# Inspect running app interactive elements
dart tool/marionette_drive.dart inspect --uri "ws://127.0.0.1:56283/..."

# Tap an element by key
dart tool/marionette_drive.dart tap --key "tab_feature_voting"

# Enter text into feedback input
dart tool/marionette_drive.dart text --key "feedback_message_input" --value "Calm and soothing!"

# Capture current widget state screenshot
dart tool/marionette_drive.dart screenshot --output "/tmp/marionette_screen.png"
```

---

## 6. Fallback Hierarchy (When Marionette is Detached)

1. **Marionette MCP / CLI** (Highest fidelity, semantic widget tree).
2. **Patrol CLI** (`patrol test -t integration_test/...` — full native Android permissions & UI).
3. **`tool/capture_device.sh`** (Auto-approvable ADB wrapper targeting Pixel or falling back to `emulator-5554`).
4. **Dart MCP Server** (`analyze_files`, `run_tests`).

---

## 7. Troubleshooting

- **`Could not connect to VM Service`**:
  Ensure the app was launched with `lib/main_dev.dart` (which calls `MarionetteBinding.ensureInitialized()`). Release builds do not expose the VM Service.
- **`Port already in use`**:
  Run `lsof -i :5037` or `adb kill-server && adb start-server` to resolve ADB socket conflicts.
- **`Widget not found in interactive elements`**:
  Check if the widget is scrolled off-screen. Call `scroll` to bring it into the viewport, then re-run `get_interactive_elements`.
