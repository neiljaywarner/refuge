#!/usr/bin/env bash
# Build the BEMA-branded dev web app and publish it to Firebase Hosting
# site bemademo (https://bemademo.web.app) in project bemademo.
#
# Same Firebase app options and dev flavor as the Belong dev build. This does
# not deploy hosting for belongonthespectrum and does not run `firebase deploy`
# without `--only hosting`.
#
# Set STREAM_TOKEN_ENDPOINT to
# https://<project-ref>.supabase.co/functions/v1/mint-stream-call-token
# before running. Do not commit that URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="firebase.bema.json"
PROJECT="bemademo"
SITE="bemademo"
TOKEN_ENDPOINT="${STREAM_TOKEN_ENDPOINT:-}"

for arg in "$@"; do
  case "$arg" in
    --live|--prod|live|prod)
      echo "Refusing to deploy Belong live or production hosting." >&2
      exit 64
      ;;
    --help|-h)
      echo "Usage: STREAM_TOKEN_ENDPOINT=https://<project-ref>.supabase.co/functions/v1/mint-stream-call-token scripts/bema_demo_deploy.sh"
      echo "Builds lib/main_bema.dart with BRAND=bema and deploys hosting site ${SITE}."
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 64
      ;;
  esac
done

if ! grep -Eq '"site"[[:space:]]*:[[:space:]]*"'"$SITE"'"' "$CONFIG"; then
  echo "Refusing: ${CONFIG} is not the ${SITE} hosting site." >&2
  exit 64
fi
if grep -Eq 'belongonthespectrum' "$CONFIG"; then
  echo "Refusing: ${CONFIG} names the Belong hosting site." >&2
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
    exit 64
    ;;
  https://*)
    ;;
  *)
    echo "Refusing: STREAM_TOKEN_ENDPOINT must be an https URL." >&2
    exit 64
    ;;
esac

echo "Building the BEMA-branded dev web app..."
export STREAM_VIDEO_PREVIEW=true
export STREAM_TOKEN_ENDPOINT="$TOKEN_ENDPOINT"
flutter build web -t lib/main_bema.dart \
  --dart-define=BRAND=bema \
  --dart-define=FLAVOR=dev \
  --dart-define=STREAM_VIDEO_PREVIEW=true \
  --dart-define=STREAM_TOKEN_ENDPOINT="$TOKEN_ENDPOINT" \
  --dart-define=BACKEND=appwrite

python3 scripts/bema_brand_web_shell.py build/web

echo "Deploying hosting site ${SITE} in project ${PROJECT}..."
firebase deploy --only hosting --project "$PROJECT" --config "$CONFIG"

echo "Hosting site: https://${SITE}.web.app"
echo "Firebase project: ${PROJECT} (config ${CONFIG})"
echo "Token endpoint: set (not printed)"
