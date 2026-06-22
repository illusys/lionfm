#!/bin/bash
set -e

# 1. Define Flutter Target Context
FLUTTER_VERSION="3.22.2"
export PATH="$PATH:$(pwd)/flutter/bin"

# 2. Prevent Git permissions errors inside Vercel's root directory environment
git config --global --add safe.directory '*'

# 3. Download Flutter SDK if cache footprint is missing
if [ ! -d "flutter" ]; then
  echo "--- Downloading Flutter SDK v$FLUTTER_VERSION ---"
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
  tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
  rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
fi

# 4. Explicitly tag the newly unpacked path directory as safe
git config --global --add safe.directory $(pwd)/flutter

# 5. Disable background telemetry analytics calls to save processing overhead
flutter config --no-analytics

# 6. Execute public web production compilation pass
echo "--- Compiling Production Web App Assets ---"
flutter build web --release --pwa-strategy=none --dart-define=GOOGLE_WEB_CLIENT_ID="748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com"