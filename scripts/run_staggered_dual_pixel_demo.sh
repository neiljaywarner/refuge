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
  echo "Error: Two connected Android devices are required. Detected: ${#DEVICES[@]}"
  echo "Specify explicitly via: LEFT_DEV=<dev1> RIGHT_DEV=<dev2> $0"
  exit 1
fi

echo "=== Preparing Devices: Left ($LEFT_DEV) and Right ($RIGHT_DEV) ==="
adb -s $LEFT_DEV shell "pkill -f screenrecord 2>/dev/null || true"
adb -s $RIGHT_DEV shell "pkill -f screenrecord 2>/dev/null || true"
adb -s $LEFT_DEV shell "rm -f /sdcard/left_pixel_staggered.mp4"
adb -s $RIGHT_DEV shell "rm -f /sdcard/right_pixel_staggered.mp4"

# Launch Sanctuary on both devices
adb -s $LEFT_DEV shell am force-stop com.belongonthespectrum.sanctuary
adb -s $RIGHT_DEV shell am force-stop com.belongonthespectrum.sanctuary
sleep 1
adb -s $LEFT_DEV shell monkey -p com.belongonthespectrum.sanctuary -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
adb -s $RIGHT_DEV shell monkey -p com.belongonthespectrum.sanctuary -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 3

echo "=== Starting Dual Screenrecordings (45s) ==="
adb -s $LEFT_DEV shell screenrecord --time-limit 45 --bit-rate 8000000 /sdcard/left_pixel_staggered.mp4 &
LEFT_PID=$!
adb -s $RIGHT_DEV shell screenrecord --time-limit 45 --bit-rate 8000000 /sdcard/right_pixel_staggered.mp4 &
RIGHT_PID=$!

echo "Recordings started (PIDs: $LEFT_PID, $RIGHT_PID). Waiting 2s for initial calm state..."
sleep 2.5

echo "=== Action 1: Pixel Right starts composing post ==="
# Tap composer text box
adb -s $RIGHT_DEV shell input tap 524 1266
sleep 1.0
adb -s $RIGHT_DEV shell "input text 'From%spixel%son%sthe%sright%ssaying%shi%svia%sServerpod%sCloud!'"
sleep 1.0
# Close keyboard
adb -s $RIGHT_DEV shell input keyevent 4
sleep 1.0
# Tap Publish Reflection
adb -s $RIGHT_DEV shell input tap 778 1470
sleep 3.5

echo "=== Action 2: Pixel Left reacts to Right's new post ==="
# On Left device, react to the reflection
adb -s $LEFT_DEV shell input tap 184 2119
sleep 2.0

echo "=== Action 3: Pixel Left replies via Serverpod Cloud ==="
# Tap composer text box on Left device
adb -s $LEFT_DEV shell input tap 524 1266
sleep 1.0
adb -s $LEFT_DEV shell "input text 'From%spixel%son%sthe%sleft:%sreceived%syour%scloud%sreflection!%sFearfully%sand%swonderfully%smade.'"
sleep 1.0
# Close keyboard on Left device
adb -s $LEFT_DEV shell input keyevent 4
sleep 1.0
# Tap Publish Reflection on Left device
adb -s $LEFT_DEV shell input tap 778 1470
sleep 3.5

echo "=== Action 4: Sensory Theme demonstration on Right Device ==="
# Tap top-right theme icon menu
adb -s $RIGHT_DEV shell input tap 584 226
sleep 1.2
# Select Dark theme in popup menu
adb -s $RIGHT_DEV shell input tap 450 530
sleep 2.0

echo "=== Action 5: About Dialog demonstration on Left Device ==="
# Tap About info icon on Left device
adb -s $LEFT_DEV shell input tap 699 225
sleep 3.0
# Dismiss dialog by tapping Close button
adb -s $LEFT_DEV shell input tap 828 1999
sleep 2.0

echo "Waiting for recordings to finalize..."
wait $LEFT_PID 2>/dev/null || true
wait $RIGHT_PID 2>/dev/null || true
sleep 2

echo "=== Pulling recordings from devices ==="
adb -s $LEFT_DEV pull /sdcard/left_pixel_staggered.mp4 ./sanctuary_pixel_left_staggered.mp4
adb -s $RIGHT_DEV pull /sdcard/right_pixel_staggered.mp4 ./sanctuary_pixel_right_staggered.mp4

echo "=== Staggered demo recording complete! ==="
