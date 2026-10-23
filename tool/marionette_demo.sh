#!/usr/bin/env bash
set -eo pipefail

# 🎭 Marionette Live Demo & Feature Showcase Runner
# Drives Belong on the Spectrum across connected Pixels, Emulators, or Chrome.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# If --help requested, pass directly to Dart CLI
for arg in "$@"; do
  if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
    dart run "$SCRIPT_DIR/marionette_demo.dart" --help
    exit 0
  fi
done

echo "🔍 Discovering devices..."
CONNECTED_PIXELS=$(adb devices | grep -E "56091JEBF14039|58221JEBF20835|emulator-5554" | awk '{print $1}' || true)

if [ -n "$CONNECTED_PIXELS" ]; then
  FIRST_DEVICE=$(echo "$CONNECTED_PIXELS" | head -n 1)
  echo "📱 Discovered hardware / emulator: $FIRST_DEVICE"
  echo "🔐 Ensuring notification permissions..."
  adb -s "$FIRST_DEVICE" shell pm grant com.belongonthespectrum.sanctuary android.permission.POST_NOTIFICATIONS 2>/dev/null || true
else
  echo "🌐 No physical Pixel or emulator found. Falling back to Chrome or auto-discovery."
fi

# Forward default Dart VM service port if running on Android
if [ -n "$FIRST_DEVICE" ]; then
  adb -s "$FIRST_DEVICE" forward tcp:56283 tcp:56283 2>/dev/null || true
fi

echo "🚀 Launching Marionette Live Feature Showcase..."
cd "$PROJECT_ROOT"
dart run "$SCRIPT_DIR/marionette_demo.dart" "$@"
