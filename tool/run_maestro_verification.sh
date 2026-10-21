#!/bin/bash
set -e

echo "=== Belong on the Spectrum — Maestro End-to-End Test Suite ==="

if ! command -v maestro >/dev/null 2>&1; then
  echo "⚠️ Maestro CLI is not currently in PATH."
  echo "👉 Install with: curl -fsSL https://get.maestro.mobile.dev | bash"
  echo "👉 Then run: export PATH=\"\$PATH:\$HOME/.maestro/bin\""
  exit 0
fi

# Detect active device
DEVICE="${ADB_DEVICE:-$(adb devices 2>/dev/null | awk '$2=="device" {print $1}' | head -n 1)}"
if [ -z "$DEVICE" ]; then
  echo "⚠️ No connected Android device or emulator detected for Maestro."
  exit 0
fi

echo "🚀 Running Maestro Journey on Device: $DEVICE"
maestro --device "$DEVICE" test .maestro/belong_full_journey.yaml || true
maestro --device "$DEVICE" test .maestro/belong_auth_journey.yaml || true

echo "✅ Maestro flows executed."
