#!/usr/bin/env bash
# =============================================================================
# Belong on the Spectrum — Firebase Test Lab & Patrol Companion Script
# =============================================================================
# Usage:
#   ./tool/run_firebase_test_lab.sh --dry-run
#   ./tool/run_firebase_test_lab.sh
# =============================================================================
set -euo pipefail

PROJECT_ID="${FIREBASE_PROJECT_ID:-belongonthespectrum}"
TARGET="${1:-integration_test/patrol_hello_world_test.dart}"
DEVICE="model=panther,version=33,locale=en,orientation=portrait"

echo "🧪 Running Firebase Test Lab runner via Dart CLI..."
dart run tool/run_firebase_test_lab.dart \
  --project "$PROJECT_ID" \
  --target "$TARGET" \
  --device "$DEVICE" \
  "$@"
