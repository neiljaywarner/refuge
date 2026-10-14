---
name: marionette-dual-device-walkthrough
description: Automated end-to-end multi-device interaction, verification, and video walkthrough skill using Marionette MCP and physical Android devices (ADB / screenrecord). Use when recording side-by-side or staggered synchronized live flows between multiple Flutter mobile clients.
---

# Marionette Dual-Device Live Walkthrough Skill

This skill documents and automates multi-device end-to-end walkthroughs for Flutter applications connecting to real-time backends (such as Serverpod Cloud). It combines Marionette MCP interactive tools with native ADB screen recording and logcat inspection.

## 1. Marionette MCP Server Tool Reference

Marionette connects to a Flutter application running with VM Service enabled (`ws://127.0.0.1:<PORT>/ws`).

| Tool | Purpose | Key Parameters |
|---|---|---|
| `connect` | Connects to Flutter VM service | `uri` (e.g. `ws://127.0.0.1:8181/ws`), `session_title` |
| `disconnect` | Closes active VM service connection | none |
| `get_interactive_elements` | Queries interactive UI hierarchy | `ancestor_keys`, `compaction` ('compact' / 'none') |
| `tap` | Taps element or screen coordinate | `key`, `text`, `x`, `y` |
| `double_tap` | Double taps element | `key`, `text`, `x`, `y` |
| `long_press` | Long presses element | `key`, `text`, `x`, `y` |
| `enter_text` | Enters text into focused field | `text`, `clear_existing` (boolean) |
| `scroll_to` | Scrolls until target element is visible | `key`, `text`, `scrollable_key` |
| `swipe` | Performs touch gesture | `direction` ('up', 'down', 'left', 'right'), `distance` |
| `press_back_button` | Simulates Android Back key | none |
| `press_key` | Triggers specific key code | `key` |
| `take_screenshots` | Captures high-res screenshot | `name` |
| `get_logs` | Fetches VM and Flutter console logs | none |
| `hot_reload` | Hot reloads app code preserving state | none |
| `hot_restart` | Fully restarts Flutter application | none |
| `set_device_config` | Changes brightness / locale | `platform_brightness`, `text_scale_factor` |

---

## 2. Dual Physical Device Workflow (Pixel 9a + Cellular LTE)

When coordinating two physical devices (e.g., Device A on left, Device B on right):

### Step 1: Device Configuration & Connectivity
1. Verify attached devices: `adb devices -l`
2. Ensure release or profile APK contains required Android permissions:
   - `<uses-permission android:name="android.permission.INTERNET"/>`
   - `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>`
3. Pass runtime backend definitions:
   ```bash
   flutter build apk --release \
     --dart-define=BACKEND=serverpod \
     --dart-define=SERVERPOD_URL=https://refuge4serverpod.api.serverpod.space/
   ```

### Step 2: Staggered Interaction Scripting
In real-time multi-user apps, stagger actions across the two devices:
1. **Device B (Sender)**:
   - Tap reflection input field (`input tap <x> <y>`)
   - Type message with visible timestamp: `[HH:MM:SS LTE] <message>`
   - Dismiss soft keyboard cleanly (`adb shell input keyevent 4`)
   - Tap **Publish Reflection**
2. **Device A (Receiver)**:
   - Wait for WebSocket broadcast event (sub-second)
   - Assert new post appears at top of feed
   - Tap affirmation reaction (e.g., Praying / Support)
3. **Device A (Reply)**:
   - Compose reply with timestamp
   - Dismiss soft keyboard
   - Tap **Publish Reflection**
4. **Device B (Receiver)**:
   - Verify reply appears in real time
   - Tap Care affirmation

### Step 3: Screen Recording & Artifact Pull
1. Start recording simultaneously:
   ```bash
   adb -s <DEVICE_A> shell screenrecord --time-limit 50 --bit-rate 8000000 /sdcard/left.mp4 &
   adb -s <DEVICE_B> shell screenrecord --time-limit 50 --bit-rate 8000000 /sdcard/right.mp4 &
   ```
2. Pull video files:
   ```bash
   adb -s <DEVICE_A> pull /sdcard/left.mp4 sanctuary_pixel_left.mp4
   adb -s <DEVICE_B> pull /sdcard/right.mp4 sanctuary_pixel_right.mp4
   ```

### Step 4: Verification & Logging
- Capture adb screencap at every milestone: `adb exec-out screencap -p > stepN.png`
- Stream logcat to verify Serverpod RPC calls (`onSucceededCall`, `onFailedCall`) and WebSocket streaming events (`session.messages.createStream`).
