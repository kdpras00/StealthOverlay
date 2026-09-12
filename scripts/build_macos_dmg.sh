#!/bin/bash
# Builds a drag-to-Applications DMG for WhisperCue.
# Usage: scripts/build_macos_dmg.sh <path-to-WhisperCue.app> <output-dmg>
set -euo pipefail

APP_SRC="$1"
OUT_DMG="$2"

RW="$(mktemp /tmp/whispercue_dmg.XXXXXX)"
rm -f "$RW"
RW="$RW.dmg"

hdiutil create -size 160m -fs HFS+ -volname "WhisperCue" -ov "$RW" >/dev/null
MNT="$(mktemp -d /tmp/whispercue_mnt.XXXXXX)"
hdiutil attach -readwrite -noverify -noautoopen -mountpoint "$MNT" "$RW" >/dev/null

cleanup() {
  hdiutil detach "$MNT" >/dev/null 2>&1 || true
  rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

cp -R "$APP_SRC" "$MNT/"
ln -s /Applications "$MNT/Applications"

# Finder window layout (best effort): app icon left, Applications right.
osascript <<EOF >/dev/null 2>&1 || true
tell application "Finder"
  tell disk "WhisperCue"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {400, 100, 920, 440}
    tell icon view options of container window
      set arrangement to not arranged
      set icon size to 128
    end tell
    set position of item "WhisperCue.app" of container window to {160, 170}
    set position of item "Applications" of container window to {360, 170}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

hdiutil detach "$MNT" >/dev/null
trap - EXIT
rmdir "$MNT" 2>/dev/null || true
hdiutil convert "$RW" -format UDZO -o "$OUT_DMG" -ov
rm -f "$RW"
echo "Created $OUT_DMG"
