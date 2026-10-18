#!/usr/bin/env bash
set -euo pipefail

echo "======================================================================"
echo " Winding Down Old Mac & Packaging Everything for New Apple Silicon Mac"
echo "======================================================================"

HOME_DIR="/Users/neil"
REPO_DIR="$HOME_DIR/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon"
INVENTORY_DIR="$HOME_DIR/.old_mac_inventory"
mkdir -p "$INVENTORY_DIR"

# 1. Check & push any remaining git changes in refuge4serverpod
if [ -d "$REPO_DIR/.git" ]; then
  echo "--> Checking git status in $REPO_DIR..."
  cd "$REPO_DIR"
  if [ -n "$(git status --porcelain)" ]; then
    echo "    Found uncommitted changes; staging and committing..."
    git add -A
    git commit -m "chore: wind-down snapshot before migrating to new Apple Silicon Mac" || true
  fi
  git branch -f chore/silicon-mac-migration-snapshot HEAD || true
  echo "--> Pushing main and snapshot branch to origin..."
  git push origin HEAD:main chore/silicon-mac-migration-snapshot || echo "    (Push skipped or already up to date)"
fi

# 2. Capture lightweight machine inventory (Homebrew, extensions, Dart globals, git repos)
echo "--> Saving installed tool & extension inventory to $INVENTORY_DIR..."
brew leaves > "$INVENTORY_DIR/brew_formulae.txt" 2>/dev/null || true
brew list --cask > "$INVENTORY_DIR/brew_casks.txt" 2>/dev/null || true
ls -1 "$HOME_DIR/.antigravity/extensions" > "$INVENTORY_DIR/antigravity_extensions.txt" 2>/dev/null || true
ls -1 "$HOME_DIR/.antigravity-ide/extensions" > "$INVENTORY_DIR/antigravity_ide_extensions.txt" 2>/dev/null || true
"$HOME_DIR/flutter/bin/dart" pub global list > "$INVENTORY_DIR/dart_pub_globals.txt" 2>/dev/null || true

# List all git remotes across AndroidStudioProjects & code so you never wonder where a repo came from
{
  for d in "$HOME_DIR"/AndroidStudioProjects/* "$HOME_DIR"/code/*; do
    if [ -d "$d/.git" ]; then
      echo "=== $d ==="
      git -C "$d" remote -v 2>/dev/null || true
      git -C "$d" status -s 2>/dev/null || true
    fi
  done
} > "$INVENTORY_DIR/all_local_git_repos_summary.txt"

# 3. Build the email-attachable zip (~140 KB)
cd "$HOME_DIR"
ZIP_OUT="$HOME_DIR/silicon_mac_home_and_configs.zip"
rm -f "$ZIP_OUT"

echo "--> Building email-friendly config & allowlist archive: $ZIP_OUT"
zip -r "$ZIP_OUT" \
  bootstrap_new_silicon_mac.sh \
  wind_down_old_mac.bash \
  silicon_mac_setup_email.txt \
  .old_mac_inventory \
  .antigravity/permissions.json \
  .antigravity/argv.json \
  .antigravity-ide/argv.json \
  .zshrc \
  .zprofile \
  .zshenv \
  .gitconfig \
  .bash_profile \
  .serverpod \
  .config/gh \
  .config/flutter \
  .android/debug.keystore \
  AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/sanctuary_server/sanctuary_server_server/config/passwords.yaml \
  AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/sanctuary_server/.scloud \
  AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/.firebase \
  2>/dev/null || true

# 4. Build the untracked media & scratch zip (~47 MB)
MEDIA_ZIP_OUT="$HOME_DIR/refuge4serverpod_untracked_media_and_scratch.zip"
if [ -d "$REPO_DIR" ]; then
  echo "--> Building untracked media & scratch archive: $MEDIA_ZIP_OUT"
  cd "$REPO_DIR"
  rm -f "$MEDIA_ZIP_OUT"
  zip -r "$MEDIA_ZIP_OUT" \
    scratch \
    *.mp4 \
    *.m4a \
    docs/submission_packet/*.m4a \
    2>/dev/null || true
fi

echo "======================================================================"
echo " Old Mac Wind-Down Complete!"
echo " Files ready in $HOME_DIR:"
ls -lh "$ZIP_OUT" "$HOME_DIR/silicon_mac_setup_email.txt" "$MEDIA_ZIP_OUT"
echo "======================================================================"
