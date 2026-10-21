# 📱 Dual Pixel Cloud Demo — Hardware Verification & Live Walkthrough

> [!TIP]
> **Live Multi-Device Verification**: Real-time multi-device verification executed across physical Google Pixel 9a hardware and Android emulators operating on T-Mobile LTE and Wi-Fi, communicating over Serverpod Cloud (`refuge4serverpod.api.serverpod.space`).

---

## 🔬 Hardware, Network & Sensory Mode Specifications (v0.8.0-alpha)

Rather than relying purely on headless mocks or localhost network loopbacks, Belong on the Spectrum is continuously verified across physical smartphones and emulators:

| Specification | Pixel Left (Device 1) | Pixel Right (Device 2) | Fallback Target |
| :--- | :--- | :--- | :--- |
| **Model** | Google Pixel 9a | Google Pixel 9a | Android Emulator (`emulator-5554`) / Chrome |
| **Role** | Community Feed & About Dialog | Initiating Reflection & Dark Mode | Verification & Automated CI |
| **Operating System** | Android 15 | Android 15 | Android API 35 / Web |
| **Sensory Mode** | **Sage Botanical** (calming green) | **Monastic Dark** (low blue-light) | **Clean Slate** / **High Contrast** |
| **Resolution** | 1080 × 2424 px (420 dpi) | 1080 × 2424 px (420 dpi) | Responsive Viewport |
| **Backend Connected** | Serverpod Cloud | Serverpod Cloud | Serverpod Cloud / Local Seed Fallback |

---

## 📸 Verified Device Evidence (Clean-Frame Visual Proof)

Per our **Zero-PII & Clean-Frame Rule**, all verification screenshots are captured directly from connected hardware and cropped to remove system status bar indicators (battery, notification icons, carrier clocks) to focus strictly on pure application UI:

### 1. Dual Sensory Themes Side-by-Side (WCAG AAA)

| Pixel Left (Sage Botanical Mode) | Pixel Right (Monastic Dark Mode) |
| :---: | :---: |
| ![Sage Botanical Mode](images/dual_pixel_left_sage.png) | ![Monastic Dark Mode](images/dual_pixel_right_dark.png) |
| *Calming natural sage tones, organizer welcome banner, unhurried reflection feed* | *High contrast dark mode engineered to reduce visual sensory overload* |

---

### 2. Sensory Mode Selection & About Belong Dialog

| Sensory Theme Selection Menu | About Belong & Scripture Dialog |
| :---: | :---: |
| ![Sensory Menu](images/dual_pixel_theme_menu.png) | ![About Dialog](images/dual_pixel_about_dialog.png) |
| *1-Tap sensory theme switcher: Clean Slate, Sage Botanical, Monastic Dark, High Contrast* | *In-app Psalm 139:14 Scripture anchor, calm-tech principles, diagnostics & logs* |

---

## 🎬 Real-Time Multi-Device Demonstration Flow

The live multi-device interaction sequence verifies real-time bidirectional synchronization over Serverpod Cloud:

```
[Pixel Right] ─────► Publishes Reflection over Serverpod Cloud
                          │
                          ▼ (WebSocket session messages stream)
[Pixel Left]  ◄───── Receives Post in Real Time & Taps "🙏 Praying" Reaction
                          │
                          ▼
[Pixel Left]  ─────► Opens "About Belong" Dialog (Psalm 139:14 Scripture)
                          │
[Pixel Right] ─────► Toggles Theme to "Monastic Dark" for sensory rest
```

### Verified Interaction Steps:
1. **Pixel Right Composes Reflection**:
   - Taps unhurried composer text box.
   - Types: *"Praising God for unhurried fellowship via Serverpod Cloud!"*
   - Selects Intent Tag `[Prayer Request]`.
   - Taps **Publish Reflection**.
2. **Pixel Left Synchronizes Live**:
   - Stream updates within **sub-second latency** without page reload or manual refresh.
   - Member taps **`🙏 9 Praying`** reaction chip; reaction count atomically increments across both devices.
