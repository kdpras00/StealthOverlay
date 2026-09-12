#!/bin/bash
set -e

# Fix git safe directory ownership issue in CI containers
git config --global --add safe.directory '*' || true

# Install Flutter SDK on Vercel build environment if not cached
if [ ! -d "$HOME/flutter" ]; then
  echo "=== Downloading Flutter SDK ==="
  curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz | tar -xJ -C $HOME
fi

export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics

echo "=== Flutter Version ==="
flutter --version

echo "=== Building Flutter Web (HTML Renderer & PWA Disabled) ==="
flutter build web --release --web-renderer html --pwa-strategy=none
