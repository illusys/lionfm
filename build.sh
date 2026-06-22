#!/bin/bash
set -e

# ─── Flutter SDK ──────────────────────────────────────────────────────────────
# Download Flutter if not already present (Vercel caches ./flutter between runs).
# We check for the binary directly so a partial/corrupt prior download is retried.

FLUTTER_VERSION="3.22.2"
FLUTTER_DIR="$(pwd)/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "▸ Downloading Flutter $FLUTTER_VERSION..."
  curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar xJ
  echo "▸ Flutter $FLUTTER_VERSION ready."
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics --no-cli-animations
flutter precache --web

# ─── Build ────────────────────────────────────────────────────────────────────
echo "▸ Fetching packages..."
flutter pub get

echo "▸ Building Flutter Web (release)..."
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=GOOGLE_WEB_CLIENT_ID="748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com"
