#!/usr/bin/env bash
# Deploy the BEMA weekly demo to a Firebase Hosting preview channel of the
# DEV site only. It does not publish the live dev site or production.
#
# The call token is the Supabase edge function mint-stream-call-token on
# project belong-preview-mint. Set STREAM_TOKEN_ENDPOINT to
# https://<project-ref>.supabase.co/functions/v1/mint-stream-call-token
# before running. Do not commit that URL.
#
# Firebase project belongonthespectrum has no functions deployed, so
# cloudfunctions.net/mintStreamCallToken returns 404. This script refuses
# that URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="firebase.dev.json"
PROJECT="belongonthespectrum"
CHANNEL="bema-demo"
DEV_SITE="dev-belongonthespectrum"
PROD_SITE="belongonthespectrum"
LIVE_DEV_URL="https://dev-belongonthespectrum.web.app"
PROD_URL="https://belongonthespectrum.web.app"
TOKEN_ENDPOINT="${STREAM_TOKEN_ENDPOINT:-}"

for arg in "$@"; do
  case "$arg" in
    --live|--prod|live|prod)
      echo "Refusing to deploy the live channel or production." >&2
      exit 64
      ;;
    --help|-h)
      echo "Usage: scripts/bema_demo_preview_deploy.sh"
      echo "Runs the CI test list, builds the flagged dev web app, and deploys"
      echo "Firebase Hosting channel ${CHANNEL} on site ${DEV_SITE} for 14 days."
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "This script does not accept a site, project, or live channel." >&2
      exit 64
      ;;
  esac
done

if ! grep -Eq '"site"[[:space:]]*:[[:space:]]*"'"$DEV_SITE"'"' "$CONFIG"; then
  echo "Refusing: ${CONFIG} is not the ${DEV_SITE} hosting site." >&2
  exit 64
fi
if grep -Eq '"site"[[:space:]]*:[[:space:]]*"'"$PROD_SITE"'"' "$CONFIG"; then
  echo "Refusing: ${CONFIG} names the production hosting site." >&2
  exit 64
fi

if [[ -z "$TOKEN_ENDPOINT" ]]; then
  echo "Set STREAM_TOKEN_ENDPOINT to the belong-preview-mint function" >&2
  echo "https://<project-ref>.supabase.co/functions/v1/mint-stream-call-token" >&2
  exit 64
fi
case "$TOKEN_ENDPOINT" in
  *cloudfunctions.net/mintStreamCallToken*)
    echo "Refusing: that Firebase function is not deployed (HTTP 404)." >&2
    echo "Use the Supabase mint-stream-call-token URL instead." >&2
    exit 64
    ;;
  https://*)
    ;;
  *)
    echo "Refusing: STREAM_TOKEN_ENDPOINT must be an https URL." >&2
    exit 64
    ;;
esac

echo "Running the CI test list (tool/ci_widget_test_manifest.txt)..."
CI_TEST_FILES=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  CI_TEST_FILES+=("$line")
done < tool/ci_widget_test_manifest.txt
if [[ ${#CI_TEST_FILES[@]} -eq 0 ]]; then
  echo "Refusing: the CI test list is empty." >&2
  exit 65
fi
flutter test "${CI_TEST_FILES[@]}"

echo "Building the flagged dev web app..."
export STREAM_VIDEO_PREVIEW=true
export STREAM_TOKEN_ENDPOINT="$TOKEN_ENDPOINT"
flutter build web -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=STREAM_VIDEO_PREVIEW=true \
  --dart-define=STREAM_TOKEN_ENDPOINT="$TOKEN_ENDPOINT"

echo "Deploying preview channel ${CHANNEL} on ${DEV_SITE} (14 days)..."
echo "This does not run 'firebase deploy' and does not update ${LIVE_DEV_URL}."
DEPLOY_JSON="$(firebase hosting:channel:deploy "$CHANNEL" \
  --config "$CONFIG" \
  --project "$PROJECT" \
  --expires 14d \
  --json)"

PREVIEW_URL="$(printf '%s\n' "$DEPLOY_JSON" | grep -o 'https://dev-belongonthespectrum--bema-demo[^"[:space:]]*' | head -n 1 || true)"

if [[ -z "$PREVIEW_URL" ]]; then
  echo "Refusing: channel deploy did not return a dev preview URL." >&2
  exit 66
fi
if [[ "$PREVIEW_URL" == "$LIVE_DEV_URL" || "$PREVIEW_URL" == "$PROD_URL" || "$PREVIEW_URL" == "https://${PROD_SITE}.firebaseapp.com" ]]; then
  echo "Refusing: deploy returned the live site ${PREVIEW_URL}." >&2
  exit 66
fi

echo "Preview URL: ${PREVIEW_URL}"
echo "Token endpoint: set (not printed)"
echo "Firebase project: ${PROJECT}"
echo "Hosting site: ${DEV_SITE} (config ${CONFIG})"
