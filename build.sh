#!/bin/bash
set -e

# 1. Define Flutter Version and Path
FLUTTER_VERSION="3.22.2" # Replace with your project's target version if needed
export PATH="$PATH:$(pwd)/flutter/bin"

# 2. Check if Flutter is already cached, if not download it
if [ ! -d "flutter" ]; then
  echo "--- Fetching Flutter SDK v$FLUTTER_VERSION ---"
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
  tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
  rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
fi

# 3. Verify installation and disable telemetry to optimize build time
flutter doctor -v
flutter config --no-analytics

# 4. Execute production build
echo "--- Compiling Flutter Web Project ---"
flutter build web --release --pwa-strategy=none --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_REAL_WEB_CLIENT_ID"