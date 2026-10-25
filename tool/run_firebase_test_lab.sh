#!/usr/bin/env bash
# Belong on the Spectrum — Firebase Test Lab runner (dev APK only).
#
# Usage:
#   ./tool/run_firebase_test_lab.sh --dry-run
#   ./tool/run_firebase_test_lab.sh --build-only
set -euo pipefail

PROJECT_ID="${FIREBASE_PROJECT_ID:-belongonthespectrum}"
DEVICE="model=panther,version=33,locale=en,orientation=portrait"
TARGET="${FTL_TARGET:-integration_test/patrol_hello_world_test.dart}"

echo "Running Firebase Test Lab runner (dev package only)..."
dart run tool/run_firebase_test_lab.dart \
  --project "$PROJECT_ID" \
  --target "$TARGET" \
  --device "$DEVICE" \
  "$@"
