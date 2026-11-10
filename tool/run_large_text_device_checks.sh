#!/usr/bin/env bash
# Set Android font scale to 2.0 and a slightly larger display density, run the
# large-text Patrol test and Maestro flow, then restore both settings.
#
# Needs one adb device (emulator or phone). Does not deploy or change
# production config. Exits 2 when adb has no device, so a desktop-only run
# can record that the device checks did not execute.
set -u

if ! command -v adb >/dev/null 2>&1; then
  echo "adb is not installed. Large-text device checks did not run."
  exit 2
fi

if ! adb get-state >/dev/null 2>&1; then
  echo "No adb device is connected. Large-text device checks did not run."
  exit 2
fi

previous_font="$(adb shell settings get system font_scale | tr -d '\r')"
density_text="$(adb shell wm density | tr -d '\r')"
previous_override="$(printf '%s\n' "$density_text" | sed -n 's/.*Override density:[[:space:]]*//p' | head -n 1)"
physical_density="$(printf '%s\n' "$density_text" | sed -n 's/.*Physical density:[[:space:]]*//p' | head -n 1)"

restore() {
  adb shell settings put system font_scale "${previous_font:-1.0}" >/dev/null
  if [ -n "$previous_override" ]; then
    adb shell wm density "$previous_override" >/dev/null
  else
    adb shell wm density reset >/dev/null
  fi
}
trap restore EXIT

adb shell settings put system font_scale 2.0
if [ -n "$physical_density" ]; then
  next_density="$(awk -v d="$physical_density" 'BEGIN { printf "%d", d * 1.15 }')"
  adb shell wm density "$next_density"
fi

status=0
if command -v patrol >/dev/null 2>&1; then
  patrol test --target integration_test/large_text_patrol_test.dart || status=$?
else
  echo "patrol CLI is not on PATH. Skipping the Patrol target."
fi

if command -v maestro >/dev/null 2>&1; then
  maestro test .maestro/large_text_sign_in_flow.yaml || status=$?
else
  echo "maestro is not on PATH. Skipping the Maestro flow."
fi

exit "$status"
