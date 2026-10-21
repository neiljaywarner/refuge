#!/bin/bash
set -e

# Auto-detect connected devices or accept environment overrides:
# Usage: [LEFT_DEV=<id>] [RIGHT_DEV=<id>] ./scripts/run_dual_pixel_demo.sh
DEVICES=($(adb devices 2>/dev/null | awk '$2=="device" {print $1}'))
LEFT_DEV="${LEFT_DEV:-${DEVICES[0]}}"
RIGHT_DEV="${RIGHT_DEV:-${DEVICES[1]}}"

if [ -z "$LEFT_DEV" ] || [ -z "$RIGHT_DEV" ]; then
  echo "Error: Two connected Android devices are required. Detected: ${#DEVICES[@]}"
  echo "Specify explicitly via: LEFT_DEV=<dev1> RIGHT_DEV=<dev2> $0"
  exit 1
fi

echo "=== Starting dual Pixel screen recordings ==="
adb -s $LEFT_DEV shell "rm -f /sdcard/left_pixel_scloud.mp4"
adb -s $RIGHT_DEV shell "rm -f /sdcard/right_pixel_scloud.mp4"

adb -s $LEFT_DEV shell screenrecord --time-limit 35 /sdcard/left_pixel_scloud.mp4 &
LEFT_PID=$!

adb -s $RIGHT_DEV shell screenrecord --time-limit 35 /sdcard/right_pixel_scloud.mp4 &
RIGHT_PID=$!

echo "Recordings started (PIDs: $LEFT_PID, $RIGHT_PID). Waiting 2s..."
sleep 2

echo "=== Step 1: Pixel Right posting via Serverpod Cloud ==="
# Tap text box
adb -s $RIGHT_DEV shell input tap 500 1060
sleep 0.8
# Type message
adb -s $RIGHT_DEV shell "input text 'From%spixel%son%sthe%sright%son%sT-Mobile%sLTE%s\(192.168.4.45\)%ssaying%shi%sto%spixel%son%sthe%sleft%svia%sServerpod%sCloud!'"
sleep 0.8
# Tap Publish Reflection
adb -s $RIGHT_DEV shell input tap 740 1255
sleep 1.5
# Toggle Dark theme
adb -s $RIGHT_DEV shell input tap 630 95
sleep 1.0

echo "=== Step 2: Pixel Left replying via Serverpod Cloud ==="
# Tap text box
adb -s $LEFT_DEV shell input tap 500 1060
sleep 0.8
# Type reply
adb -s $LEFT_DEV shell "input text 'From%spixel%son%sthe%sleft%son%sT-Mobile%sLTE%s\(192.168.4.46\)%sreceived%syour%scloud%sreflection!%sFearfully%sand%swonderfully%smade%s\(Psalm%s139:14\)'"
sleep 0.8
# Tap Publish Reflection
adb -s $LEFT_DEV shell input tap 740 1255
sleep 1.5
# Toggle Contrast theme
adb -s $LEFT_DEV shell input tap 800 95
sleep 1.0
# Tap About info button
adb -s $LEFT_DEV shell input tap 940 95
sleep 3.0
# Tap outside dialog to dismiss
adb -s $LEFT_DEV shell input tap 540 1800
sleep 1.0

echo "Waiting for recordings to finalize..."
wait $LEFT_PID 2>/dev/null || true
wait $RIGHT_PID 2>/dev/null || true
sleep 2

echo "=== Pulling recordings ==="
adb -s $LEFT_DEV pull /sdcard/left_pixel_scloud.mp4 ./sanctuary_pixel_left_scloud.mp4
adb -s $RIGHT_DEV pull /sdcard/right_pixel_scloud.mp4 ./sanctuary_pixel_right_scloud.mp4

echo "=== Done! Dual Pixel demo videos recorded successfully ==="
