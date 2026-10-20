#!/bin/bash
set -e

if [ -n "$ADB_DEVICE" ]; then
  DEVICE="$ADB_DEVICE"
elif adb devices | grep -q "56091JEBF14039"; then
  DEVICE="56091JEBF14039"
elif adb devices | grep -q "emulator-"; then
  DEVICE="$(adb devices | grep 'emulator-' | head -n 1 | awk '{print $1}')"
else
  DEVICE="56091JEBF14039"
fi
ACTION="${1:-screenshot}"
TARGET="${2:-/tmp/screenshot.png}"

case "$ACTION" in
  screenshot)
    adb -s "$DEVICE" exec-out screencap -p > "$TARGET"
    echo "Screenshot saved to $TARGET"
    ;;
  tap)
    X="${2:-500}"
    Y="${3:-500}"
    adb -s "$DEVICE" shell input tap "$X" "$Y"
    echo "Tapped $X $Y"
    ;;
  key)
    KEY="${2:-4}"
    adb -s "$DEVICE" shell input keyevent "$KEY"
    echo "Keyevent $KEY sent"
    ;;
  text)
    TEXT="${2:-}"
    adb -s "$DEVICE" shell input text "$TEXT"
    echo "Input text sent"
    ;;
  record)
    DURATION="${2:-15}"
    DEST="${3:-/tmp/screenrecord.mp4}"
    echo "Recording $DURATION seconds on $DEVICE..."
    adb -s "$DEVICE" shell screenrecord --time-limit "$DURATION" /sdcard/rec.mp4
    adb -s "$DEVICE" pull /sdcard/rec.mp4 "$DEST"
    adb -s "$DEVICE" shell rm -f /sdcard/rec.mp4
    echo "Video saved to $DEST"
    ;;
  *)
    echo "Usage: $0 {screenshot <path>|tap <x> <y>|key <keycode>|text <string>|record <duration> <path>}"
    exit 1
    ;;
esac
