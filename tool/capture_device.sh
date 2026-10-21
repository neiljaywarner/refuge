#!/bin/bash
set -e

if [ -n "$ADB_DEVICE" ]; then
  DEVICE="$ADB_DEVICE"
else
  PHYSICAL_DEV="$(adb devices 2>/dev/null | grep -v "List" | grep "device$" | grep -v "emulator-" | head -n 1 | awk '{print $1}')"
  EMULATOR_DEV="$(adb devices 2>/dev/null | grep -v "List" | grep "device$" | grep "emulator-" | head -n 1 | awk '{print $1}')"

  if [ -n "$PHYSICAL_DEV" ]; then
    DEVICE="$PHYSICAL_DEV"
  elif [ -n "$EMULATOR_DEV" ]; then
    DEVICE="$EMULATOR_DEV"
  else
    DEVICE="$(adb devices 2>/dev/null | grep -v "List" | grep "device$" | head -n 1 | awk '{print $1}')"
  fi
fi
ACTION="${1:-screenshot}"
TARGET="${2:-/tmp/screenshot.png}"

case "$ACTION" in
  screenshot)
    adb -s "$DEVICE" exec-out screencap -p > "$TARGET"
    if command -v sips >/dev/null 2>&1; then
      DIM=$(sips -g pixelHeight -g pixelWidth "$TARGET" 2>/dev/null | awk '/pixelHeight/ {h=$2} /pixelWidth/ {w=$2} END {print w"x"h}')
      if [ "$DIM" = "1080x2424" ]; then
        sips -c 2160 1080 "$TARGET" --out "$TARGET" >/dev/null 2>&1 || true
      fi
    fi
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
  shell)
    shift
    adb -s "$DEVICE" shell "$@"
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
    echo "Usage: $0 [screenshot <path>|tap <x> <y>|key <keycode>|text <string>|shell <cmd>|record <duration> <path>]"
    exit 1
    ;;
esac
