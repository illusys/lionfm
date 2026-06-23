#!/bin/bash
set -e

# ─── Flutter SDK ──────────────────────────────────────────────────────────────
# Pinned to match the local dev environment exactly.
# Color.withValues(), CardThemeData, DialogThemeData, Switch.activeThumbColor
# and other APIs used in this codebase require Flutter >= 3.27.
# The version check below busts any stale cached SDK automatically.

FLUTTER_VERSION="3.38.7"
FLUTTER_DIR="$(pwd)/flutter"

git config --global --add safe.directory '*'

# If a flutter directory already exists but is the wrong version, remove it.
if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  INSTALLED=$("$FLUTTER_DIR/bin/flutter" --version 2>/dev/null \
    | grep -oP 'Flutter \K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ "$INSTALLED" != "$FLUTTER_VERSION" ]; then
    echo "▸ Cached Flutter $INSTALLED != required $FLUTTER_VERSION — re-downloading..."
    rm -rf "$FLUTTER_DIR"
  fi
fi

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "▸ Downloading Flutter $FLUTTER_VERSION..."
  curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar xJ
  echo "▸ Flutter $FLUTTER_VERSION ready."
fi

# PATH is set after download so it always points to a real binary.
export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR"

# Suppress the "running as root" warning and analytics prompts in CI.
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter config --no-analytics --no-cli-animations

# ─── Build ────────────────────────────────────────────────────────────────────
flutter pub get

echo "▸ Building Flutter Web (release)..."
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=GOOGLE_WEB_CLIENT_ID="748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com"
