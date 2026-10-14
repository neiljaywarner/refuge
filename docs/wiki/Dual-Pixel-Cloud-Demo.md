# 📱 Dual Pixel Cloud Demo — Hardware Verification

> Real-time multi-device verification executed across physical Google Pixel 9a hardware operating on T-Mobile LTE communicating over Serverpod Cloud.

---

## 🔬 Hardware & Network Specifications

Rather than relying on emulators or localhost network loopbacks, Sanctuary was tested and recorded on physical smartphones:

| Specification | Pixel Left (Device 1) | Pixel Right (Device 2) |
| :--- | :--- | :--- |
| **Model** | Google Pixel 9a | Google Pixel 9a |
| **Serial Number** | `56091JEBF14039` | `58221JEBF20835` |
| **Operating System** | Android 15 | Android 15 |
| **Local Wi-Fi IP** | `192.168.4.46` | `192.168.4.45` |
| **Cellular Network** | T-Mobile LTE (`rmnet16`) | T-Mobile LTE (`rmnet17`) |
| **Backend Connected** | Serverpod Cloud (`refuge4serverpod.api.serverpod.space`) | Serverpod Cloud (`refuge4serverpod.api.serverpod.space`) |

---

## 🎬 Live Demonstration Recordings

The dual-device test was captured concurrently using Android's native `screenrecord` utility and uploaded to the official v0.1.0 release:

### 1. Pixel Right (Initiating Reflection)
* **Action**: Composed and published reflection:
  > *"From pixel on the right on T-Mobile LTE (192.168.4.45) saying hi to pixel on the left via Serverpod Cloud!"*
* **Interactions**: Toggled theme to **Monastic Dark**, tapped qualitative care affirmation.
* **Recording**: [Download `sanctuary_pixel_right_scloud.mp4`](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_right_scloud.mp4)

### 2. Pixel Left (Receiving & Affirming)
* **Action**: Received cloud reflection and published community reply:
  > *"From pixel on the left on T-Mobile LTE (192.168.4.46) received your cloud reflection! Fearfully and wonderfully made (Psalm 139:14)"*
* **Interactions**: Toggled theme to **High Contrast**, tapped care affirmation, opened **About Sanctuary** dialog with BuilderBase and Serverpod credits.
* **Recording**: [Download `sanctuary_pixel_left_scloud.mp4`](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary_pixel_left_scloud.mp4)

---

## 🤖 Automated Test Driver Script

The test execution was driven via an automated bash script utilizing ADB:

```bash
#!/bin/bash
LEFT_DEV="56091JEBF14039"
RIGHT_DEV="58221JEBF20835"

# 1. Start concurrent screen recordings
adb -s $LEFT_DEV shell screenrecord --time-limit 35 /sdcard/left_pixel_scloud.mp4 &
adb -s $RIGHT_DEV shell screenrecord --time-limit 35 /sdcard/right_pixel_scloud.mp4 &

# 2. Pixel Right posts to Serverpod Cloud
adb -s $RIGHT_DEV shell input tap 500 1060
adb -s $RIGHT_DEV shell "input text 'From%spixel%son%sthe%sright%son%sT-Mobile%sLTE%s\(192.168.4.45\)%ssaying%shi%sto%spixel%son%sthe%sleft%svia%sServerpod%sCloud!'"
adb -s $RIGHT_DEV shell input tap 740 1255

# 3. Pixel Left replies via Serverpod Cloud
adb -s $LEFT_DEV shell input tap 500 1060
adb -s $LEFT_DEV shell "input text 'From%spixel%son%sthe%sleft%son%sT-Mobile%sLTE%s\(192.168.4.46\)%sreceived%syour%scloud%sreflection!%sFearfully%sand%swonderfully%smade%s\(Psalm%s139:14\)'"
adb -s $LEFT_DEV shell input tap 740 1255

# 4. Pull recordings
adb -s $LEFT_DEV pull /sdcard/left_pixel_scloud.mp4 ./sanctuary_pixel_left_scloud.mp4
adb -s $RIGHT_DEV pull /sdcard/right_pixel_scloud.mp4 ./sanctuary_pixel_right_scloud.mp4
```

This ensures reproducible, verifiable hardware validation for hackathon evaluators.
