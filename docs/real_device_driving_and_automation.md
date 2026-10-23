# 📱 Real Device Driving, Maestro Automation & Testing Architecture

**Authoritative Guide for Humans & AI Agents Driving Real Hardware & Emulators**  
**Repository**: [Belong on the Spectrum (Refuge)](https://github.com/neiljaywarner/refuge)  
**Tracking Issues**: [#73](https://github.com/neiljaywarner/refuge/issues/73), [#355](https://github.com/neiljaywarner/refuge/issues/355)  
**Status**: Active & Fully Operational  

---

## 1. Tool Priority & Hierarchy

> [!IMPORTANT]
> **Maestro is fully installed and operational.** Both the Maestro CLI (`maestro`) and the native **Maestro MCP Server** (`ServerName: 'maestro'`) are available for zero-prompt unattended device driving.

| Priority | Tool / Engine | Primary Capabilities | Operational Notes |
| :---: | :--- | :--- | :--- |
| **1 (Highest)** | **Maestro MCP Server** (`ServerName: 'maestro'`) & CLI | Instant zero-prompt device screenshots, view hierarchy inspection (`inspect_screen`), declarative YAML flow execution (`run`), and live Maestro Viewer at `http://127.0.0.1:9999/` | Priority #1 for visual evidence on PRs & issues. Executes with 0 terminal permission dialogs. |
| **2** | **Patrol MCP** (`ServerName: 'patrol'`) & `patrol_finders` | Sub-2-second widget BDD tests (`patrolWidgetTest`, `$` selector) and native OS automation (notification shade, permission dialogs) | Use `patrol_finders` for deterministic component testing. Run native suites via Patrol MCP. |
| **3** | **Marionette MCP / CLI** (`marionette_flutter`) | Token-optimized interactive widget driving (`get_interactive_elements`, <200 tokens) without full-screen screenshot token burn | Requires `lib/main_dev.dart` with `MarionetteBinding`. Perfect for rapid form filling and tab switching. |
| **4** | **Pre-Approved Clean Script** (`tool/capture_device.sh`) | Allowlisted path auto-approved via prefix matching; captures and strips status bars (1080x2160 via `sips`) | Eliminates personal battery levels, carrier clocks, and notification PII. |
| **5** | **Direct ADB Screencap** (`adb exec-out screencap -p`) | Fallback raw screenshot capture | Used when MCP server processes are cycling. |

---

## 2. Connected Device Fleet

| Device | Identifier / Serial | Form Factor | Primary Usage |
| :--- | :--- | :--- | :--- |
| **Google Pixel 9a** | `56091JEBF14039` | Physical Android 14+ | Primary real-device glass verification, camera/avatar capture, Google Password Manager autofill |
| **Google Pixel 8** | `58221JEBF20835` | Physical Android 14+ | Secondary device for dual-device live concurrency and real-time WebSocket sync verification |
| **Android Emulator** | `emulator-5554` | Medium Phone API 35/37 | Unattended background test execution, regression runs when physical hardware is unplugged |
| **Chromium Browser** | `chromium` | Desktop / Mobile Web | PWA responsive layout verification and desktop browser testing |

---

## 3. Maestro MCP Operational Guide

### Direct MCP Tool Invocations (Zero Terminal Prompts)

#### A. Instant Clean Screenshot (`take_screenshot`)
```json
{
  "ServerName": "maestro",
  "ToolName": "take_screenshot",
  "Arguments": {
    "device_id": "emulator-5554" // or "56091JEBF14039"
  }
}
```

#### B. UI View Hierarchy Inspection (`inspect_screen`)
Dumps the complete Android view hierarchy to inspect exact accessibility strings and test keys without guessing:
```json
{
  "ServerName": "maestro",
  "ToolName": "inspect_screen",
  "Arguments": {
    "device_id": "emulator-5554"
  }
}
```

#### C. Declarative Flow Execution (`run`)
Runs inline Maestro YAML with appId header:
```json
{
  "ServerName": "maestro",
  "ToolName": "run",
  "Arguments": {
    "device_id": "emulator-5554",
    "yaml": "appId: com.belongonthespectrum.sanctuary\n---\n- tapOn: \"Spaces\"\n- tapOn: \".*Members Section & Directory.*\"\n"
  }
}
```

#### D. Live Maestro Web Viewer
Launch the live browser viewer at **`http://127.0.0.1:9999/`** via MCP `open_maestro_viewer` for real-time visual inspection during unattended sessions.

---

## 4. Maestro Flow Catalog (`.maestro/`)

1. **`.maestro/smoke_test.yaml`**: App launch, header logo verification, theme toggling, and calm feed loading.
2. **`.maestro/spaces_navigation_and_monogram_flow.yaml`**: Navigates from Feed to Spaces, opens Member Directory, and verifies monogram initials (`FM`, `HM`, `MO`).
3. **`.maestro/feed_bookmark_and_sort_flow.yaml`**: Tests multi-criteria feed sorting (`Latest`, `For you`, `New Activity`, `Oldest`) and private bookmarks.

---

## 5. Patrol BDD & Widget Testing Guide

We use **`patrol_finders`** for rapid widget tests:
```dart
patrolWidgetTest('Tapping bookmark ribbon updates saved count', ($) async {
  await $.pumpWidgetAndSettle(createTestHarness());
  expect($(Key('empty_saved_reflections_placeholder')), findsNothing);
  await $(Icons.bookmark_border_rounded).tap();
  expect($(Key('empty_saved_reflections_placeholder')), findsOneWidget);
});
```

Execute tests via Dart MCP (`run_tests`) for sub-2-second execution cycles:
```json
{
  "ServerName": "dart",
  "ToolName": "run_tests",
  "Arguments": {
    "roots": [{
      "root": "file:///Users/neil/belongonthespectrum/refuge",
      "paths": ["test/features/reflections/save_for_later_bookmarks_test.dart"]
    }]
  }
}
```

---

## 6. Single-Command Turnkey Hardware Regression Runner

To execute the entire physical glass regression suite (screen wake, Patrol BDD, Maestro journeys, clean-frame 1080x2160 screenshots, and audit report generation) in one command:

```bash
# Auto-detects connected Pixel and runs full regression suite
./tool/run_physical_glass_regression.sh

# Dry-run inspection without triggering UI taps
./tool/run_physical_glass_regression.sh --dry-run
```