3. **Sensory Theme Customization**:
   - Pixel Right taps the sensory theme icon (`☀️`) and selects **🌙 Dark**. The entire theme dynamically switches without losing composer state or scroll position.
4. **Calm-Tech Transparency**:
   - Pixel Left taps the Info (`(i)`) button, presenting the **About Belong on the Spectrum** dialog:
     > *"I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."* — **Psalm 139:14**
   - Displays version `v0.8.0-alpha`, church partnership information, and diagnostics log link.

---

## 🤖 Dynamic Automated Test Driver (`scripts/run_dual_pixel_demo.sh`)

Our test driving scripts dynamically auto-detect connected physical Pixel devices and gracefully fall back to the Android emulator or environment overrides without hardcoding any hardware serial numbers:

```bash
#!/bin/bash
set -e

# Auto-detect connected devices dynamically:
PHYSICAL_DEVICES=($(adb devices 2>/dev/null | awk '$2=="device" && !/emulator/ {print $1}'))
if [ ${#PHYSICAL_DEVICES[@]} -ge 2 ]; then
  DEVICES=("${PHYSICAL_DEVICES[@]}")
else
  DEVICES=($(adb devices 2>/dev/null | awk '$2=="device" {print $1}'))
fi

LEFT_DEV="${LEFT_DEV:-${DEVICES[0]}}"
RIGHT_DEV="${RIGHT_DEV:-${DEVICES[1]}}"

if [ -z "$LEFT_DEV" ] || [ -z "$RIGHT_DEV" ]; then
  echo "Error: Two Android devices are required. Found: ${#DEVICES[@]}"
  echo "Specify explicitly via: LEFT_DEV=<dev1> RIGHT_DEV=<dev2> $0"
  exit 1
fi

echo "=== Driving Pixel Left ($LEFT_DEV) and Pixel Right ($RIGHT_DEV) ==="

# 1. Start concurrent screen recordings
adb -s $LEFT_DEV shell screenrecord --time-limit 45 /sdcard/left_pixel_demo.mp4 &
LEFT_PID=$!
adb -s $RIGHT_DEV shell screenrecord --time-limit 45 /sdcard/right_pixel_demo.mp4 &
RIGHT_PID=$!

# 2. Pixel Right posts to Serverpod Cloud
adb -s $RIGHT_DEV shell input tap 524 1266
adb -s $RIGHT_DEV shell "input text 'From%spixel%son%sthe%sright%ssaying%shi%svia%sServerpod%sCloud!'"
adb -s $RIGHT_DEV shell input keyevent 4 # Dismiss keyboard cleanly
adb -s $RIGHT_DEV shell input tap 778 1470 # Publish Reflection

# 3. Pixel Left reacts and opens About dialog
sleep 3
adb -s $LEFT_DEV shell input tap 184 2119 # Praying reaction
adb -s $LEFT_DEV shell input tap 699 225  # About Belong dialog

# 4. Finalize and pull recordings
wait $LEFT_PID $RIGHT_PID 2>/dev/null || true
adb -s $LEFT_DEV pull /sdcard/left_pixel_demo.mp4 ./sanctuary_pixel_left.mp4
adb -s $RIGHT_DEV pull /sdcard/right_pixel_demo.mp4 ./sanctuary_pixel_right.mp4
echo "=== Done! Live recordings pulled successfully ==="
```

---

## 🏛️ Historical Hackathon Archive (v0.1.0)

<details>
<summary>Click to view historical Serverpod Hackathon v0.1.0 recordings and hardware archive</summary>

### v0.1.0 Demonstrations:
- **Pixel Right (Initiating)**: Composed reflection on T-Mobile LTE (`192.168.4.45`), toggled Monastic Dark. [Download `sanctuary_pixel_right_scloud.mp4`](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_right_scloud.mp4).
- **Pixel Left (Receiving)**: Received cloud reflection on T-Mobile LTE (`192.168.4.46`), replied with Psalm 139:14. [Download `sanctuary_pixel_left_scloud.mp4`](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_left_scloud.mp4).

</details>
