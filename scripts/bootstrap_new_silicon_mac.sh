#!/usr/bin/env bash
set -euo pipefail

echo "======================================================================"
echo " Bootstrapping Brand-New Apple Silicon Mac for refuge4serverpod"
echo "======================================================================"

# 1. Rosetta 2 (Required by some Flutter/Android sub-binaries on Apple Silicon)
if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
  echo "--> Installing Rosetta 2..."
  sudo softwareupdate --install-rosetta --agree-to-license || true
fi

# 2. Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo "--> Triggering Xcode Command Line Tools installer..."
  xcode-select --install || true
  echo "    Wait for the Xcode Command Line Tools popup to finish, then re-run this script."
  exit 0
fi

# 3. Install Apple Silicon Homebrew (/opt/homebrew)
if [ ! -x /opt/homebrew/bin/brew ]; then
  echo "--> Installing Homebrew for Apple Silicon (/opt/homebrew)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# 4. Install Core Formulae & Casks (Native ARM64)
echo "--> Installing CLI tools via Homebrew..."
brew install git gh jq ffmpeg cocoapods ruby node openjdk@17

echo "--> Installing GUI Apps (Flutter, Android Studio, Docker, Chrome)..."
brew install --cask google-chrome android-studio docker flutter

# 5. Restore Home Configs & Antigravity Allowlist if zip is in ~/Downloads
ZIP_PATH="${1:-$HOME/Downloads/silicon_mac_home_and_configs.zip}"
if [ -f "$ZIP_PATH" ]; then
  echo "--> Extracting $ZIP_PATH into $HOME..."
  unzip -o "$ZIP_PATH" -d "$HOME"
fi

# 6. Fix Intel paths -> Apple Silicon paths in shell dotfiles
echo "--> Configuring ~/.zprofile, ~/.zshenv, and ~/.zshrc for Apple Silicon..."
touch "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.zshrc"
sed -i '' 's|/usr/local/bin/brew|/opt/homebrew/bin/brew|g' "$HOME/.zprofile" || true
sed -i '' 's|/usr/local/opt/ruby/bin|/opt/homebrew/opt/ruby/bin|g' "$HOME/.zshrc" || true
sed -i '' 's|export PATH=\$HOME/flutter/bin:\$PATH|# Using Homebrew ARM64 Flutter|g' "$HOME/.zshenv" || true

if ! grep -q "/opt/homebrew/bin/brew shellenv" "$HOME/.zprofile"; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
fi

# 7. Link Java 17 for Android / Gradle / Maestro
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk || true

# 8. Install Global CLIs (Serverpod, Scloud, Firebase, Maestro)
echo "--> Activating Serverpod, Scloud, Firebase, and Maestro CLIs..."
export PATH="$HOME/.pub-cache/bin:/opt/homebrew/bin:$PATH"
dart pub global activate serverpod_cli
dart pub global activate serverpod_cloud_cli
npm install -g firebase-tools
curl -Ls "https://get.maestro.mobile.dev" | bash || true

# 9. Clone refuge4serverpod & Restore Untracked Secrets
mkdir -p "$HOME/AndroidStudioProjects"
REPO_DIR="$HOME/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon"
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "--> Cloning neiljaywarner/refuge4serverpod..."
  git clone https://github.com/neiljaywarner/refuge4serverpod.git "$REPO_DIR"
fi

if [ -f "$ZIP_PATH" ]; then
  echo "--> Restoring untracked project configs (passwords.yaml, .scloud, .firebase)..."
  unzip -o "$ZIP_PATH" -d "$HOME"
fi

cd "$REPO_DIR"
flutter pub get
flutter test

echo "======================================================================"
echo " Bootstrap Complete!"
echo " Next manual steps:"
echo "  1. Open Android Studio -> SDK Manager -> Install Android SDK + Command-line Tools"
echo "  2. Run: flutter doctor --android-licenses"
echo "  3. Open Docker Desktop once to finish background daemon setup"
echo "======================================================================"
