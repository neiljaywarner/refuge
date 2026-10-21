#!/bin/bash
set -e

# Auto-detect connected devices or accept environment overrides:
# Usage: [LEFT_DEV=<id>] [RIGHT_DEV=<id>] ./scripts/run_staggered_dual_pixel_demo.sh
DEVICES=($(adb devices 2>/dev/null | awk '$2=="device" {print $1}'))
LEFT_DEV="${LEFT_DEV:-${DEVICES[0]}}"
RIGHT_DEV="${RIGHT_DEV:-${DEVICES[1]}}"

if [ -z "$LEFT_DEV" ] || [ -z "$RIGHT_DEV" ]; then
  echo "Error: Two connected Android devices are required. Detected: ${#DEVICES[@]}"
  echo "Specify explicitly via: LEFT_DEV=<dev1> RIGHT_DEV=<dev2> $0"
  exit 1
fi

echo "=== Preparing Devices ==="
# Force close any existing screenrecords on devices
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
# Tap composer text box on Right device
adb -s $RIGHT_DEV shell input tap 500 800
sleep 1.0
adb -s $RIGHT_DEV shell "input text 'From%spixel%son%sthe%sright%son%sLTE%ssaying%shi%svia%sServerpod%sCloud!'"
sleep 1.0
# CLOSE KEYBOARD so full screen and feed are clearly visible!
adb -s $RIGHT_DEV shell input keyevent 111
sleep 1.2
# Tap Publish Reflection (x ~ 740, y ~ 1030)
adb -s $RIGHT_DEV shell input tap 740 1030
sleep 3.5

echo "=== Action 2: Pixel Left reacts to Right's new post ==="
# On Left device, react to the incoming reflection
adb -s $LEFT_DEV shell input tap 180 1560
sleep 2.0

echo "=== Action 3: Pixel Left replies via Serverpod Cloud ==="
# Tap composer text box on Left device
adb -s $LEFT_DEV shell input tap 500 800
sleep 1.0
adb -s $LEFT_DEV shell "input text 'From%spixel%son%sthe%sleft:%sreceived%syour%scloud%sreflection!%sFearfully%sand%swonderfully%smade.'"
sleep 1.0
# CLOSE KEYBOARD on Left device!
adb -s $LEFT_DEV shell input keyevent 111
sleep 1.2
# Tap Publish Reflection on Left device
adb -s $LEFT_DEV shell input tap 740 1030
sleep 3.5

echo "=== Action 4: Pixel Right reacts to Left's reply ==="
# Right device reacts with Support to the top post
adb -s $RIGHT_DEV shell input tap 380 1560
sleep 2.0

echo "=== Action 5: Sensory Theme demonstration on Right Device ==="
# Tap top-right theme icon menu (x 930, y 160)
adb -s $RIGHT_DEV shell input tap 930 160
sleep 1.2
# Select Dark theme in popup menu
adb -s $RIGHT_DEV shell input tap 850 340
sleep 2.0

echo "=== Action 6: About Dialog demonstration on Left Device ==="
# Tap About info icon on Left device (x 1010, y 160)
adb -s $LEFT_DEV shell input tap 1010 160
sleep 3.0
# Dismiss dialog by tapping outside
adb -s $LEFT_DEV shell input tap 540 1900
sleep 2.0

echo "Waiting for recordings to finalize..."
wait $LEFT_PID 2>/dev/null || true
wait $RIGHT_PID 2>/dev/null || true
sleep 2

echo "=== Pulling recordings from devices ==="
adb -s $LEFT_DEV pull /sdcard/left_pixel_staggered.mp4 ./sanctuary_pixel_left_staggered.mp4
adb -s $RIGHT_DEV pull /sdcard/right_pixel_staggered.mp4 ./sanctuary_pixel_right_staggered.mp4

echo "=== Staggered demo recording complete! ==="
