#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Install or setup Flutter on Vercel if necessary
# (Assuming your current custom setup command logic goes here)

# 2. Run the production build with all custom environment definitions
flutter build web --release --pwa-strategy=none --dart-define=GOOGLE_WEB_CLIENT_ID="748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com"
