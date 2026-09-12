#!/bin/bash
set -e

# Install Flutter SDK on Vercel build environment if not cached
if [ ! -d "$HOME/flutter" ]; then
  echo "=== Downloading Flutter SDK ==="
  curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz | tar -xJ -C $HOME
fi

export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web ==="
flutter build web --release
